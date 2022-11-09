import SwiftUI

struct FeatureListView: View {
    
    var body: some View {
        List {
            NavigationLink(
                "Sorter", destination: PlaylistSorterView()
            )
            NavigationLink(
                "Queuer", destination: PlaylistOverView()
            )
            NavigationLink(
                "Debug", destination: DebugMenuView()
            )
        }
        .listStyle(.inset)
    }
}
