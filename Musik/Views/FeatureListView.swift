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
            NavigationLink {
                DebugMenuView()
            } label: {
                Text("Debug")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: 42)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(5)
            .buttonStyle(.plain)
            .padding(13)
        }
    }
}
