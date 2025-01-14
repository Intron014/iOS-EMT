import SwiftUI
import SwiftData

struct CredentialsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var clientId = ""
    @State private var passkey = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Query private var existingCredentials: [Credentials]
    var refreshCallback: (() -> Void)? = nil
    
    private func obfuscateString(_ input: String) -> String {
        guard input.count > 4 else { return input }
        return String(input.prefix(4)) + String(repeating: "•", count: 16)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let existing = existingCredentials.first {
                    Section(header: Text("Current Credentials")) {
                        Text("Client ID: \(obfuscateString(existing.clientId))")
                        Text("Passkey: \(obfuscateString(existing.passkey))")
                    }
                }
                
                Section(header: Text("New Credentials")) {
                    TextField("Client ID", text: $clientId)
                    TextField("Passkey", text: $passkey)
                }
                
                Section {
                    Text("You can get your credentials at:")
                    Link("EMT Mobility Labs", 
                         destination: URL(string: "https://mobilitylabs.emtmadrid.es/")!)
                }
                
                Button("Validate and Save") {
                    Task {
                        await validateAndSave()
                    }
                }
                .disabled(clientId.isEmpty || passkey.isEmpty)
            }
            .navigationTitle("Setup")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func validateAndSave() async {
        do {
            // Try to get a token with the provided credentials
            var token = try await TokenManager.shared.validateCredentials(
                clientId: clientId,
                passkey: passkey
            )
            
            // If successful, save credentials
            let credentials = Credentials(clientId: clientId, passkey: passkey)
            modelContext.insert(credentials)
            isPresented = false
            refreshCallback?()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
