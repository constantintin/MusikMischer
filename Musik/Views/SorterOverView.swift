//
//  SorterOverView.swift
//  Musik
//
//  Created by Constantin Loew on 25.07.21.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import SpotifyWebAPI
import SpotifyExampleContent

class CurrentTrack: ObservableObject {
    @Published var track: Track?
    init() {
        self.track = nil
    }
}

struct SorterOverView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var spotify: Spotify
    
    @StateObject private var currentTrack: CurrentTrack = CurrentTrack()
    @State private var playlists: [Playlist<PlaylistItemsReference>] = []
    @State private var filteredPlaylists: [Playlist<PlaylistItemsReference>] = []
    
    @State private var searchText = ""
    
    @State private var trackIsLoading: Bool = false
    @State private var retrieveTimer: Timer? = nil
    @State private var syncing = false
    
    @State private var presentSearch = false
    @State private var trackSearchText = ""
    @State private var searchTracks: [Track] = []
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    @FocusState private var focusTrackSearch: Bool
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var loadedPlaylists = false
    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
    @State private var newPlaylistName: String = ""
    @FocusState private var newPlaylistFieldIsFocused: Bool
    
    @State private var alert: AlertItem? = nil
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                VStack {
                    if playlists.isEmpty {
                        if isLoadingPlaylists {
                            HStack {
                                ProgressView()
                                    .padding()
                                Text("Loading Playlists")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        else if couldntLoadPlaylists {
                            Text("Couldn't Load Playlists")
                                .font(.title)
                                .foregroundColor(.secondary)
                                .frame(maxHeight: .infinity)
                        }
                        else {
                            Text("No Playlists Found")
                                .font(.title)
                                .foregroundColor(.secondary)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    else {
                        ScrollView(.vertical) {
                            LazyVGrid(columns: [GridItem](repeating: GridItem(.flexible()), count: numColumns(geo.size.width))) {
                                ForEach(filteredPlaylists, id: \.uri) { playlist in
                                    PlaylistSelectionView(spotify: spotify, playlist: playlist, current: currentTrack)
                                }
                                if !searchText.isEmpty {
                                    newPlaylistButton
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search By Playlist Name")
                        .onChange(of: searchText) { _ in
                            filterPlaylists()
                        }
                        .onSubmit(of: .search) {
                            filterPlaylists()
                        }
                        .padding([.leading, .trailing], 10)
                    }
                    Divider()
                        .padding(.horizontal, 23)
                    HStack {
                        syncButton
                            .padding(.trailing, 5)
                        TrackView(track: $currentTrack.track)
                            .onTapGesture {
                                self.presentSearch = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.focusTrackSearch = true
                                }
                            }
                            .onLongPressGesture(perform: {
                                if let artistUri = currentTrack.track?.album?.uri {
                                    if let url = URL(string: artistUri) {
                                        openURL(url)
                                    }
                                }
                            })
                        skipButton
                            .padding(.leading, 5)
                    }
                    .padding([.horizontal], 10)
                    .padding(.top, 2)
                    .padding(.bottom, 7)
                }
                .navigationBarTitle("Sort")
                .navigationBarItems(trailing:
                                        HStack {
                    SpotifyButtonView(uriString: "spotify:")
                    refreshButton
                })
                .alert(item: $alert) { alert in
                    Alert(title: alert.title, message: alert.message)
                }
                .onAppear {
                    if self.syncing {
                        retrieveCurrentlyPlaying()
                    }
                    if !loadedPlaylists {
                        retrievePlaylists()
                        loadedPlaylists = true
                    }
                }
            }
            .sheet(isPresented: $presentSearch) {
                trackSearchSelect
                    .presentationDetents([.large])
            }
        }
    }
    
    var trackSearchSelect: some View {
        ScrollView(.vertical) {
            TextField("Search ..", text: $trackSearchText)
                .focused(self.$focusTrackSearch)
                .onSubmit {
                    loadTracks(trackSearchText)
                }
                .padding(7)
                .padding(.horizontal, 25)
                .background(.gray.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !self.trackSearchText.isEmpty {
                            Button(action: {
                                self.trackSearchText = ""
                                self.focusTrackSearch = true
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 15)
            
            LazyVStack(alignment: .leading, spacing: 5) {
                ForEach(self.searchTracks, id: \.uri) { track in
                    Button {
                        self.syncing = false
                        self.retrieveTimer = nil
                        self.trackIsLoading = false
                        self.currentTrack.track = track
                        self.presentSearch = false
                    } label: {
                        TrackSelectableView(track: track)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    func loadTracks(_ searchText: String) {
        if !self.trackSearchText.isEmpty {
            self.searchTracks = []
            self.isLoadingTracks = true
            
            self.spotify.api.search(query: trackSearchText, categories: [.track])
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
                    receiveValue: { searchResult in
                        if let items = searchResult.tracks?.items {
                            self.searchTracks += items
                        } else {
                            print("Search was empty")
                            self.couldntLoadTracks = true
                        }
                        
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// button to create new playlist
    var newPlaylistButton: some View {
        Button {
            addPlaylist(searchText)
        } label: {
            VStack {
                Image(systemName: "plus.square")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 111, height: 111, alignment: .center)
                    .clipped()
                    .foregroundColor(Color.green)
                Text("'\(searchText)'")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 14))
                    .padding(5)
            }
            .background(Color.gray.opacity(0.3))
            .cornerRadius(5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// progress view if loading
    var progressView: some View {
        Group {
            if self.trackIsLoading {
                ProgressView()
            } else {
                EmptyView()
            }
        }
        .scaleEffect(0.7)
    }
    
    var syncButton: some View {
        Button {
            retrieveCurrentlyPlaying()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.body)
                .imageScale(.large)
                .foregroundColor(self.syncing ? .blue : .gray)
                .overlay(progressView, alignment: .center)
        }
    }
    
    /// button to skip to next song
    var skipButton: some View {
        Button(action: skipToNext) {
            Image(systemName: "forward.end.fill")
                .font(.body)
                .imageScale(.large)
                .foregroundColor(.green)
                .shadow(radius: 3)
        }
    }

    /// button to refresh playlists and tracks
    var refreshButton: some View {
        Button{
            retrievePlaylists()
            retrieveCurrentlyPlaying()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .imageScale(.medium)
        }
        .disabled(isLoadingPlaylists)
        .frame(width: 42)
        
    }
    
    /// calculate columns based on device width
    func numColumns(_ width: Double) -> Int {
        Int((width / (111 + 5)).rounded(.down))
    }
    
    /// filter playlists based on search
    func filterPlaylists() {
        if searchText.isEmpty {
            filteredPlaylists = playlists
        } else {
            filteredPlaylists = playlists.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    /// skip to next song
    func skipToNext() {
        spotify.api.skipToNext()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting user completion: \(completion)")
            }, receiveValue: { _ in
                retrieveCurrentlyPlaying()
            })
            .store(in: &cancellables)
    }
    
    /// create playlist 'name' , add currentTrack and add it to self.playlists
    func addPlaylist(_ name: String) {
        if let uri = spotify.currentUser?.uri {
            spotify.api.createPlaylist(for: uri,
                                          PlaylistDetails(name: name, isPublic: false, isCollaborative: nil, description: nil))
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { completion in
                    print("Getting user completion: \(completion)")
                }, receiveValue: { newPlaylist in
                    // add current track to new playlist
                    if let uri = self.currentTrack.track?.uri {
                        self.spotify.api.addToPlaylist(newPlaylist.uri, uris: [uri], position: nil)
                            .receive(on: RunLoop.main)
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                        case .finished:
                                            print("Added '\(self.currentTrack.track?.name)' to '\(newPlaylist.name)'")
                                        case .failure(let error):
                                            print("Adding to playlist failed with \(error)")
                                    }
                                },
                                receiveValue: { _ in }
                            ).store(in: &cancellables)
                    } else {
                        print("Current track \(self.currentTrack.track) has no uri")
                    }
                    
                    // add new playlist to view
                    spotify.api.currentUserPlaylists()
                        // Gets all pages of playlists.
                        .extendPagesConcurrently(spotify.api)
                        .receive(on: RunLoop.main)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { playlistsPage in
                                let playlists = playlistsPage.items
                                for playlist in playlists {
                                    if playlist.uri == newPlaylist.uri {
                                        self.playlists.insert(playlist, at: 0)
                                        self.filteredPlaylists.insert(playlist, at: 0)
                                    }
                                }
                            }
                        )
                        .store(in: &cancellables)
                })
                .store(in: &cancellables)
        }
        self.newPlaylistFieldIsFocused = false
        self.newPlaylistName = ""
    }
    
    /// get currently playing track
    func retrieveCurrentlyPlaying() {
        self.syncing = true
        self.trackIsLoading = true
        spotify.api.currentPlayback()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting context completion: \(completion)")
            }, receiveValue: { optionalContext in
                if self.trackIsLoading {
                    if let context = optionalContext {
                        switch context.item {
                        case let .some(.track(track)):
                            self.currentTrack.track = track
                            self.trackIsLoading = false
                            
                            // if playing, queue retrieve after finished
                            if context.isPlaying {
                                let timeRemaining = (track.durationMS ?? 0) - (context.progressMS ?? 0)
                                self.retrieveTimer = Timer.scheduledTimer(withTimeInterval: Double(timeRemaining) / 1000.0,
                                                                          repeats: false) { timer in
                                    retrieveCurrentlyPlaying()
                                }
                            }
                        default:
                            self.currentTrack.track = nil
                            self.trackIsLoading = false
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }

    /// get playlists for user
    func retrievePlaylists() {
        
        // Don't try to load any playlists if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        self.isLoadingPlaylists = true
        self.playlists = []
        self.filteredPlaylists = []
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
                    let editablePlaylists = playlistsPage.items.filter {
                        $0.isCollaborative || $0.owner?.uri == spotify.currentUser?.uri
                    }
                    self.playlists += editablePlaylists
                    self.filteredPlaylists += editablePlaylists
                }
            )
            .store(in: &cancellables)

    }
}
