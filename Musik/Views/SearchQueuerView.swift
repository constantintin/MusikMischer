//
//  SearchQueuerView.swift
//  Musik
//
//  Created by Constantin Loew on 11.11.22.
//

import Foundation
import SwiftUI
import SpotifyWebAPI
import Combine

struct SearchQueuerView: View {
    var spotify: Spotify
    
    @State var searchText = ""
    
    @State private var tracks: [Track] = []
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    @FocusState private var focusSearch: Bool
    
    @State private var alert: AlertItem? = nil
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    var body: some View {
        ScrollView(.vertical) {
            TextField("Search ..", text: $searchText)
                .focused(self.$focusSearch)
                .onSubmit {
                    loadTracks(searchText)
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
                        
                        if !self.searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                                self.focusSearch = true
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
                ForEach(self.tracks, id: \.uri) { track in
                    TrackQueueableView(track: track)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusSearch = true
            }
        }
        .navigationTitle("Search")
        .toolbarTitleDisplayMode(.inlineLarge)
    }
    
    func loadTracks(_ searchText: String) {
        if !self.searchText.isEmpty {
            self.tracks = []
            self.isLoadingTracks = true
            
            self.spotify.api.search(query: searchText, categories: [.track])
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
                            self.tracks += items
                        } else {
                            print("Search was empty")
                            self.couldntLoadTracks = true
                        }
                        
                    }
                )
                .store(in: &cancellables)
        }
    }
}
