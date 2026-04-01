import Foundation
import SwiftData

@Model
final class ProjectCustomField {
    var label: String
    var value: String
    var sortOrder: Int
    var project: Project?

    init(label: String, value: String = "", sortOrder: Int) {
        self.label = label
        self.value = value
        self.sortOrder = sortOrder
    }
}
