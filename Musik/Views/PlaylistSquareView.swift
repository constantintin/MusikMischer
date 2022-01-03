//
//  PlaylistSquareView.swift
//  Musik
//
//  Created by Constantin Loew on 25.07.21.
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
    
    @State private var selected: Bool = false
    @State private var operating: Bool = false
    
    @ObservedObject var current: CurrentTrack
    @State private var snapshot: String
    
    
    init(spotify: Spotify, playlist: Playlist<PlaylistItemsReference>, current: CurrentTrack) {
        self.spotify = spotify
        self.playlist = playlist
        self.current = current
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
        .background(self.selected ? Color.green : Color.gray)
        .cornerRadius(5)
        .onAppear(perform: {
            loadImage()
        })
        .onReceive(current.$track) { track in
            isInPlaylist(track: track)
        }
        .onTapGesture {
            if !self.operating {
                if self.selected {
                    delFromPlaylist()
                } else {
                    addToPlaylist()
                }
            }
        }
    }
    
    func delFromPlaylist() {
        self.operating = true
        if let uri = self.current.track.uri {
            self.spotify.api.removeAllOccurrencesFromPlaylist(self.playlist.uri, of: [uri], snapshotId: self.snapshot)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.operating = false
                        switch completion {
                            case .finished:
                                self.selected.toggle()
                            case .failure(let error):
                                print("Deleting from playlist failed with \(error)")
                        }
                    },
                    receiveValue: { snapshot in
                        self.snapshot = snapshot
                    }
                ).store(in: &cancellables)
        } else {
            print("Current track \(self.current.track) has no uri")
        }
    }
    
    func addToPlaylist() {
        self.operating = true
        if let uri = self.current.track.uri {
            self.spotify.api.addToPlaylist(self.playlist.uri, uris: [uri], position: nil)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.operating = false
                        switch completion {
                            case .finished:
                                self.selected.toggle()
                                print("Added '\(self.current.track.name)' to '\(self.playlist.name)'")
                            case .failure(let error):
                                print("Adding to playlist failed with \(error)")
                        }
                    },
                    receiveValue: { snapshot in
                        self.snapshot = snapshot
                    }
                ).store(in: &cancellables)
        } else {
            print("Current track \(self.current.track) has no uri")
        }
    }
    
    func isInPlaylist(track: Track) {
        self.spotify.api.playlistItems(self.playlist.uri)
            .extendPagesConcurrently(self.spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    print("Getting playlist item completion: \(completion)")
                },
                receiveValue: { trackPage in
                    for playlistTrack in trackPage.items {
                        if track.uri == playlistTrack.item?.uri {
                            self.selected = true
                            return
                        }
                    }
                }
            )
            .store(in: &cancellables)
        self.selected = false
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
    @State static var selected = false
    
    static var previews: some View {
        ScrollView(.vertical) {
            VStack {
                PlaylistSquareView(spotify: spotify, playlist: .rockClassics, current: CurrentTrack(.comeTogether))
                PlaylistSquareView(spotify: spotify, playlist: .thisIsRadiohead, current: CurrentTrack(.comeTogether))
            }
            .environmentObject(spotify)
        }
    }
}
