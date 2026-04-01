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
    case external       = "External (Customer)"
    case ibmInternal    = "Internal (IBM)"
    case businessPartner = "Business Partner"
}

enum InternalRole: String, Codable, CaseIterable {
    case ae      = "Account Executive"
    case se      = "Solutions Engineer"
    case manager = "Manager"
    case other   = "Other"
}
