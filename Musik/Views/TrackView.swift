import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    
    @Binding var opacity: Double
    @Binding var track: Track
    
    @State private var liked = false
    @State private var operating: Bool = false
    
    @State private var didRequestImage = false
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var alert: AlertItem? = nil

    
    var body: some View {
        HStack {
            image
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 42, height: 42)
            Text(trackDisplayName())
                .lineLimit(2)
                .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                .padding(.leading, 15)
                .font(.system(size: 13))
            Spacer()
            likedImage
                .onTapGesture {
                    if !self.operating {
                        if liked {
                            unlike()
                        } else {
                            like()
                        }
                    }
                }
                .padding(.trailing, 5)
        }
        // Ensure the hit box extends across the entire width of the frame.
        // See https://bit.ly/2HqNk4S
        .contentShape(Rectangle())
        .animation(Animation.easeInOut(duration: 0.3), value: self.opacity)
        .background(Color.green.opacity(self.opacity))
        .cornerRadius(13)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
        .onAppear {
            isLiked()
            loadImage()
        }
        .onChange(of: self.track, perform: { _ in
            isLiked()
            self.didRequestImage = false
            loadImage()
        })
    }
    
    /// heart either filled or empty
    var likedImage: some View {
        if liked {
            return Image(systemName: "heart.fill")
                .font(.title)
                .scaleEffect(0.8)
                .foregroundColor(.green)
        } else {
            return Image(systemName: "heart")
                .font(.title)
                .scaleEffect(0.8)
                .foregroundColor(.green)
        }
    }
    
    /// save this track for user
    func like() {
        self.operating = true
        self.liked.toggle()
        if let uri = track.uri {
            spotify.api.saveTracksForCurrentUser([uri])
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { _ in
                        self.operating = false
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
    
    /// save this track for user
    func unlike() {
        self.operating = true
        self.liked.toggle()
        if let uri = track.uri {
            spotify.api.removeSavedTracksForCurrentUser([uri])
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { _ in
                        self.operating = false
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
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
    
    /// check whether track is saved or not and store in self.liked
    func isLiked() {
        if let uri = track.uri {
            spotify.api.currentUserSavedTracksContains([uri])
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { bools in
                        if let liked = bools.first {
                            self.liked = liked
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// load album image
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
