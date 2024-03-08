//
//  PlaylistOverView.swift
//  Musik
//
//  Created by Constantin Loew on 08.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

struct QueuerOverView: View {
    @EnvironmentObject var spotify: Spotify
    @Environment(\.openURL) var openURL
    
    @State private var alert: AlertItem? = nil
    @State private var playlists: [Playlist<PlaylistItemsReference>] = []
    @State private var filteredPlaylists: [Playlist<PlaylistItemsReference>] = []
    
    @State private var searchText = ""

    @State private var cancellables: Set<AnyCancellable> = []

    @State private var loadedPlaylists = false
    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
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
                                .onTapGesture {
                                    retrievePlaylists()
                                    loadedPlaylists = true
                                }
                        }
                    }
                    else {
                        ScrollView(.vertical) {
                            LazyVGrid(columns: [GridItem](repeating: GridItem(.flexible()), count: numColumns(geo.size.width))) {
                                ForEach(filteredPlaylists, id: \.uri) { playlist in
                                    NavigationLink {
                                        PlaylistQueuerView(spotify: self.spotify, playlist: playlist)
                                    } label: {
                                        PlaylistSquareView(spotify: self.spotify, playlist: playlist)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .searchable(text: $searchText, prompt: "Search By Playlist Name")
                            .onChange(of: searchText) {
                                filterPlaylists()
                            }
                            .onSubmit(of: .search) {
                                filterPlaylists()
                            }
                            .padding([.leading, .trailing], 10)
                        }
                    }
                    Divider()
                        .padding(.horizontal, 23)
                    queuerNavigation
                        .frame(maxHeight: 42)
                        .padding([.leading, .trailing, .bottom], 10)
                }
                .navigationBarTitle("Queue")
                .navigationBarItems(trailing:
                                        HStack {
                    SpotifyButtonView(uriString: "spotify:")
                    refreshButton
                })
                .alert(item: $alert) { alert in
                    Alert(title: alert.title, message: alert.message)
                }
                .onAppear {
                    if !loadedPlaylists {
                        retrievePlaylists()
                        loadedPlaylists = true
                    }
                }
                .onChange(of: self.spotify.isAuthorized, initial: false) {
                    retrievePlaylists()
                    loadedPlaylists = true
                }
            }
        }
    }
    
    var queuerNavigation: some View {
        let viewsAndTexts: [(view: AnyView, text: String)] = [
            (AnyView(RecoQueuerView(spotify: self.spotify)), "📻  Recos"),
            (AnyView(LikedQueuerView(spotify: self.spotify)), "❤️  Liked"),
            (AnyView(SearchQueuerView(spotify: self.spotify)), "🔍  Search"),
        ]
        
        return HStack(alignment: .center) {
            ForEach(viewsAndTexts, id: \.text) { view, text in
                NavigationLink() {
                    view
                } label: {
                    Text(text)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [.clear, .blue.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(5)
            .shadow(radius: 3)
            .buttonStyle(.plain)
        }
    }
    
    var refreshButton: some View {
        Button(action: retrievePlaylists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .imageScale(.medium)
        }
        .disabled(isLoadingPlaylists)
        .frame(width: 42)
        
    }
    
    /// calculate columns based on device width
    func numColumns(_ screenWidth: Double) -> Int {
        Int((screenWidth / (111 + 5)).rounded(.down))
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
    
    /// get playlists for user
    func retrievePlaylists() {
        guard self.spotify.isAuthorized else {
            return
        }

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
                    self.playlists += playlistsPage.items
                    self.filteredPlaylists += playlistsPage.items
                }
            )
            .store(in: &cancellables)
    }
}


