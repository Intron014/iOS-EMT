import Foundation
import SwiftData

@Model
final class Credentials {
    let clientId: String
    let passkey: String
    let dateAdded: Date
    
    init(clientId: String, passkey: String) {
        self.clientId = clientId
        self.passkey = passkey
        self.dateAdded = Date()
    }
}
