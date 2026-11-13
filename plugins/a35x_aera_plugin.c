/* SPDX-License-Identifier: Apache-2.0
 *
 * A35X AERA Host API 2 prototype.
 * Read-only GSI inspection and emergency diagnostics. No block writes,
 * formatting, automatic rollback, or boot-chain changes are implemented here.
 */
#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/fs.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define AERA_MAGIC 0x41325049U
#define AERA_API 2U
#define FEATURE_METRICS (1U << 0)
#define FEATURE_BACK (1U << 1)
#define FEATURE_FILE_PICKER (1U << 11)
#define FEATURE_REQUEST_MAGIC 0xA2E20000U
#define PRIMARY (1U << 0)
#define DISABLED (1U << 2)
#define METRIC_WARNING (1U << 9)
#define METRIC_GOOD (1U << 8)
#define MAX_ROWS 64
#define MAX_ACTIONS 12

enum Kind {
    HELLO = 1, BEGIN_PAGE, ADD_BUTTON, COMMIT_PAGE, SET_STATUS,
    REQUEST_OPERATION, CLOSE_WORKER, ADD_SECTION, ADD_METRIC,
    UPDATE_METRIC, SET_BACK_ACTION, PICK_FILE = 28,
    HELLO_ACK = 64, ACTION, LIFECYCLE, OPERATION_RESULT,
    FILE_PICKER_RESULT = 75
};

enum Lifecycle { RESUME = 1, PAUSE, STOP };
enum {
    PAGE_HOME = 100, PAGE_IMPORT, PAGE_PARTITIONS, PAGE_COMPAT,
    PAGE_SNAPSHOTS, PAGE_ROOT, PAGE_BOOT, PAGE_PSTORE, PAGE_FILESYSTEMS,
    PAGE_CRYPTO, PAGE_LOGS
};

struct Message {
    uint32_t magic, version, kind, request_id, value, flags;
    char title[96];
    char text[1024];
};
_Static_assert(sizeof(struct Message) == 1144, "AERA Host API packet size mismatch");

struct Row {
    int section;
    uint32_t id, flags;
    char title[96], value[256];
};
struct Button {
    uint32_t id, flags;
    char title[96], detail[256];
};
struct Page {
    char title[96], body[512];
    struct Row rows[MAX_ROWS];
    size_t row_count;
    struct Button buttons[MAX_ACTIONS];
    size_t button_count;
    uint32_t back_action;
};
static uint32_t host_features;
static int app_fd = 4;
static const uint32_t BACK_ACTION = 999;
static const uint32_t PICKER_REQUEST = 901;

