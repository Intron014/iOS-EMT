import Foundation
import SwiftData

@Model
final class FavoriteStation {
    var stationId: String
    var name: String
    var customName: String?
    var dateAdded: Date
    
    init(stationId: String, name: String, customName: String? = nil) {
        self.stationId = stationId
        self.name = name
        self.customName = customName
        self.dateAdded = Date()
    }
}
