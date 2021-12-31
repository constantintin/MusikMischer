//
//  PlaylistSelectorView.swift
//  Musik
//
//  Created by Constantin Loew on 25.07.21.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Combine

struct PlaylistSelectorView: View {

    @EnvironmentObject var spotify: Spotify

    @State private var currentTrack: Track = .comeTogether
    @State private var playlists: [Playlist<PlaylistItemsReference>] = []
    @State private var playlistViews: [PlaylistSquareView] = []

    @State private var cancellables: Set<AnyCancellable> = []

    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false

    @State private var alert: AlertItem? = nil

    init() { }

    /// Used only by the preview provider to provide sample data.
    fileprivate init(samplePlaylists: [Playlist<PlaylistItemsReference>]) {
        self._playlists = State(initialValue: samplePlaylists)
    }
    
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
            Button("Get currently playing") {
                retrieveCurrentlyPlaying()
            }
            if playlists.isEmpty {
                if isLoadingPlaylists {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Playlists")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if couldntLoadPlaylists {
                    Text("Couldn't Load Playlists")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No Playlists Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                TrackView(track: currentTrack).padding(12)
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns) {
                        ForEach(playlists, id: \.uri) { playlist in
                            PlaylistSquareView(spotify: spotify, playlist: playlist, current: currentTrack)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .navigationTitle("Playlist Selector")
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: retrieve)
    }

    var refreshButton: some View {
        Button(action: retrieve) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPlaylists)
        
    }
    

    
    func retrieve() {
        retrieveCurrentlyPlaying()
        retrievePlaylists()
    }
    
    func retrieveCurrentlyPlaying() {
        spotify.api.currentPlayback()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting context completion: \(completion)")
            }, receiveValue: { context in
                switch context?.item {
                case let .some(.track(track)):
                    currentTrack = track
                default:
                    ()
                }
            })
            .store(in: &cancellables)
    }

    func retrievePlaylists() {
        
        // Don't try to load any playlists if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        var currentUser: SpotifyUser? = nil
        spotify.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting user completion: \(completion)")
            }, receiveValue: { user in
                currentUser = user
            })
            .store(in: &cancellables)
        
        self.isLoadingPlaylists = true
        self.playlists = []
        spotify.api.currentUserPlaylists()
            // Gets all pages of playlists.
            .extendPages(spotify.api)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingPlaylists = false
                    switch completion {
                        case .finished:
                            self.couldntLoadPlaylists = false
                        case .failure(let error):
                            self.couldntLoadPlaylists = true
                            self.alert = AlertItem(
                                title: "Couldn't Retrieve Playlists",
                                message: error.localizedDescription
                            )
                    }
                },
                // We will receive a value for each page of playlists. You could
                // use Combine's `collect()` operator to wait until all of the
                // pages have been retrieved.
                receiveValue: { playlistsPage in
                    let playlists = playlistsPage.items
                    for playlist in playlists {
                        if playlist.isCollaborative || playlist.owner?.uri == currentUser?.uri {
                            self.playlists.append(playlist)
                        }
                    }
                }
            )
            .store(in: &cancellables)

    }
}

struct PlaylistsSelectorView_Previews: PreviewProvider {

    static let spotify = Spotify()

    static let playlists: [Playlist<PlaylistItemsReference>] = [
        .menITrust, .modernPsychedelia, .menITrust,
        .lucyInTheSkyWithDiamonds, .rockClassics,
        .thisIsMFDoom, .thisIsSonicYouth, .thisIsMildHighClub,
        .thisIsSkinshape
    ]

    static var previews: some View {
        NavigationView {
            PlaylistSelectorView(samplePlaylists: playlists)
                .environmentObject(spotify)
        }
    }
}
