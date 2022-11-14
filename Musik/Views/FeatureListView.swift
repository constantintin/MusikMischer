import SwiftUI

struct FeatureListView: View {
    
    var body: some View {
        List {
            NavigationLink(
                "Sorter", destination: SorterOverView()
            )
            NavigationLink(
                "Queuer", destination: QueuerOverView()
            )
            NavigationLink(
                "Debug", destination: DebugMenuView()
            )
        }
        .listStyle(.inset)
    }
}
