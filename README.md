# AllergenDetector

AllergenDetector is an iOS application that scans product barcodes and warns users when allergens are detected. Users can select allergens to avoid, view a history of scanned items and, as of this version, export that history to a plain text file. When a barcode cannot be read, users can capture a photo of the ingredient label and the app will attempt OCR-based recognition. Subscribers gain access to an AI-powered analysis that highlights ambiguous ingredients or potential cross-contamination warnings.

## Exporting History

Open the **History** screen and tap the **Export** button to share a text file listing all recorded scans. The export runs briefly in the background and a spinner is shown until the share sheet appears. Each line contains the barcode, product name, date scanned, and whether the item was marked safe.
