# AllergenDetector

AllergenDetector is an iOS application that scans product barcodes and warns users when allergens are detected. It uses the [Open Food Facts](https://world.openfoodfacts.org/) database to look up ingredients and cross-references them against the user's allergen preferences.

## Features

- **Barcode Scanning** — Scan product barcodes with your camera or enter them manually.
- **Allergen Detection** — Automatically flags products containing any of 15 built-in allergen categories (gluten, dairy, eggs, soy, fish, shellfish, peanuts, tree nuts, sesame, mustard, celery, lupin, sulfites, nuts, food dyes).
- **Custom Allergens** — Add your own allergens beyond the built-in list.
- **Multiple Profiles** — Create profiles for different family members, each with their own allergen preferences.
- **Scan History** — Browse, search, and filter past scans per profile.
- **Export** — Export scan history as plain text, CSV, or PDF.
- **Insights & Analytics** — View scanning streaks, safety rates, most-scanned products, and weekly activity charts.
- **Product Recommendations** — When a product is flagged as unsafe, find safe alternatives from the Open Food Facts database.
- **Offline Support** — Previously scanned products are cached for offline access.

## Requirements

- iOS 15.0+
- Xcode 15+
- Swift 5.9+

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/BrevinB/AllergenDetector.git
   ```
2. Open `AllergenDetector.xcodeproj` in Xcode.
3. Select a simulator or connected device and press **Run**.

No third-party dependencies are required — the project uses only Apple frameworks.

## Architecture

The app follows an **MVVM** pattern with singleton services:

| Layer | Key Files |
|-------|-----------|
| **Views** | `ContentView`, `HistoryView`, `InsightsView`, `ProfileSelectionView`, `RecommendationsView` |
| **ViewModels** | `ScannerViewModel` |
| **Services** | `ProductService`, `HistoryService`, `ProfileManager`, `ExportService`, `InsightsService`, `RecommendationService` |
| **Models** | `Product`, `ScanRecord`, `Allergen`, `UserProfile`, `CustomAllergen`, `ScanInsights` |

## Data Flow

1. User scans a barcode (camera or manual entry).
2. `ProductService` fetches product data from the Open Food Facts API.
3. `ScannerViewModel` analyzes ingredients against selected allergens.
4. Results are displayed in a product card with safety status.
5. The scan is recorded in `HistoryService` and persisted to `UserDefaults`.

## API

Product data is retrieved from the [Open Food Facts API](https://world.openfoodfacts.org/data). No API key is required.

## Exporting History

Open the **History** screen and tap the **Export** button. Choose from text, CSV, or PDF format. The export runs in the background and presents a share sheet when ready.

## Testing

Unit tests are located in `AllergenDetectorTests/`. They cover data models, allergen mappings, insights calculations, and error handling.

## License

This project is provided as-is for personal and educational use.
