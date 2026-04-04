import Foundation
import Testing
@testable import Charter

@Suite("ProjectTemplate Decoding")
struct ProjectTemplateDecodingTests {

    private func decode(_ jsonString: String) throws -> ProjectTemplate {
        let data = Data(jsonString.utf8)
        return try JSONDecoder().decode(ProjectTemplate.self, from: data)
    }

    // MARK: - ProjectTemplate basics

    @Test("template id equals its name")
    func templateIDIsName() throws {
        let t = try decode("""
        {"name":"My Template","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[]}
        """)
        #expect(t.id == "My Template")
    }

    @Test("template decodes isPOC=true correctly")
    func templateIsPOCTrue() throws {
        let t = try decode("""
        {"name":"poc","isPOC":true,"tags":[],"stage":"Discovery","taskTitles":[]}
        """)
        #expect(t.isPOC == true)
    }

    @Test("template decodes tags correctly")
    func templateTags() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":["cloud","security"],"stage":"Discovery","taskTitles":[]}
        """)
        #expect(t.tags == ["cloud", "security"])
    }

    @Test("template decodes task titles correctly")
    func templateTaskTitles() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":["Task A","Task B"]}
        """)
        #expect(t.taskTitles == ["Task A", "Task B"])
    }

    @Test("template with missing optional arrays defaults to empty")
    func templateMissingArraysDefaultEmpty() throws {
        let t = try decode("""
        {"name":"base","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[]}
        """)
        #expect(t.customFields.isEmpty)
        #expect(t.checkpoints.isEmpty)
    }

    // MARK: - projectStage computed property

    @Test("projectStage returns correct stage for each valid raw value")
    func projectStageAllValidValues() throws {
        let cases: [(String, ProjectStage)] = [
            ("Discovery", .discovery),
            ("Initial Delivery", .initialDelivery),
            ("Refine", .refine),
            ("Proposal", .proposal),
            ("Won", .won),
            ("Lost", .lost)
        ]
        for (rawValue, expected) in cases {
            let json = """
            {"name":"test","isPOC":false,"tags":[],"stage":"\(rawValue)","taskTitles":[]}
            """
            let t = try decode(json)
            #expect(t.projectStage == expected, "Expected \(expected) for stage '\(rawValue)'")
        }
    }

    @Test("projectStage defaults to discovery for unknown stage string")
    func projectStageUnknownDefaultsToDiscovery() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"NotAStage","taskTitles":[]}
        """)
        #expect(t.projectStage == .discovery)
    }

    // MARK: - TemplateCheckpoint

    @Test("template with checkpoints decodes title and stage")
    func templateCheckpoints() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "checkpoints":[{"title":"Setup complete","stage":"Discovery"}]}
        """)
        #expect(t.checkpoints.count == 1)
        #expect(t.checkpoints[0].title == "Setup complete")
        #expect(t.checkpoints[0].stage == "Discovery")
    }

    @Test("TemplateCheckpoint.projectStage returns correct stage")
    func checkpointProjectStage() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "checkpoints":[{"title":"Proposal ready","stage":"Proposal"}]}
        """)
        #expect(t.checkpoints[0].projectStage == .proposal)
    }

    @Test("TemplateCheckpoint.projectStage defaults to discovery for unknown stage")
    func checkpointProjectStageDefaultsToDiscovery() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "checkpoints":[{"title":"Unknown","stage":"NotAStage"}]}
        """)
        #expect(t.checkpoints[0].projectStage == .discovery)
    }

    // MARK: - TemplateCustomField types

    @Test("TemplateCustomField defaults to text type when type key is missing")
    func customFieldDefaultsToText() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Notes"}]}
        """)
        #expect(t.customFields[0].type == .text)
    }

    @Test("TemplateCustomField decodes url type")
    func customFieldURLType() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Link","type":"url"}]}
        """)
        #expect(t.customFields[0].type == .url)
    }

    @Test("TemplateCustomField decodes toggle type")
    func customFieldToggleType() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Is Active","type":"toggle"}]}
        """)
        #expect(t.customFields[0].type == .toggle)
    }

    @Test("TemplateCustomField decodes stage-picker type")
    func customFieldStagePickerType() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Stage","type":"stage-picker"}]}
        """)
        #expect(t.customFields[0].type == .stagePicker)
    }

    @Test("TemplateCustomField decodes date type")
    func customFieldDateType() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Close Date","type":"date"}]}
        """)
        #expect(t.customFields[0].type == .date)
    }

    @Test("TemplateCustomField decodes options array")
    func customFieldOptions() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Priority","options":["Low","Medium","High"]}]}
        """)
        #expect(t.customFields[0].options == ["Low", "Medium", "High"])
    }

    @Test("TemplateCustomField with key decodes key correctly")
    func customFieldKey() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Stage","key":"stage","type":"stage-picker"}]}
        """)
        #expect(t.customFields[0].key == "stage")
    }

    @Test("TemplateCustomField with no placeholder decodes as nil")
    func customFieldNilPlaceholder() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Notes"}]}
        """)
        #expect(t.customFields[0].placeholder == nil)
    }

    @Test("TemplateCustomField with placeholder decodes correctly")
    func customFieldWithPlaceholder() throws {
        let t = try decode("""
        {"name":"test","isPOC":false,"tags":[],"stage":"Discovery","taskTitles":[],
         "customFields":[{"label":"Contract","placeholder":"CNT-001"}]}
        """)
        #expect(t.customFields[0].placeholder == "CNT-001")
    }
}
