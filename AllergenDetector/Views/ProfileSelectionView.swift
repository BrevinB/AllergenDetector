//
//  ProfileSelectionView.swift
//  AllergenDetector
//
//  UI for selecting and managing user profiles
//

import SwiftUI

struct ProfileSelectionView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @State private var showingAddProfile = false
    @State private var profileToEdit: UserProfile?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Section(header: Text("Family Profiles")
                .font(.headline)
                .foregroundColor(.primary)
            ) {
                ForEach(profileManager.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isActive: profile.id == profileManager.activeProfileId,
                        onSelect: {
                            profileManager.switchToProfile(id: profile.id)
                            presentationMode.wrappedValue.dismiss()
                        },
                        onEdit: {
                            profileToEdit = profile
                        }
                    )
                }
                .onDelete(perform: deleteProfiles)
            }

            Section {
                Button(action: {
                    showingAddProfile = true
                }) {
                    Label("Add New Profile", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }

            if profileManager.profiles.count > 1 {
                Section(footer: Text("Swipe left to delete a profile. Each profile maintains its own allergen preferences and scan history.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ) {
                    EmptyView()
                }
            }
        }
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddProfile) {
            ProfileEditorView(mode: .add)
        }
        .sheet(item: $profileToEdit) { profile in
            ProfileEditorView(mode: .edit(profile))
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profileManager.profiles[index]
            profileManager.deleteProfile(id: profile.id)
        }
    }
}

struct ProfileRow: View {
    let profile: UserProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(profile.emoji)
                    .font(.system(size: 36))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .imageScale(.small)
                        }
                    }

                    HStack(spacing: 8) {
                        Label("\(profile.selectedAllergens.count)", systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !profile.customAllergens.isEmpty {
                            Label("\(profile.customAllergens.count) custom", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.accentColor)
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        ProfileSelectionView()
    }
}
