//
//  LikedQueuerView.swift
//  Musik
//
//  Created by Constantin Loew on 10.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import MusicKit
import Combine

struct LikedQueuerView: View {
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var backend: Backend
    
    @State private var tracks: [MusikTrack] = []
    @State private var filteredTracks: [MusikTrack] = []
    
    @State private var searchText = ""
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    
    @State private var alert: AlertItem? = nil
    
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
                    LazyVStack(alignment: .leading, spacing: 5) {
                        ForEach(self.filteredTracks, id: \.id) { track in
                            TrackQueueableView(track)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search By Song Name")
                .onChange(of: searchText) { _ in
                    filterTracks()
                }
                .onSubmit(of: .search) {
                    filterTracks()
                }
            }
        }
        .onAppear {
            loadLikedTracks(self.backend.type)
        }
        .navigationBarTitle("Liked Songs")
        .navigationBarItems(trailing:
                                HStack {
            SpotifyButtonView(uriString: "https://open.spotify.com/collection/tracks")
            shuffleButton
        })
    }
    
    /// filter tracks based on search
    func filterTracks() {
        if searchText.isEmpty {
            filteredTracks = tracks
        } else {
            filteredTracks = tracks.filter {
                var trackTextToSearch = $0.title
                for artist in $0.artists {
                    trackTextToSearch += " \(artist)"
                    
                }
                return trackTextToSearch.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var shuffleButton: some View {
        Button(action: shuffleTracks) {
            Image(systemName: "shuffle")
                .font(.title)
                .imageScale(.medium)
        }
        .frame(width: 42)
    }
    
    func shuffleTracks() {
        self.filteredTracks.shuffle()
    }
    
    
    func loadLikedTracks(_ backend: BackendType) {
        switch backend {
        case .spotify:
            loadLikedTracksSpotify()
        case .appleMusic:
            loadLikedTracksAppleMusic()
        }
    }
    
    func loadLikedTracksSpotify() {
        self.isLoadingTracks = true
        
        spotify.api.currentUserSavedTracks()
            .extendPagesConcurrently(spotify.api)
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
                    self.tracks += savedTracksPage.items.map { MusikTrack(spotifyTrack: $0.item) }
                    self.filteredTracks += savedTracksPage.items.map { MusikTrack(spotifyTrack: $0.item) }
                }
            )
            .store(in: &cancellables)
        
    }
    
    func loadLikedTracksAppleMusic() {
        print("Load apple music liked tracks")
    }

}
