import Testing
@testable import EngagementTracker

@Suite("Search Filtering")
struct SearchFilterTests {

    private func makeProject(name: String, account: String? = nil, stage: ProjectStage = .discovery) -> Project {
        Project(name: name, accountName: account, stage: stage)
    }

    @Test func matchesOnName() {
        let project = makeProject(name: "Acme Corp")
        let q = "acme"
        let matches = project.name.lowercased().contains(q)
        #expect(matches == true)
    }

    @Test func matchesOnAccountName() {
        let project = makeProject(name: "Deal 001", account: "GlobalBank")
        let q = "global"
        let matches = (project.accountName?.lowercased().contains(q) ?? false)
        #expect(matches == true)
    }

    @Test func noMatchOnUnrelatedQuery() {
        let project = makeProject(name: "Acme Corp", account: "Acme")
        let q = "xyz"
        let matchesName = project.name.lowercased().contains(q)
        let matchesAccount = project.accountName?.lowercased().contains(q) ?? false
        #expect(matchesName == false)
        #expect(matchesAccount == false)
    }

    @Test func estimatedValueCentsConversion() {
        let project = Project(name: "Test", estimatedValueCents: 24000000)
        let formatted = project.estimatedValueFormatted
        #expect(formatted != nil)
        #expect(formatted!.contains("240,000") || formatted!.contains("240000"))
    }

    @Test func nilValueReturnsNilFormatted() {
        let project = Project(name: "Test", estimatedValueCents: nil)
        #expect(project.estimatedValueFormatted == nil)
    }

    @Test func matchesOnTag() {
        let project = Project(name: "Deal 001", tags: ["cloud", "security"])
        let q = "cloud"
        let matches = project.tags.contains { $0.lowercased().contains(q) }
        #expect(matches == true)
    }

    @Test func matchesOnTagPartial() {
        let project = Project(name: "Deal 001", tags: ["cloud-native", "security"])
        let q = "native"
        let matches = project.tags.contains { $0.lowercased().contains(q) }
        #expect(matches == true)
    }

    @Test func noMatchOnAbsentTag() {
        let project = Project(name: "Deal 001", tags: ["cloud", "security"])
        let q = "networking"
        let matches = project.tags.contains { $0.lowercased().contains(q) }
        #expect(matches == false)
    }

    @Test func matchesOnStageRawValue() {
        let project = makeProject(name: "Deal 001", stage: .proposal)
        let q = "proposal"
        let matches = project.stage.rawValue.lowercased().contains(q)
        #expect(matches == true)
    }

    @Test func matchesOnStagePartial() {
        let project = makeProject(name: "Deal 001", stage: .initialDelivery)
        let q = "initial"
        let matches = project.stage.rawValue.lowercased().contains(q)
        #expect(matches == true)
    }
}
