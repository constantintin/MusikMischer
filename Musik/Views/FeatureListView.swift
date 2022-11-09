import SwiftUI

struct FeatureListView: View {
    
    var body: some View {
        List {
            NavigationLink(
                "Sorter", destination: PlaylistSelectorView()
            )
            NavigationLink(
                "Queuer", destination: PlaylistOverView()
            )
            NavigationLink(
                "Debug Menu", destination: DebugMenuView()
            )
            
            // This is the location where you can add your own views to test out
            // your application. Each view receives an instance of `Spotify`
            // from the environment.
            
        }
        .listStyle(PlainListStyle())
        
    }
}
