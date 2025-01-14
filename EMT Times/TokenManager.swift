import Foundation
import SwiftData

class TokenManager {
    static let shared = TokenManager()
    private var currentToken: String?
    private var tokenExpiration: Date?
    private var apiStats: ApiCounter?
    private let userDefaults = UserDefaults.standard
    
    private init() {
        if let savedStats = userDefaults.data(forKey: "apiStats"),
           let decoded = try? JSONDecoder().decode(ApiCounter.self, from: savedStats) {
            self.apiStats = decoded
        }
    }
    
    func getApiStats() -> ApiCounter? {
        return apiStats
    }
    
    func validateCredentials(clientId: String, passkey: String) async throws -> String {
        guard let loginURL = URL(string: "https://openapi.emtmadrid.es/v1/mobilitylabs/user/login/") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "GET"
        request.addValue(clientId, forHTTPHeaderField: "X-ClientId")
        request.addValue(passkey, forHTTPHeaderField: "passKey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        guard let token = loginResponse.data.first?.accessToken else {
            throw URLError(.cannotParseResponse)
        }
        
        // Store the API stats
        apiStats = loginResponse.data.first?.apiCounter
        
        if let encoded = try? JSONEncoder().encode(loginResponse.data.first?.apiCounter) {
            userDefaults.set(encoded, forKey: "apiStats")
        }
        
        return token
    }
    
    func getToken(using credentials: Credentials) async throws -> String {
        if let currentToken = currentToken,
           let expiration = tokenExpiration,
           Date() < expiration {
            return currentToken
        }
        
        let token = try await validateCredentials(
            clientId: credentials.clientId,
            passkey: credentials.passkey
        )
        
        currentToken = token
        tokenExpiration = Date().addingTimeInterval(3600) // 1 hour
        return token
    }
}
