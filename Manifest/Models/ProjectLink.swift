import Foundation
import SwiftData

@Model
final class ProjectLink {
    var name: String
    var url: String
    var sortOrder: Int
    var project: Project?

    init(name: String = "", url: String = "", sortOrder: Int) {
        self.name = name
        self.url = url
        self.sortOrder = sortOrder
    }
}
