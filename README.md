# PageKeep

A SwiftUI iOS app for tracking your reading life — books, annotations, quotes, and reading progress, with OCR-based capture from physical books.

## Build

1. Open `Bookshelf.xcodeproj` in Xcode 15+.
2. Select an iOS 17+ simulator or a device.
3. Build and run (`⌘R`).

## Stack

- SwiftUI
- SwiftData for persistence
- Vision framework for OCR
- StoreKit 2 for the in-app tip jar
- Google Books API for metadata and cover art

## Notes

- The Google Books API key in `PageKeep/Components/GoogleBooksService.swift` is restricted in Google Cloud Console to this app's iOS bundle ID and to the Books API only — it cannot be reused outside this app.
- Camera access is used solely to capture text from physical books for annotations (declared in `Info.plist` via `NSCameraUsageDescription`).

## License

All rights reserved.
