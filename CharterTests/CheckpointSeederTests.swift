import Testing
@testable import Charter

@Suite("CheckpointSeeder")
struct CheckpointSeederTests {

    @Test func discoveryTitles() {
        let titles = CheckpointSeeder.titles(for: .discovery)
        #expect(titles.count == 4)
        #expect(titles[0] == "Discovery call scheduled")
        #expect(titles[1] == "Discovery call completed")
        #expect(titles[2] == "Stakeholders identified")
        #expect(titles[3] == "Pain points documented")
    }

    @Test func initialDeliveryTitles() {
        let titles = CheckpointSeeder.titles(for: .initialDelivery)
        #expect(titles.count == 3)
        #expect(titles[0] == "Solution / BOM draft started")
        #expect(titles[1] == "Initial BOM delivered")
        #expect(titles[2] == "Architecture overview shared")
    }

    @Test func refineTitles() {
        let titles = CheckpointSeeder.titles(for: .refine)
        #expect(titles.count == 3)
        #expect(titles[0] == "Customer feedback received")
        #expect(titles[1] == "BOM / solution revised")
        #expect(titles[2] == "Technical deep-dive completed")
    }

    @Test func proposalTitles() {
        let titles = CheckpointSeeder.titles(for: .proposal)
        #expect(titles.count == 3)
        #expect(titles[0] == "Proposal drafted")
        #expect(titles[1] == "Internal review complete")
        #expect(titles[2] == "Proposal delivered to customer")
    }

    @Test func wonTitles() {
        let titles = CheckpointSeeder.titles(for: .won)
        #expect(titles.count == 1)
        #expect(titles[0] == "Contract / order signed")
    }

    @Test func lostTitles() {
        let titles = CheckpointSeeder.titles(for: .lost)
        #expect(titles.count == 1)
        #expect(titles[0] == "Close reason documented")
    }

    @Test func allActiveStagesSeeded() {
        let active: [ProjectStage] = [.discovery, .initialDelivery, .refine, .proposal]
        for stage in active {
            #expect(!CheckpointSeeder.titles(for: stage).isEmpty, "Stage \(stage.rawValue) has no checkpoints")
        }
    }

    @Test func checkpointsHaveCorrectStageAndOrder() {
        let checkpoints = CheckpointSeeder.makeCheckpoints(for: .discovery)
        #expect(checkpoints.count == 4)
        for (i, cp) in checkpoints.enumerated() {
            #expect(cp.stage == .discovery)
            #expect(cp.sortOrder == i)
            #expect(cp.isCompleted == false)
        }
    }

    @Test func makeAllCheckpointsProducesExpectedTotal() {
        let all = CheckpointSeeder.makeAllCheckpoints()
        let expected = ProjectStage.allCases.reduce(0) { $0 + CheckpointSeeder.titles(for: $1).count }
        #expect(all.count == expected)
    }

    @Test func makeAllCheckpointsContainsAllStages() {
        let all = CheckpointSeeder.makeAllCheckpoints()
        let stagesPresent = Set(all.map(\.stage))
        #expect(stagesPresent == Set(ProjectStage.allCases))
    }
}
