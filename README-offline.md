# OpenWebUI Offline Bundle

This repository includes scripts to create and install an air-gapped (offline) bundle
containing all Python wheels, npm packages, and Hugging Face models used by OpenWebUI. The process has two phases:

1. On an internet-connected machine, run the bundling script to download all dependencies and models.
2. Copy the produced `OpenWebUI-offline.zip` to the air-gapped target and run the install script.

Files added:
- `scripts/create-offline-bundle.sh` — creates `OpenWebUI-offline.zip` (Linux/macOS)
- `scripts/Create-OfflineBundle.ps1` — creates `OpenWebUI-offline.zip` (Windows PowerShell)
- `scripts/install-offline-bundle.sh` — installs from the bundle on a target machine (Linux/macOS)
- `scripts/Install-OfflineBundle.ps1` — installs from the bundle on a target machine (Windows PowerShell)

Notes and caveats:
- The bundler runs `pip download -r backend/requirements.txt` to collect wheels, `npm ci` to populate `node_modules` based on `package-lock.json`, and downloads Hugging Face models to `offline_bundle/models`.
- Some packages may include platform-specific wheels (e.g., onnxruntime). To support multiple target platforms, run the bundler on each target platform or include wheels for each platform.
- Large packages, many wheels, and models will produce a large archive. Ensure sufficient disk space.

Usage (online machine):

```bash
chmod +x scripts/create-offline-bundle.sh
./scripts/create-offline-bundle.sh
```

or on Windows PowerShell:

```powershell
.\scripts\Create-OfflineBundle.ps1
```

Usage (air-gapped target):

```bash
unzip OpenWebUI-offline.zip
chmod +x scripts/install-offline-bundle.sh
./scripts/install-offline-bundle.sh OpenWebUI-offline.zip /opt/open-webui
```

or on Windows PowerShell:

```powershell
.\scripts\Install-OfflineBundle.ps1 -BundlePath OpenWebUI-offline.zip -InstallRoot C:\path\to\install
```

If you want a multi-platform packaging or additional automation, open an issue to request enhancements.
