# OpenWebUI Offline Bundle

This repository includes scripts to create and install an air-gapped (offline) bundle
containing all Python wheels and npm packages used by OpenWebUI. The process has two phases:

1. On an internet-connected machine, run the bundling script to download all dependencies.
2. Copy the produced `OpenWebUI-offline.zip` to the air-gapped target and run the install script.

Files added:
- `scripts/create-offline-bundle.sh` — creates `OpenWebUI-offline.zip` (Linux/macOS)
- `scripts/install-offline-bundle.sh` — installs from the bundle on a target machine (Linux/macOS)

Notes and caveats:
- The bundler runs `pip download -r backend/requirements.txt` to collect wheels and `npm ci`
  to populate `node_modules` based on `package-lock.json`.
- Some packages may include platform-specific wheels (e.g., onnxruntime). To support multiple
  target platforms, run the bundler on each target platform or include wheels for each platform.
- Large packages and many wheels will produce a large archive. Ensure sufficient disk space.

Usage (online machine):

```bash
chmod +x scripts/create-offline-bundle.sh
./scripts/create-offline-bundle.sh
```

Usage (air-gapped target):

```bash
unzip OpenWebUI-offline.zip
chmod +x scripts/install-offline-bundle.sh
./scripts/install-offline-bundle.sh OpenWebUI-offline.zip /opt/open-webui
```

If you need a Windows PowerShell variant or multi-platform packaging (multiple wheels),
the scripts can be adapted. Open an issue if you want me to add a more automated multi-platform packager.
