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
    
    @State private var alert: AlertItem? = nil
    
    init(spotify: Spotify) {
        self.spotify = spotify
    }
    
    var body: some View {
        ScrollView(.vertical) {
            ZStack {
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.3))
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search ..", text: $searchText)
                        .onSubmit {
                            loadTracks(searchText)
                        }
                }
                .padding(.leading, 13)
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding()
            
            LazyVStack(alignment: .leading, spacing: 5) {
                ForEach(self.tracks, id: \.uri) { track in
                    TrackQueueableView(track: track)
                }
            }
        }
        .navigationBarTitle("Search")
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
