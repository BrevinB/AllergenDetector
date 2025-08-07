import Foundation

struct CustomAllergen: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var isEnabled: Bool = true
}
