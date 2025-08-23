import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            VStack(spacing: 20) {
                Spacer()
                Text("Welcome to Allergen Detector")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                Text("Scan barcodes and quickly check products for allergens you want to avoid.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Button("Next") { selection = 1 }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .tag(0)

            VStack(spacing: 20) {
                Spacer()
                Text("Select Your Allergens")
                    .font(.largeTitle)
                    .bold()
                Text("Customize your allergen list so the app can flag ingredients that matter to you.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Button("Next") { selection = 2 }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .tag(1)

            VStack(spacing: 20) {
                Spacer()
                Text("Stay Safe")
                    .font(.largeTitle)
                    .bold()
                Text("If you have a life‑threatening allergy, always double‑check the ingredient list on the product even when the app says it's safe.")
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
                Button("Get Started") {
                    settings.hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .tag(2)
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserSettings())
}
