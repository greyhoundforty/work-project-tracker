import Testing
@testable import Manifest

@Suite("ProjectStage")
struct ProjectStageTests {

    @Test func stageProgression() {
        #expect(ProjectStage.discovery.next == .initialDelivery)
        #expect(ProjectStage.initialDelivery.next == .refine)
        #expect(ProjectStage.refine.next == .proposal)
        #expect(ProjectStage.proposal.next == nil)
    }

    @Test func terminalStages() {
        #expect(ProjectStage.won.isTerminal == true)
        #expect(ProjectStage.lost.isTerminal == true)
        #expect(ProjectStage.discovery.isTerminal == false)
        #expect(ProjectStage.proposal.isTerminal == false)
    }

    @Test func allCasesCount() {
        #expect(ProjectStage.allCases.count == 6)
    }
}
