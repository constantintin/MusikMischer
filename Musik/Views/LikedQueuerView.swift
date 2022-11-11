//
//  LikedQueuerView.swift
//  Musik
//
//  Created by Constantin Loew on 10.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

struct LikedQueuerView: View {
    var spotify: Spotify
    
    @State private var tracks: [Track] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    
    @State private var alert: AlertItem? = nil
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    var body: some View {
        VStack {
            if tracks.isEmpty {
                if isLoadingTracks {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Tracks")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadTracks {
                    Text("Couldn't Load Tracks")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No Tracks Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(self.tracks, id: \.uri) { track in
                            TrackQueueableView(track: track)
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadTracks)
        .navigationBarItems(trailing: shuffleButton)
        .navigationTitle("Q 'Liked Songs'")
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
        self.isLoadingTracks = true
        
        spotify.api.currentUserSavedTracks()
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingTracks = false
                    switch completion {
                        case .finished:
                            self.couldntLoadTracks = false
                        case .failure(let error):
                            self.couldntLoadTracks = true
                            self.alert = AlertItem(
                                title: "Couldn't Retrieve Tracks",
                                message: error.localizedDescription
                            )
                    }
                },
                receiveValue: { savedTracksPage in
                    self.tracks += savedTracksPage.items.map(\.item)
                }
            )
            .store(in: &cancellables)
    }
}
