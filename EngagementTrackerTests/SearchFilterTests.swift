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
}
