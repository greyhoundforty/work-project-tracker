import Foundation
import Testing
@testable import Manifest

@Suite("ProjectCustomField")
struct ProjectCustomFieldTests {

    @Test func initDefaultsValueToEmptyString() {
        let field = ProjectCustomField(label: "Contract Number", sortOrder: 0)
        #expect(field.label == "Contract Number")
        #expect(field.value == "")
        #expect(field.sortOrder == 0)
    }

    @Test func initWithValue() {
        let field = ProjectCustomField(label: "Contract Number", value: "CNT-001", sortOrder: 0)
        #expect(field.value == "CNT-001")
    }

    @Test func projectStartsWithNoCustomFields() {
        let project = Project(name: "Test")
        #expect(project.customFields.isEmpty)
    }

    // MARK: - TemplateCustomField decoding

    @Test func decodesTemplateWithoutCustomFields() throws {
        let json = """
        {"name":"base","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields.isEmpty)
    }

    @Test func decodesTemplateWithCustomFields() throws {
        let json = """
        {"name":"client","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Contract Number","placeholder":"CNT-001"}]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields.count == 1)
        #expect(template.customFields[0].label == "Contract Number")
        #expect(template.customFields[0].placeholder == "CNT-001")
    }

    @Test func decodesTemplateWithCustomFieldMissingPlaceholder() throws {
        let json = """
        {"name":"client","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Contract Number"}]}
        """.data(using: .utf8)!
        let template = try JSONDecoder().decode(ProjectTemplate.self, from: json)
        #expect(template.customFields[0].placeholder == nil)
    }
}
