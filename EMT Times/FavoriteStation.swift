import Foundation
import SwiftData

@Model
final class FavoriteStation {
    let stationId: String
    let name: String
    var customName: String?
    let dateAdded: Date
    
    init(stationId: String, name: String, customName: String? = nil) {
        self.stationId = stationId
        self.name = name
        self.customName = customName
        self.dateAdded = Date()
    }
}
