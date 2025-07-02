//
//  AllergenDetectorApp.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import SwiftUI

@main
struct AllergenDetectorApp: App {
    @StateObject private var settings = UserSettings()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
