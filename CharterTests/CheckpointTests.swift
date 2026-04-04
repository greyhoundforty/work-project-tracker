import Foundation
import Testing
@testable import Charter

@Suite("Checkpoint")
struct CheckpointTests {

    @Test("init creates uncompleted checkpoint with correct properties")
    func initProperties() {
        let cp = Checkpoint(title: "Discovery call scheduled", stage: .discovery, sortOrder: 0)
        #expect(cp.title == "Discovery call scheduled")
        #expect(cp.stage == .discovery)
        #expect(cp.sortOrder == 0)
        #expect(cp.isCompleted == false)
        #expect(cp.completedAt == nil)
    }

    @Test("each checkpoint gets a unique id")
    func uniqueIDs() {
        let cp1 = Checkpoint(title: "Step A", stage: .discovery, sortOrder: 0)
        let cp2 = Checkpoint(title: "Step B", stage: .discovery, sortOrder: 1)
        #expect(cp1.id != cp2.id)
    }

    @Test("toggle marks checkpoint as completed and sets completedAt")
    func toggleToCompleted() {
        let cp = Checkpoint(title: "Test", stage: .discovery, sortOrder: 0)
        cp.toggle()
        #expect(cp.isCompleted == true)
        #expect(cp.completedAt != nil)
    }

    @Test("toggle twice restores checkpoint to uncompleted and clears completedAt")
    func toggleTwiceResetsState() {
        let cp = Checkpoint(title: "Test", stage: .discovery, sortOrder: 0)
        cp.toggle()
        cp.toggle()
        #expect(cp.isCompleted == false)
        #expect(cp.completedAt == nil)
    }

    @Test("completedAt is set to a recent timestamp when toggled to completed")
    func completedAtIsRecent() {
        let before = Date()
        let cp = Checkpoint(title: "Test", stage: .proposal, sortOrder: 1)
        cp.toggle()
        let after = Date()
        #expect(cp.completedAt != nil)
        if let completedAt = cp.completedAt {
            #expect(completedAt >= before)
            #expect(completedAt <= after)
        }
    }

    @Test("toggle works for any stage")
    func toggleWorksForAllStages() {
        for stage in ProjectStage.allCases {
            let cp = Checkpoint(title: "Step", stage: stage, sortOrder: 0)
            cp.toggle()
            #expect(cp.isCompleted == true)
        }
    }
}
