import Foundation
import SwiftData

class TokenManager {
    static let shared = TokenManager()
    private var currentToken: String?
    private var currentApiStats: ApiCounter?
    
    private init() {}
    
    func getApiStats() -> ApiCounter? {
        return currentApiStats
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
        currentApiStats = loginResponse.data.first?.apiCounter
        
        return token
    }
    
    func getToken(using credentials: Credentials) async throws -> String {
        if let token = currentToken {
            return token
        }
        
        let token = try await validateCredentials(
            clientId: credentials.clientId,
            passkey: credentials.passkey
        )
        
        currentToken = token
        return token
    }
}
