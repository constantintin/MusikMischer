//
//  RecoQueuerView.swift
//  Musik
//
//  Created by Constantin Loew on 10.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

struct RecoQueuerView: View {
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
        .navigationBarItems(trailing: reloadButton)
        .navigationTitle("Q 'Recommendations'")
    }
    
    var reloadButton: some View {
        Button(action: loadTracks) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
    }
    
    func loadTracks() {
        self.tracks = []
        self.isLoadingTracks = true
        
        spotify.api.queue()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting context completion: \(completion)")
            }, receiveValue: { context in
                switch context.currentlyPlaying {
                case let .some(.track(track)):
                    if let uri = track.uri {
                        var seedTracks = [uri, uri, uri]
                        seedTracks += context.queue.map(\.uri).compactMap{ $0 }.prefix(2)
                        let seed: TrackAttributes = TrackAttributes(seedTracks: seedTracks)
                        spotify.api.recommendations(seed)
                            .receive(on: RunLoop.main)
                            .sink(
                                receiveCompletion: { completion in
                                    self.isLoadingTracks = false
                                    switch completion {
                                    case .finished:
                                        self.couldntLoadTracks = false
                                    case .failure(let error):
                                        self.couldntLoadTracks = true
                                        print("Error getting recos: \(error.localizedDescription)")
                                        self.alert = AlertItem(
                                            title: "Couldn't retrieve Recos",
                                            message: error.localizedDescription
                                        )
                                    }
                                },
                                receiveValue: { recoResponse in
                                    self.tracks += recoResponse.tracks
                                }
                            )
                            .store(in: &cancellables)
                    }
                default:
                    ()
                }
            })
            .store(in: &cancellables)
        
        
    }
}
