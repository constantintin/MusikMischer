import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct TrackView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    
    @Binding var track: Track?
    
    @State private var liked = false
    @State private var operating: Bool = false
    
    @State private var didRequestImage = false
    @State private var image = Image(ImageName.spotifyAlbumPlaceholder)

    @State private var alert: AlertItem? = nil

    
    var body: some View {
        Group {
            if let track = track {
                HStack {
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading) {
                        Text(track.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Text(trackArtists())
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        if !self.operating {
                            if liked {
                                unlike()
                            } else {
                                like()
                            }
                        }
                    } label: {
                        likedImage
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 5)
                }
            } else {
                HStack {
                    Spacer()
                    VStack {
                        Text("No song selected")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .frame(height: 42)
            }
        }
        // Ensure the hit box extends across the entire width of the frame.
        // See https://bit.ly/2HqNk4S
        .contentShape(Rectangle())
        .background(
            LinearGradient(colors: [Color.gray.opacity(0.1), .clear, Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
        .cornerRadius(5)
        .shadow(radius: 3)
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
        Group {
            if liked {
                Image(systemName: "heart.fill")
                    .font(.body)
                    .imageScale(.large)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "heart")
                    .font(.body)
                    .imageScale(.large)
                    .foregroundColor(.green)
            }
        }
    }
    
    /// save this track for user
    func like() {
        self.operating = true
        self.liked.toggle()
        if let uri = track?.uri {
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
        if let uri = track?.uri {
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
    func trackArtists() -> String {
        var display = ""
        if let artists = track?.artists {
            for artist in artists {
                display += "\(artist.name), "
            }
            display = String(display.dropLast(2))
        }
        return display
    }
    
    /// check whether track is saved or not and store in self.liked
    func isLiked() {
        if let uri = track?.uri {
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
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = self.track?.album?.images?.last else {
            return
        }

        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    self.image = image
                }
            )
    }
}
