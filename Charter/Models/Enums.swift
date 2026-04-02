import Foundation

enum ProjectStage: String, Codable, CaseIterable, Identifiable {
    case discovery        = "Discovery"
    case initialDelivery  = "Initial Delivery"
    case refine           = "Refine"
    case proposal         = "Proposal"
    case won              = "Won"
    case lost             = "Lost"

    var id: String { rawValue }

    var isTerminal: Bool {
        self == .won || self == .lost
    }

    var next: ProjectStage? {
        switch self {
        case .discovery:       return .initialDelivery
        case .initialDelivery: return .refine
        case .refine:          return .proposal
        case .proposal:        return nil
        case .won, .lost:      return nil
        }
    }
}

enum ContactType: String, Codable, CaseIterable {
    case external = "External"
    case `internal` = "Internal"

    // Handles data stored with old raw values from previous app versions
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "External", "External (Customer)":
            self = .external
        case "Internal", "Internal (IBM)":
            self = .internal
        case "Business Partner":
            self = .external
        default:
            self = .external
        }
    }
}
