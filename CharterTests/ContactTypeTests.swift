import Foundation
import Testing
@testable import Charter

@Suite("ContactType")
struct ContactTypeTests {

    @Test("decodes standard External raw value")
    func decodesExternal() throws {
        let data = Data("\"External\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .external)
    }

    @Test("decodes legacy 'External (Customer)' raw value as external")
    func decodesLegacyExternalCustomer() throws {
        let data = Data("\"External (Customer)\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .external)
    }

    @Test("decodes legacy 'Business Partner' raw value as external")
    func decodesBusinessPartner() throws {
        let data = Data("\"Business Partner\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .external)
    }

    @Test("decodes standard Internal raw value")
    func decodesInternal() throws {
        let data = Data("\"Internal\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .internal)
    }

    @Test("decodes legacy 'Internal (IBM)' raw value as internal")
    func decodesLegacyInternalIBM() throws {
        let data = Data("\"Internal (IBM)\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .internal)
    }

    @Test("unknown raw value defaults to external")
    func decodesUnknownAsExternal() throws {
        let data = Data("\"Consultant\"".utf8)
        let type = try JSONDecoder().decode(ContactType.self, from: data)
        #expect(type == .external)
    }

    @Test("rawValues are correct")
    func rawValues() {
        #expect(ContactType.external.rawValue == "External")
        #expect(ContactType.internal.rawValue == "Internal")
    }

    @Test("allCases contains exactly two values")
    func allCasesCount() {
        #expect(ContactType.allCases.count == 2)
    }
}
