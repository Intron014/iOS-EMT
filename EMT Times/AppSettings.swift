import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("defaultApp") var defaultApp: String?
    
    static let shared = AppSettings()
    private init() {}
}
