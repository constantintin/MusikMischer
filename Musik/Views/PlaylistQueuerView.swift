//
//  PlaylistRandomizerView.swift
//  Musik
//
//  Created by Constantin Loew on 08.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

struct PlaylistQueuerView: View {
    var spotify: Spotify
    private let playlist: Playlist<PlaylistItemsReference>
    @State private var tracks: [Track] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    init(spotify: Spotify, playlist: Playlist<PlaylistItemsReference>) {
        self.spotify = spotify
        self.playlist = playlist
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(self.tracks, id: \.uri) { track in
                    TrackQueueableView(track: track)
                }
            }
        }
        .onAppear(perform: loadTracks)
        .navigationBarTitle(self.playlist.name)
        .navigationBarItems(trailing: shuffleButton)
    }
    
    var shuffleButton: some View {
        Button(action: shuffleTracks) {
            Image(systemName: "shuffle")
                .font(.title)
                .scaleEffect(0.8)
        }
    }
    
    func shuffleTracks() {
        self.tracks.shuffle()
    }
    
    func loadTracks() {
        self.spotify.api.playlistItems(self.playlist.uri)
            .extendPagesConcurrently(self.spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    print("Getting playlist item completion: \(completion)")
                },
                receiveValue: { trackPage in
                    for playlistTrack in trackPage.items {
                        switch playlistTrack.item {
                        case .track(let track):
                            self.tracks.append(track)
                        default:
                            break
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
}
