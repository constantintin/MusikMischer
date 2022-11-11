//
//  PlaylistSquareView.swift
//  Musik
//
//  Created by Constantin Loew on 08.11.22.
//

import Foundation
import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistSquareView: View {
    var spotify: Spotify
    
    private let playlist: Playlist<PlaylistItemsReference>
    /// The cover image for the playlist.
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var didRequestImage = false
    @State private var snapshot: String
    
    @State private var shouldNavigate = false
    
    init(spotify: Spotify, playlist: Playlist<PlaylistItemsReference>) {
        self.spotify = spotify
        self.playlist = playlist
        _snapshot = State(initialValue: self.playlist.snapshotId)
    }
    
    // MARK: Cancellables
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        VStack {
            image
                .resizable()
                .aspectRatio(1, contentMode: .fill)
            Text(self.playlist.name)
                .lineLimit(1)
                .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                .font(.system(size: 12))
                .padding(5)
        }
        .background(Color.gray.opacity(0.3))
        .cornerRadius(5)
        .onAppear(perform: {
            loadImage()
        })
    }


    
    /// Loads the image for the playlist.
    func loadImage() {
        
        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
        if self.didRequestImage {
            // print("already requested image for '\(playlist.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = self.playlist.images.largest else {
            // print("no image found for '\(playlist.name)'")
            return
        }

        // print("loading image for '\(playlist.name)'")
        
        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(playlist.name)'")
                    self.image = image
                }
            )
    }
}

struct PlaylistSquare_Previews: PreviewProvider {
    static let spotify = Spotify()
    
    static var previews: some View {
        ScrollView(.vertical) {
            VStack {
                PlaylistSquareView(spotify: spotify, playlist: .rockClassics)
                PlaylistSquareView(spotify: spotify, playlist: .thisIsRadiohead)
            }
            .environmentObject(spotify)
        }
    }
}
