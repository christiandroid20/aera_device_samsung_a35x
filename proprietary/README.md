# Proprietary components

This directory is reserved for documentation and extraction manifests for device-specific proprietary components.

No Samsung proprietary binaries are included.

For local testing, obtain blobs from firmware that matches the target SM-A356E build and record:
- firmware build identifier and source;
- original partition/path;
- file hash;
- required destination and purpose;
- licensing/redistribution status.

Do not commit Samsung proprietary blobs unless redistribution is explicitly authorized. Pay particular attention to KeyMint, Gatekeeper, TEEGRIS and related trusted applications: copying files alone does not establish a working decryption chain.
