import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var backgroundOpacity = 0.0
    
    @State private var didRequestImage = false
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var alert: AlertItem? = nil
    
    let track: Track
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 15)
            HStack {
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 42, height: 42)
                Spacer()
                    .frame(width: 15)
                Text(trackDisplayName())
                    .lineLimit(2)
                    .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                    .font(.system(size: 13))
                Spacer()
            }
            // Ensure the hit box extends across the entire width of the frame.
            // See https://bit.ly/2HqNk4S
            .contentShape(Rectangle())
            .animation(Animation.easeInOut(duration: 0.5), value: self.backgroundOpacity)
            .background(Color.green.opacity(self.backgroundOpacity))
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onAppear {
                loadImage()
            }
            .onTapGesture {
                self.backgroundOpacity = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.backgroundOpacity = 0.0
                }
            }
        }
    }
    
    /// The display name for the track. E.g., "Eclipse - Pink Floyd".
    func trackDisplayName() -> String {
        var displayName = track.name
        if let artistName = track.artists?.first?.name {
            displayName += " - \(artistName)"
        }
        return displayName
    }
    
    func loadImage() {
        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
        if self.didRequestImage {
            // print("already requested image for '\(self.track.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = self.track.album?.images?.largest else {
            // print("no image found for '\(self.track.name)'")
            return
        }

        // print("loading image for '\(self.track.name)'")
        
        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(self.track.name)'")
                    self.image = image
                }
            )
    }
}

struct TrackView_Previews: PreviewProvider {
    
    static let tracks: [Track] = [
        .because, .comeTogether, .faces,
        .illWind, .odeToViceroy, .reckoner,
        .theEnd, .time
    ]

    static var previews: some View {
        List(tracks, id: \.id) { track in
            TrackView(track: track)
        }
        .environmentObject(Spotify())
    }
}
