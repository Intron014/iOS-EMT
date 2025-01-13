import Foundation
import SwiftData

@Model
final class Credentials {
    var clientId: String
    var passkey: String
    var dateAdded: Date
    
    init(clientId: String, passkey: String) {
        self.clientId = clientId
        self.passkey = passkey
        self.dateAdded = Date()
    }
}
