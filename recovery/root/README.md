# Recovery root additions

This directory is reserved for device-specific recovery-side files that are proven necessary for the A35 AERA port.

Do not copy SHRP/TWRP init scripts wholesale. Each service, property, permission and binary must be checked against:
- the pinned AERA 16.0 source;
- the exact SM-A356E firmware;
- the actual partition layout and boot mode;
- runtime logs from the device.

No init scripts or binaries are installed by this scaffold.
