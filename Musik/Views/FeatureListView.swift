import SwiftUI

struct FeatureListView: View {
    
    var body: some View {
        VStack {
            List {
                NavigationLink {
                    SorterOverView()
                } label: {
                    Text("Sorter")
                        .font(.title)
                }
                NavigationLink {
                    QueuerOverView()
                } label: {
                    Text("Queuer")
                        .font(.title)
                }
            }
            Spacer()
                .frame(maxHeight: .infinity)
            List {
                NavigationLink {
                    DebugMenuView()
                } label: {
                    Text("Debug")
                }
            }
            .listStyle(.plain)
        }
    }
}
