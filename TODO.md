# Cloud Sync

The app uses a standard NSPersistentContainer (not NSPersistentCloudKitContainer) in PersistenceController.swift:37, which stores data locally only. While the SPEC.md mentions iCloud sync as a planned capability, it's not implemented in the current codebase.
