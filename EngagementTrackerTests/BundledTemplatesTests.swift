import Foundation
import Testing
@testable import Manifest

struct BundledTemplatesTests {

    @Test("loadBundled returns exactly 3 templates")
    func loadBundledCount() {
        let templates = ProjectTemplate.loadBundled()
        #expect(templates.count == 3)
    }

    @Test("loadBundled templates all have isBuiltIn = true")
    func loadBundledIsBuiltIn() {
        let templates = ProjectTemplate.loadBundled()
        #expect(templates.allSatisfy { $0.isBuiltIn })
    }

    @Test("loadBundled templates have expected names")
    func loadBundledNames() {
        let names = Set(ProjectTemplate.loadBundled().map(\.name))
        #expect(names.contains("Base Project"))
        #expect(names.contains("Personal Development"))
        #expect(names.contains("freelance-client"))
    }

    @Test("loadBundled returns templates sorted by name")
    func loadBundledSorted() {
        let names = ProjectTemplate.loadBundled().map(\.name)
        #expect(names == names.sorted())
    }

    @Test("user-loaded templates have isBuiltIn = false")
    func userLoadedIsNotBuiltIn() {
        // Encode a bundled template and decode it back — simulates what load(from:) does
        // isBuiltIn is not in CodingKeys so decode always produces false
        let template = ProjectTemplate.loadBundled().first!
        let data = try! JSONEncoder().encode(template)
        let decoded = try! JSONDecoder().decode(ProjectTemplate.self, from: data)
        #expect(decoded.isBuiltIn == false)
    }
}
