import Testing
@testable import EngagementTracker

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
}
