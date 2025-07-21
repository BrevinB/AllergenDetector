# AllergenDetector

AllergenDetector is an iOS application that scans product barcodes and warns users when allergens are detected. Users can select allergens to avoid, view a history of scanned items and, as of this version, export that history to a plain text file. Selected allergens, custom allergens and scan history automatically sync across devices using iCloud.

## Exporting History

Open the **History** screen and tap the **Export** button to share a text file listing all recorded scans. The export runs briefly in the background and a spinner is shown until the share sheet appears. Each line contains the barcode, product name, date scanned, and whether the item was marked safe.

## Cloud Sync

Selected allergens, custom allergens and your scan history are stored in iCloud using the ubiquitous key-value store. Sign in with the same iCloud account on multiple devices and your data will automatically stay in sync.
