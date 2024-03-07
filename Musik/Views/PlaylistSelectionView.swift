//
//  PlaylistSelectionView.swift
//  Musik
//
//  Created by Constantin Loew on 25.07.21.
//

import Foundation
import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistSelectionView: View {
    var spotify: Spotify
    @Environment(\.openURL) var openURL
    
    private let playlist: Playlist<PlaylistItemsReference>
    /// The cover image for the playlist.
    @State private var image = Image(ImageName.spotifyAlbumPlaceholder)

    @State private var didRequestImage = false
    
    @State private var selected: Bool = false
    @State private var operating: Bool = false
    @State private var trackUris: [String] = []
    @State private var tracksCached: Bool = false
    
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
                .aspectRatio(contentMode: .fill)
                .frame(width: 111, height: 111, alignment: .center)
                .saturation(self.selected ? 1.0 : 0.5)
                .clipped()
                .overlay(progressView, alignment: .center)
            Text(self.playlist.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.system(size: 14))
                .padding([.leading, .trailing, .bottom], 5)
        }
        .frame(maxWidth: 111)
        .background(
            LinearGradient(colors: [self.selected ? Color.green : Color.gray.opacity(0.3), .clear, self.selected ? Color.green : Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(5)
        .shadow(radius: 3)
        .onAppear(perform: {
            loadImage()
        })
        .onReceive(current.$track) { track in
            isInPlaylist(track: track)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !self.operating {
                if self.selected {
                    delFromPlaylist()
                } else {
                    addToPlaylist()
                }
            }
        }
        .onLongPressGesture(perform: {
            if let url = URL(string: playlist.uri) {
                openURL(url)
            }
        })
    }
    
    /// progress view if operating
    var progressView: some View {
        Group {
            if operating {
                ProgressView()
            } else {
                EmptyView()
            }
        }
    }
    
    /// remove all occurrences of current.track from playlist
    func delFromPlaylist() {
        self.operating = true
        self.selected.toggle()
        if let uri = self.current.track?.uri {
            self.spotify.api.removeAllOccurrencesFromPlaylist(self.playlist.uri, of: [uri], snapshotId: self.snapshot)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.operating = false
                        switch completion {
                            case .finished:
                                self.trackUris.removeAll { value in
                                    value == uri
                                }
                                print("Removed '\(self.current.track?.name ?? "")' from '\(self.playlist.name)'")
                            case .failure(let error):
                                self.selected.toggle()
                                print("Deleting from playlist failed with \(error)")
                        }
                    },
                    receiveValue: { snapshot in
                        self.snapshot = snapshot
                    }
                ).store(in: &cancellables)
        } else {
            print("Current track has no uri, not deleting from playlist")
        }
    }
    
    /// add current.track to playlist
    func addToPlaylist() {
        self.operating = true
        self.selected.toggle()
        if let uri = self.current.track?.uri {
            self.spotify.api.addToPlaylist(self.playlist.uri, uris: [uri], position: nil)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        self.operating = false
                        switch completion {
                            case .finished:
                                self.trackUris.append(uri)
                                print("Added '\(self.current.track?.name ?? "")' to '\(self.playlist.name)'")
                            case .failure(let error):
                                self.selected.toggle()
                                print("Adding to playlist failed with \(error)")
                        }
                    },
                    receiveValue: { snapshot in
                        self.snapshot = snapshot
                    }
                ).store(in: &cancellables)
        } else {
            print("Current track has no uri, not adding to playlist")
        }
    }
    
    /// check if track is in the playlist
    /// after first runthrough results are cached in self.trackUris
    func isInPlaylist(track: Track?) {
        if self.tracksCached {
            print("Using cached tracks for \(self.playlist.name)")
            if let trackUri = track?.uri {
                self.selected = self.trackUris.contains(trackUri)
            } else {
                print("Track '\(track?.name ?? "")' has no uri, can't check if in playlist")
            }
        } else {
            self.selected = false
            self.spotify.api.playlistItems(self.playlist.uri)
                .extendPagesConcurrently(self.spotify.api)
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { _ in
                        self.tracksCached = true
                    },
                    receiveValue: { trackPage in
                        for playlistTrack in trackPage.items {
                            if track?.uri == playlistTrack.item?.uri {
                                self.selected = true
                            }
                            if let uri = playlistTrack.item?.uri {
                                self.trackUris.append(uri)
                            }
                        }
                    }
                )
                .store(in: &cancellables)
        }
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