static void copy_text(char *out, size_t size, const char *in) {
    if (!out || !size) return;
    if (!in) in = "";
    snprintf(out, size, "%s", in);
}
static int send_message(uint32_t kind, uint32_t request, uint32_t value,
                        uint32_t flags, const char *title, const char *text) {
    struct Message m;
    memset(&m, 0, sizeof(m));
    m.magic = AERA_MAGIC; m.version = AERA_API; m.kind = kind;
    m.request_id = request; m.value = value; m.flags = flags;
    copy_text(m.title, sizeof(m.title), title);
    copy_text(m.text, sizeof(m.text), text);
    ssize_t n;
    do { n = send(app_fd, &m, sizeof(m), MSG_NOSIGNAL); }
    while (n < 0 && errno == EINTR);
    return n == (ssize_t)sizeof(m) ? 0 : -1;
}
static int valid_message(const struct Message *m) {
    return m->magic == AERA_MAGIC && m->version == AERA_API &&
           memchr(m->title, 0, sizeof(m->title)) &&
           memchr(m->text, 0, sizeof(m->text));
}
static int receive_message(struct Message *m) {
    ssize_t n;
    do { n = recv(app_fd, m, sizeof(*m), 0); }
    while (n < 0 && errno == EINTR);
    return n == (ssize_t)sizeof(*m) && valid_message(m) ? 1 : 0;
}
static int capture_argv(char *const argv[], char *out, size_t size) {
    int pipefd[2];
    if (!out || size < 2 || pipe(pipefd) != 0) return 0;
    pid_t pid = fork();
    if (pid < 0) { close(pipefd[0]); close(pipefd[1]); return 0; }
    if (pid == 0) {
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[0]); close(pipefd[1]);
        execvp(argv[0], argv);
        _exit(127);
    }
    close(pipefd[1]);
    size_t used = 0;
    while (used + 1 < size) {
        ssize_t n = read(pipefd[0], out + used, size - used - 1);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) break;
        used += (size_t)n;
    }
    close(pipefd[0]);
    out[used] = 0;
    int status = 0;
    while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {}
    while (used && (out[used - 1] == '\n' || out[used - 1] == '\r' ||
                    out[used - 1] == ' ' || out[used - 1] == '\t'))
        out[--used] = 0;
    return WIFEXITED(status) && WEXITSTATUS(status) == 0 && used != 0;
}
static int get_property(const char *key, char *out, size_t size) {
    char *const argv[] = {(char *)"getprop", (char *)key, NULL};
    return capture_argv(argv, out, size);
}
static void page_init(struct Page *p, const char *title, const char *body) {
    memset(p, 0, sizeof(*p));
    copy_text(p->title, sizeof(p->title), title);
    copy_text(p->body, sizeof(p->body), body);
}
static void add_section(struct Page *p, const char *title) {
    if (p->row_count >= MAX_ROWS) return;
    struct Row *r = &p->rows[p->row_count++];
    memset(r, 0, sizeof(*r)); r->section = 1;
    copy_text(r->title, sizeof(r->title), title);
}
static void add_metric(struct Page *p, const char *title, const char *value,
                       uint32_t flags) {
    if (!value || !*value || p->row_count >= MAX_ROWS) return;
    struct Row *r = &p->rows[p->row_count++];
    memset(r, 0, sizeof(*r)); r->id = (uint32_t)p->row_count;
    r->flags = flags;
    copy_text(r->title, sizeof(r->title), title);
    copy_text(r->value, sizeof(r->value), value);
}
static void add_action(struct Page *p, uint32_t id, const char *title,
                       const char *detail, uint32_t flags) {
    if (p->button_count >= MAX_ACTIONS) return;
    struct Button *b = &p->buttons[p->button_count++];
    memset(b, 0, sizeof(*b)); b->id = id; b->flags = flags;
    copy_text(b->title, sizeof(b->title), title);
    copy_text(b->detail, sizeof(b->detail), detail);
}
static void add_back(struct Page *p) {
    add_action(p, BACK_ACTION, "Back to Home", "Return to the main manager", 0);
    p->back_action = BACK_ACTION;
}
static void append_body(char *body, size_t size, const char *line) {
    size_t used = strlen(body);
    if (used + 2 >= size) return;
    snprintf(body + used, size - used, "%s\n", line);
}
static int publish_page(const struct Page *p) {
    if (host_features & FEATURE_METRICS) {
        if (send_message(BEGIN_PAGE, 0, 0, 0, p->title, p->body)) return -1;
        for (size_t i = 0; i < p->row_count; ++i) {
            const struct Row *r = &p->rows[i];
            if (send_message(r->section ? ADD_SECTION : ADD_METRIC,
                             r->section ? 0 : r->id, 0, r->flags,
                             r->title, r->section ? "" : r->value)) return -1;
        }
    } else {
        char body[1024] = {0};
        append_body(body, sizeof(body), p->body);
        for (size_t i = 0; i < p->row_count; ++i) {
            char line[400];
            if (p->rows[i].section)
                snprintf(line, sizeof(line), "[%s]", p->rows[i].title);
            else
                snprintf(line, sizeof(line), "%s: %s", p->rows[i].title, p->rows[i].value);
            append_body(body, sizeof(body), line);
        }
        if (send_message(BEGIN_PAGE, 0, 0, 0, p->title, body)) return -1;
    }
    for (size_t i = 0; i < p->button_count; ++i) {
        const struct Button *b = &p->buttons[i];
        if (send_message(ADD_BUTTON, b->id, 0, b->flags, b->title, b->detail)) return -1;
    }
    if ((host_features & FEATURE_BACK) && p->back_action)
        if (send_message(SET_BACK_ACTION, p->back_action, 0, 0, "", "")) return -1;
    return send_message(COMMIT_PAGE, 0, 0, 0, "", "");
}
static void format_bytes(uint64_t bytes, char *out, size_t size) {
    const char *units[] = {"B", "KiB", "MiB", "GiB", "TiB"};
    double n = (double)bytes; size_t i = 0;
    while (n >= 1024.0 && i < 4) { n /= 1024.0; ++i; }
    snprintf(out, size, i ? "%.2f %s" : "%.0f %s", n, units[i]);
}
static int file_size(const char *path, uint64_t *size) {
    struct stat st;
    if (stat(path, &st) != 0) return 0;
    if (S_ISREG(st.st_mode)) { *size = (uint64_t)st.st_size; return 1; }
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    uint64_t bytes = 0;
    int ok = ioctl(fd, BLKGETSIZE64, &bytes) == 0;
    close(fd);
    if (ok) *size = bytes;
    return ok;
}
static int real_vendor_dm4_mounted(void) {
    FILE *f = fopen("/proc/self/mountinfo", "r");
    if (!f) return 0;
    char line[1024], device[64], mountpoint[256];
    int found = 0;
    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "%*s %*s %63s %*s %255s", device, mountpoint) == 2 &&
            strcmp(device, "254:4") == 0 && strcmp(mountpoint, "/vendor") == 0) {
            found = 1; break;
        }
    }
    fclose(f); return found;
}
static int mount_present(const char *mountpoint) {
    FILE *f = fopen("/proc/mounts", "r");
    if (!f) return 0;
    char line[1024], source[256], target[256];
    int found = 0;
    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "%255s %255s", source, target) == 2 &&
            strcmp(target, mountpoint) == 0) { found = 1; break; }
    }
    fclose(f); return found;
}
static int read_prefix(const char *path, unsigned char *buf, size_t size) {
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return -1;
    ssize_t n;
    do { n = read(fd, buf, size); } while (n < 0 && errno == EINTR);
    close(fd); return (int)n;
}
static uint32_t le32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static const char *image_type(const char *path, uint64_t *sparse_bytes) {
    unsigned char h[1200]; memset(h, 0, sizeof(h));
    int n = read_prefix(path, h, sizeof(h));
    if (n < 4) return "Unknown / unreadable image";
    if (le32(h) == 0xed26ff3aU && n >= 28) {
        uint32_t block = le32(h + 12), blocks = le32(h + 16);
        if (block && blocks && (uint64_t)blocks <= UINT64_MAX / block)
            *sparse_bytes = (uint64_t)block * blocks;
        return "Android sparse image";
    }
    if (!memcmp(h, "PK\003\004", 4) || !memcmp(h, "PK\005\006", 4))
        return "ZIP archive / ROM package";
    if (!memcmp(h, "CrAU", 4)) return "Android OTA payload";
    if (!memcmp(h, "ANDROID!", 8)) return "Android boot image";
    if (n >= 1082 && h[1080] == 0x53 && h[1081] == 0xef)
        return "EXT4 filesystem image";
    if (n >= 1028 && h[1024] == 0xe2 && h[1025] == 0xe1 &&
        h[1026] == 0xf5 && h[1027] == 0xe0)
        return "EROFS filesystem image";
    return "Raw image (filesystem not identified)";
}
static int sha256_file(const char *path, char *out, size_t size) {
    char *const argv[] = {(char *)"sha256sum", (char *)path, NULL};
    char result[256];
    if (!capture_argv(argv, result, sizeof(result)) || strlen(result) < 64) return 0;
    result[64] = 0; copy_text(out, size, result); return 1;
}
static void render_image_result(const char *path) {
    struct Page p; page_init(&p, "GSI IMAGE INSPECTOR",
        "Read-only inspection. The selected image has not been mounted or modified.");
    uint64_t bytes = 0, sparse_bytes = 0;
    char value[256], hash[96];
    if (!file_size(path, &bytes)) {
        add_metric(&p, "Result", "Unable to read selected file", METRIC_WARNING);
    } else {
        format_bytes(bytes, value, sizeof(value)); add_metric(&p, "File size", value, 0);
        add_metric(&p, "Detected format", image_type(path, &sparse_bytes), 0);
        if (sparse_bytes) {
            format_bytes(sparse_bytes, value, sizeof(value));
            add_metric(&p, "Expanded sparse size", value, 0);
        }
        send_message(SET_STATUS, 0, 0, 0, "", "Calculating SHA-256; large images may take a while.");
        if (sha256_file(path, hash, sizeof(hash)))
            add_metric(&p, "SHA-256", hash, METRIC_GOOD);
        else
            add_metric(&p, "SHA-256", "sha256sum is unavailable in this recovery build", METRIC_WARNING);
        add_metric(&p, "Selected path", path, 0);
    }
    add_back(&p); publish_page(&p);
}
static void scan_partitions(struct Page *p, const char *dir, const char *section) {
    DIR *d = opendir(dir);
    if (!d) { add_section(p, section); add_metric(p, "Status", "Directory unavailable", METRIC_WARNING); return; }
    add_section(p, section);
    struct dirent *entry; unsigned count = 0;
    while ((entry = readdir(d)) && p->row_count < MAX_ROWS - 1 && count < 30) {
        if (!strcmp(entry->d_name, ".") || !strcmp(entry->d_name, "..")) continue;
        char path[512], target[256], size_text[256];
        snprintf(path, sizeof(path), "%s/%s", dir, entry->d_name);
        uint64_t bytes = 0;
        if (!file_size(path, &bytes)) continue;
        format_bytes(bytes, size_text, sizeof(size_text));
        ssize_t n = readlink(path, target, sizeof(target) - 1);
        if (n >= 0) target[n] = 0; else copy_text(target, sizeof(target), "block device");
        size_t used = strlen(size_text);
        if (used + 3 < sizeof(size_text)) {
            strncat(size_text, " · ", sizeof(size_text) - used - 1);
            used = strlen(size_text);
            strncat(size_text, target, sizeof(size_text) - used - 1);
        }
        add_metric(p, entry->d_name, size_text, 0); ++count;
    }
    if (!count) add_metric(p, "Status", "No readable entries found", METRIC_WARNING);
    closedir(d);
}
static void render_partitions(void) {
    struct Page p; page_init(&p, "PARTITION INVENTORY",
        "Read-only physical by-name and logical mapper inventory. Super metadata parsing is not enabled yet.");
    scan_partitions(&p, "/dev/block/by-name", "Physical / by-name");
    scan_partitions(&p, "/dev/block/mapper", "Logical / mapper");
    add_back(&p); publish_page(&p);
}
static void metric_prop(struct Page *p, const char *label, const char *key) {
    char value[256];
    if (get_property(key, value, sizeof(value))) add_metric(p, label, value, 0);
}
static void render_compat(void) {
    struct Page p; page_init(&p, "SAMSUNG COMPATIBILITY",
        "Read-only recovery/vendor properties and secure-service state. Full HAL, VINTF and SELinux comparison is not enabled yet.");
    add_section(&p, "Device / Android");
    metric_prop(&p, "Device", "ro.product.device");
    metric_prop(&p, "Model", "ro.product.model");
    metric_prop(&p, "Android release", "ro.build.version.release");
    metric_prop(&p, "API level", "ro.build.version.sdk");
    metric_prop(&p, "Vendor VNDK", "ro.vndk.version");
    metric_prop(&p, "Vendor API", "ro.vendor.api_level");
    metric_prop(&p, "Vendor fingerprint", "ro.vendor.build.fingerprint");
    metric_prop(&p, "Kernel", "os.version");
    add_section(&p, "Samsung secure services");
    metric_prop(&p, "TEEGRIS loaded", "vendor.TEEGRIS.loaded");
    metric_prop(&p, "Crypto ready", "crypto.ready");
    metric_prop(&p, "TZ daemon", "init.svc.tz_service");
    metric_prop(&p, "TZ-TS daemon", "init.svc.tzts_service");
    metric_prop(&p, "KeyMint", "init.svc.vendor.keymint-default");
    metric_prop(&p, "Gatekeeper", "init.svc.vendor.gatekeeper-1-0");
    metric_prop(&p, "FKeymaster", "init.svc.vendor.fkeymaster-default");
    int vendor_dm4 = real_vendor_dm4_mounted();
    add_metric(&p, "Real vendor dm-4 mounted", vendor_dm4 ? "Yes" : "No / not verified", vendor_dm4 ? METRIC_GOOD : METRIC_WARNING);
    add_back(&p); publish_page(&p);
}
static void render_snapshots(void) {
    struct Page p; page_init(&p, "ROM SNAPSHOTS",
        "Read-only discovery. This prototype does not create, overwrite or restore snapshots.");
    const char *paths[] = {
        "/sdcard/AERA/GSI", "/sdcard/AERA/Snapshots",
        "/data/media/0/AERA/GSI", "/data/media/0/AERA/Snapshots"
    };
    for (size_t i = 0; i < sizeof(paths)/sizeof(paths[0]); ++i) {
        struct stat st; char value[384];
        if (stat(paths[i], &st) == 0 && S_ISDIR(st.st_mode))
            snprintf(value, sizeof(value), "Directory present · %s", paths[i]);
        else
            snprintf(value, sizeof(value), "Not found · %s", paths[i]);
        add_metric(&p, i < 2 ? "Storage path" : "Data path", value, 0);
    }
    add_back(&p); publish_page(&p);
}
static void render_root(void) {
    struct Page p; page_init(&p, "ROOT & BOOT INSPECTION",
        "Use the existing AERA Root Manager for provider installation and patching. This page never writes boot.");
    uint64_t bytes = 0; char value[128];
    if (file_size("/dev/block/by-name/boot", &bytes)) {
        format_bytes(bytes, value, sizeof(value)); add_metric(&p, "Boot partition", value, 0);
    } else add_metric(&p, "Boot partition", "Not readable", METRIC_WARNING);
    add_metric(&p, "Automatic boot patch", "Disabled", METRIC_GOOD);
    add_metric(&p, "Manual patching", "Use AERA Root Manager / approved manual workflow", 0);
    add_metric(&p, "Write protection", "No boot write operation exists in this prototype", METRIC_GOOD);
    add_back(&p); publish_page(&p);
}
static void render_gsi_home(void) {
    struct Page p; page_init(&p, "GSI MANAGER",
        "A35X ROM workshop. Samsung vendor stays in place. Inspection is read-only in this bring-up.");
    add_action(&p, 10, "Import & inspect image", "Choose a system image, inspect format, size and SHA-256", PRIMARY);
    add_action(&p, 20, "Partition inventory", "Read-only physical/logical devices; super metadata parser pending", 0);
    add_action(&p, 30, "Samsung compatibility", "Review loaded Android/vendor properties and secure-service state", 0);
    add_action(&p, 40, "ROM snapshots", "Find existing working copies and snapshot folders", 0);
    add_action(&p, 50, "Root & boot inspection", "Read-only boot status; existing Root Manager remains separate", 0);
    add_action(&p, 60, "ROM customization", "Staging, GApps injection and filesystem conversion are not enabled yet", DISABLED);
    add_action(&p, 70, "ROM builder & export", "Image rebuild and package export are not enabled yet", DISABLED);
 publish_page(&p);
}
static void render_emergency_home(void) {
    struct Page p; page_init(&p, "EMERGENCY MODE",
        "A35X recovery diagnostics. No userdata wipe, automatic restore or boot-chain write is performed.");
    add_action(&p, 110, "Boot reason & Android build", "Read bootloader-reported reason and build properties", PRIMARY);
    add_action(&p, 120, "Pstore / kernel evidence", "List pstore records and check last_kmsg availability", 0);
    add_action(&p, 130, "Filesystem health", "Check mount state and free space without modifying files", 0);
    add_action(&p, 140, "TEE & decryption status", "Inspect TEEGRIS, KeyMint, Gatekeeper and FKeymaster state", 0);
    add_action(&p, 150, "ROM snapshots", "Find available recovery points; no restore is triggered", 0);
    add_action(&p, 160, "Recovery logs", "Check recovery log availability and file sizes", 0);
    add_action(&p, 170, "Automatic rollback", "Not enabled: bootloader / early-boot trigger is not yet proven", DISABLED);
 publish_page(&p);
}
static void render_boot_reason(void) {
    struct Page p; page_init(&p, "BOOT REASON & BUILD",
        "These properties describe the current recovery boot; they are not a saved record of the previous Android boot.");
    add_section(&p, "Bootloader / build");
    metric_prop(&p, "Boot reason", "ro.boot.bootreason");
    metric_prop(&p, "Bootloader", "ro.bootloader");
    metric_prop(&p, "Boot device", "ro.boot.boot_devices");
    metric_prop(&p, "Slot suffix", "ro.boot.slot_suffix");
    metric_prop(&p, "Verified boot", "ro.boot.verifiedbootstate");
    metric_prop(&p, "Android release", "ro.build.version.release");
    metric_prop(&p, "Build fingerprint", "ro.build.fingerprint");
    add_back(&p); publish_page(&p);
}
static void render_pstore(void) {
    struct Page p; page_init(&p, "PSTORE / KERNEL EVIDENCE",
        "Read-only listing. Missing pstore files do not prove that no boot failure occurred.");
    DIR *d = opendir("/sys/fs/pstore"); struct dirent *e; unsigned count = 0;
    add_section(&p, "/sys/fs/pstore");
    if (d) {
        while ((e = readdir(d)) && p.row_count < MAX_ROWS - 1 && count < 40) {
            if (e->d_name[0] == '.') continue;
            char path[512], size[64]; uint64_t bytes = 0;
            snprintf(path, sizeof(path), "/sys/fs/pstore/%s", e->d_name);
            if (!file_size(path, &bytes)) continue;
            format_bytes(bytes, size, sizeof(size)); add_metric(&p, e->d_name, size, 0); ++count;
        }
        closedir(d);
    }
    if (!count) add_metric(&p, "Pstore", "No readable pstore records", METRIC_WARNING);
    struct stat st;
    if (stat("/proc/last_kmsg", &st) == 0) add_metric(&p, "last_kmsg", "Present", METRIC_GOOD);
    else add_metric(&p, "last_kmsg", "Unavailable", 0);
    add_back(&p); publish_page(&p);
}
static void render_filesystems(void) {
    struct Page p; page_init(&p, "FILESYSTEM HEALTH",
        "Mount and free-space checks only. No fsck repair, format or remount is attempted.");
    const char *paths[] = {"/data", "/metadata", "/system", "/vendor", "/product", "/system_ext", "/mnt/vendor/efs", "/efs"};
    add_section(&p, "Mount status / free space");
    for (size_t i = 0; i < sizeof(paths)/sizeof(paths[0]); ++i) {
        struct statvfs v; char value[128];
        if (statvfs(paths[i], &v) == 0) {
            uint64_t total = (uint64_t)v.f_blocks * v.f_frsize;
            uint64_t freeb = (uint64_t)v.f_bavail * v.f_frsize;
            char total_s[48], free_s[48];
            format_bytes(total, total_s, sizeof(total_s));
            format_bytes(freeb, free_s, sizeof(free_s));
            snprintf(value, sizeof(value), "%s · free %s", total_s, free_s);
        } else copy_text(value, sizeof(value), "Unavailable");
        add_metric(&p, paths[i], value, mount_present(paths[i]) ? METRIC_GOOD : METRIC_WARNING);
    }
    add_back(&p); publish_page(&p);
}
static void render_crypto(void) {
    struct Page p; page_init(&p, "TEE & DECRYPTION STATUS",
        "Read-only service inspection. Secure services are never stopped or restarted here.");
    add_section(&p, "Crypto state");
    metric_prop(&p, "ro.crypto.state", "ro.crypto.state");
    metric_prop(&p, "ro.crypto.type", "ro.crypto.type");
    metric_prop(&p, "crypto.ready", "crypto.ready");
    metric_prop(&p, "TEEGRIS loaded", "vendor.TEEGRIS.loaded");
    add_section(&p, "Secure services");
    metric_prop(&p, "TZ daemon", "init.svc.tz_service");
    metric_prop(&p, "TZ-TS daemon", "init.svc.tzts_service");
    metric_prop(&p, "KeyMint", "init.svc.vendor.keymint-default");
    metric_prop(&p, "Gatekeeper", "init.svc.vendor.gatekeeper-1-0");
    metric_prop(&p, "FKeymaster", "init.svc.vendor.fkeymaster-default");
    add_back(&p); publish_page(&p);
}
static void render_logs(void) {
    struct Page p; page_init(&p, "RECOVERY LOGS",
        "Read-only log availability and file sizes. Export and repair actions are not enabled.");
    const char *logs[] = {"/tmp/recovery.log", "/cache/recovery/last_log", "/sys/fs/pstore/console-ramoops"};
    for (size_t i = 0; i < sizeof(logs)/sizeof(logs[0]); ++i) {
        uint64_t bytes = 0; char value[128];
        if (file_size(logs[i], &bytes)) {
            format_bytes(bytes, value, sizeof(value));
            add_metric(&p, logs[i], value, METRIC_GOOD);
        } else add_metric(&p, logs[i], "Unavailable", 0);
    }
    add_back(&p); publish_page(&p);
}
static void render_import_page(void) {
    struct Page p; page_init(&p, "IMPORT & INSPECT",
        "Select an image for read-only inspection. The image is not mounted, flashed or modified.");
    add_action(&p, 11, "Choose image file", "Supported: .img, .zip, .xz and .bin", PRIMARY);
    add_back(&p); publish_page(&p);
}
static void render_current_home(void) {
#if defined(APP_GSI)
    render_gsi_home();
#else
    render_emergency_home();
#endif
}
static void handle_action(uint32_t id) {
    if (id == BACK_ACTION) { render_current_home(); return; }
#if defined(APP_GSI)
    switch (id) {
        case 10: render_import_page(); break;
        case 11:
            send_message(PICK_FILE, PICKER_REQUEST, 0, 0, ".img,.zip,.xz,.bin", "/sdcard");
            break;
        case 20: render_partitions(); break;
        case 30: render_compat(); break;
        case 40: render_snapshots(); break;
        case 50: render_root(); break;
        default: break;
    }
#else
    switch (id) {
        case 110: render_boot_reason(); break;
        case 120: render_pstore(); break;
        case 130: render_filesystems(); break;
        case 140: render_crypto(); break;
        case 150: render_snapshots(); break;
        case 160: render_logs(); break;
        default: break;
    }
#endif
}
int main(void) {
    struct Message hello;
    memset(&hello, 0, sizeof(hello));
    hello.magic = AERA_MAGIC; hello.version = AERA_API; hello.kind = HELLO;
    hello.value = 2; hello.flags = 2;
#if defined(APP_GSI)
    hello.request_id = FEATURE_REQUEST_MAGIC | FEATURE_FILE_PICKER;
#endif
    if (send(app_fd, &hello, sizeof(hello), MSG_NOSIGNAL) != (ssize_t)sizeof(hello))
        return 2;
    struct Message msg;
    if (!receive_message(&msg) || msg.kind != HELLO_ACK) return 3;
    host_features = msg.flags;
    render_current_home();
    while (receive_message(&msg)) {
        if (msg.kind == ACTION) {
            handle_action(msg.request_id);
        } else if (msg.kind == FILE_PICKER_RESULT && msg.request_id == PICKER_REQUEST) {
#if defined(APP_GSI)
            if (msg.flags == 1 && msg.text[0]) render_image_result(msg.text);
            else {
                struct Page p; page_init(&p, "IMPORT & INSPECT", "File selection was cancelled or unavailable.");
                add_back(&p); publish_page(&p);
            }
#endif
        } else if (msg.kind == LIFECYCLE && msg.value == STOP) {
            break;
        } else if (msg.kind == CLOSE_WORKER) {
            break;
        }
    }
    return 0;
}
