import SwiftUI
import Combine
import SpotifyWebAPI

enum BackendType: String, CaseIterable, Identifiable{
    case spotify
    case appleMusic
    var id: Self { self}
}

class Backend: ObservableObject {
    @Published var type: BackendType = .spotify
}

@main
struct MusikApp: App {

    @StateObject var spotify = Spotify()
    @StateObject var backend = Backend()

    init() {
        SpotifyAPILogHandler.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
                .environmentObject(backend)
        }
    }
    
}
