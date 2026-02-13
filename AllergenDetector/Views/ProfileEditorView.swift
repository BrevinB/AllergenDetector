//
//  ProfileEditorView.swift
//  AllergenDetector
//
//  UI for creating and editing user profiles
//

import SwiftUI

enum ProfileEditorMode {
    case add
    case edit(UserProfile)
}

struct ProfileEditorView: View {
    let mode: ProfileEditorMode
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var emoji: String = "👤"
    @State private var showingEmojiPicker = false

    // Common emoji options for family profiles
    private let emojiOptions = [
        "👤", "👨", "👩", "👶", "👧", "👦", "🧒",
        "👨‍🦱", "👩‍🦱", "👨‍🦰", "👩‍🦰", "👨‍🦳", "👩‍🦳",
        "🧔", "👴", "👵", "🙂", "😊", "🤗"
    ]

    init(mode: ProfileEditorMode) {
        self.mode = mode
        if case .edit(let profile) = mode {
            _name = State(initialValue: profile.name)
            _emoji = State(initialValue: profile.emoji)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    HStack {
                        Text("Emoji")
                            .font(.headline)

                        Spacer()

                        Button(action: {
                            showingEmojiPicker.toggle()
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.brand.opacity(0.15))
                                )
                        }
                    }

                    if showingEmojiPicker {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(emojiOptions, id: \.self) { option in
                                Button(action: {
                                    emoji = option
                                    showingEmojiPicker = false
                                }) {
                                    Text(option)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(emoji == option ? Color.brand.opacity(0.3) : Color.secondary.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    TextField("Name", text: $name)
                        .font(.body)
                }

                Section(header: Text("Preview")) {
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.system(size: 36))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.brand.opacity(0.15))
                            )

                        Text(name.isEmpty ? "New Profile" : name)
                            .font(.headline)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                if case .add = mode {
                    Section(footer: Text("You can configure allergen preferences after creating the profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ) {
                        EmptyView()
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch mode {
        case .add:
            let newProfile = UserProfile(
                name: trimmedName,
                emoji: emoji
            )
            profileManager.addProfile(newProfile)

        case .edit(var profile):
            profile.name = trimmedName
            profile.emoji = emoji
            profileManager.updateProfile(profile)
        }

        presentationMode.wrappedValue.dismiss()
    }
}

extension ProfileEditorMode {
    var title: String {
        switch self {
        case .add:
            return "New Profile"
        case .edit:
            return "Edit Profile"
        }
    }
}

#Preview {
    ProfileEditorView(mode: .add)
}
