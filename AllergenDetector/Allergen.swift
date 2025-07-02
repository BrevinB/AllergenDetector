//
//  Allergen.swift
//  AllergenDetector
//
//  Created by Brevin Blalock on 5/30/25.
//

import Foundation

enum Allergen: String, CaseIterable, Identifiable, Codable {
    case gluten
    case dairy
    case foodDyes
    case nuts
    case eggs
    case soy
    case fish
    case shellfish
    case peanuts
    case treeNuts
    case sesame
    case mustard
    case celery
    case lupin
    case sulfites

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .gluten: return "Gluten"
        case .dairy: return "Dairy"
        case .foodDyes: return "Food Dyes"
        case .nuts: return "Nuts"
        case .eggs: return "Eggs"
        case .soy: return "Soy"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .peanuts: return "Peanuts"
        case .treeNuts: return "Tree Nuts"
        case .sesame: return "Sesame"
        case .mustard: return "Mustard"
        case .celery: return "Celery"
        case .lupin: return "Lupin"
        case .sulfites: return "Sulfites"
        }
    }
}
