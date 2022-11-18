import SwiftUI
import Combine

struct SettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        NavigationView {
            List {
                Button(action: spotify.api.authorizationManager.deauthorize, label: {
                    Text("Logout")
//                        .foregroundColor(.white)
//                        .padding(7)
//                        .background(Color(#colorLiteral(red: 0.3923448698, green: 0.7200681584, blue: 0.19703095, alpha: 1)))
//                        .cornerRadius(10)
//                        .shadow(radius: 3)
                    
                })
                Button("Make Access Token Expired") {
                    self.spotify.api.authorizationManager.setExpirationDate(
                        to: Date()
                    )
                }
                Button("Refresh Access Token") {
                    self.spotify.api.authorizationManager.refreshTokens(
                        onlyIfExpired: false
                    )
                    .sink(receiveCompletion: { completion in
                        print("refresh tokens completion: \(completion)")
                        
                    })
                    .store(in: &self.cancellables)
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}
