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
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @EnvironmentObject var spotify: Spotify
    @State private var currentUser: SpotifyUser? = nil
    
    @State private var alert: AlertItem? = nil
    @State private var playlists: [Playlist<PlaylistItemsReference>] = []

    @State private var cancellables: Set<AnyCancellable> = []

    @State private var isLoadingPlaylists = false
    @State private var couldntLoadPlaylists = false
    
    var body: some View {
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
                    LazyVGrid(columns: columns) {
                        ForEach(playlists, id: \.uri) { playlist in
                            NavigationLink {
                                PlaylistQueuerView(spotify: self.spotify, playlist: playlist)
                            } label: {
                                PlaylistSquareView(spotify: self.spotify, playlist: playlist)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(10)
                }
            }
            queuerNavigation
                .frame(maxHeight: 42)
                .padding(5)
            
        }
        .navigationTitle("Queuer")
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: retrievePlaylists)
    }
    
    var queuerNavigation: some View {
        let viewsAndTexts: [(view: AnyView, text: String)] = [
            (AnyView(RecoQueuerView(spotify: self.spotify)), "📻  Recos"),
            (AnyView(LikedQueuerView(spotify: self.spotify)), "❤️  Liked"),
            (AnyView(SearchQueuerView(spotify: self.spotify)), "🔍  Search"),
        ]
        
        return HStack(alignment: .center) {
            ForEach(viewsAndTexts, id: \.text) { vt in
                NavigationLink() {
                    vt.view
                } label: {
                    Text(vt.text)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(5)
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    var refreshButton: some View {
        Button(action: retrievePlaylists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoadingPlaylists)
        
    }
    
    func retrievePlaylists() {
        
        // Don't try to load any playlists if we're in preview mode.
        if ProcessInfo.processInfo.isPreviewing { return }
        
        
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
                    self.playlists += playlistsPage.items
                }
            )
            .store(in: &cancellables)

    }
}


