# TODO: Finish Adding Hugging Face Models to Offline Bundle

## Completed Tasks
- [x] Updated `scripts/create-offline-bundle.sh` to download HF models
- [x] Updated `scripts/Create-OfflineBundle.ps1` to download HF models
- [x] Updated `offline_bundle/README.md` to document models
- [x] Updated `README-offline.md` to document models in bundle
- [x] Tested the updated bundle creation scripts on an internet-connected machine
- [x] Verified that the bundle includes models, wheels, and npm packages

## Remaining Tasks
- [ ] Test installation on air-gapped system
- [ ] Confirm that the application runs offline with bundled models

## Notes
- The system is air-gapped, so all dependencies must be pre-downloaded.
- Models are downloaded to `offline_bundle/models/` and included in the zip.
- Install scripts copy models to the install location.
