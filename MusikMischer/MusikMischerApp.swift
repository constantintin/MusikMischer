import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct MusikMischerApp: App {

    @StateObject var spotify = Spotify()

    init() {
        SpotifyAPILogHandler.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
        }
    }
    
}
