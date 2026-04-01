import Foundation

enum CheckpointSeeder {

    static func titles(for stage: ProjectStage) -> [String] {
        switch stage {
        case .discovery:
            return [
                "Discovery call scheduled",
                "Discovery call completed",
                "Stakeholders identified",
                "Pain points documented"
            ]
        case .initialDelivery:
            return [
                "Solution / BOM draft started",
                "Initial BOM delivered",
                "Architecture overview shared"
            ]
        case .refine:
            return [
                "Customer feedback received",
                "BOM / solution revised",
                "Technical deep-dive completed"
            ]
        case .proposal:
            return [
                "Proposal drafted",
                "Internal review complete",
                "Proposal delivered to customer"
            ]
        case .won:
            return ["Contract / order signed"]
        case .lost:
            return ["Close reason documented"]
        }
    }

    /// Creates Checkpoint model objects for a single stage (not inserted into context).
    static func makeCheckpoints(for stage: ProjectStage) -> [Checkpoint] {
        titles(for: stage).enumerated().map { index, title in
            Checkpoint(title: title, stage: stage, sortOrder: index)
        }
    }

    /// Creates Checkpoint model objects for all stages.
    static func makeAllCheckpoints() -> [Checkpoint] {
        ProjectStage.allCases.flatMap { makeCheckpoints(for: $0) }
    }
}
