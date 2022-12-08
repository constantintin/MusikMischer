//
//  TrackQueueableView.swift
//  Musik
//
//  Created by Constantin Loew on 08.11.22.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import SpotifyWebAPI
import SpotifyExampleContent

struct TrackQueueableView: View {
    
    @EnvironmentObject var spotify: Spotify
    @Environment(\.openURL) var openURL
    
    @State private var loadImageCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []
    
    @State private var bgOpacity = 0.1
    
    @State private var didRequestImage = false
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var alert: AlertItem? = nil
    
    let track: MusikTrack
    
    init(_ track: MusikTrack) {
        self.track = track
    }
    
    
    var body: some View {
        HStack() {
            image
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading) {
                Text(track.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                Text(trackArtists())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 15)
            Spacer()
        }
        .animation(Animation.easeInOut(duration: 0.3), value: self.bgOpacity)
        .background(
            LinearGradient(colors: [.clear, .green.opacity(bgOpacity)], startPoint: .leading, endPoint: .trailing)
        )
        .fixedSize(horizontal: false, vertical: true)
        .cornerRadius(5)
        .shadow(radius: 3)
        .padding([.trailing, .leading], 13)
        .contentShape(Rectangle())
        .onAppear {
            loadImage()
        }
        .onTapGesture{
            queueTrack()
            self.bgOpacity = 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.bgOpacity = 0.1
            }
        }
//        .onLongPressGesture(perform: {
//            if let artistUri = track.album?.uri {
//                if let url = URL(string: artistUri) {
//                    openURL(url)
//                }
//            }
//        })
    }
    
    /// add track to end of queue
    func queueTrack() {
        let uri = "spotify:track:\(self.track.id)"
        spotify.api.addToQueue(uri)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                print("Added \(self.track.title) to queue")
            },
                  receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /// The display name for the track. E.g., "Eclipse - Pink Floyd".
    func trackArtists() -> String {
        var display = ""
        for artist in track.artists {
            display += "\(artist), "
        }
        display = String(display.dropLast(2))
        return display
    }
    
    /// load album image
    func loadImage() {
        return
        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
//        if self.didRequestImage {
//            return
//        }
//        self.didRequestImage = true
//
//        guard let spotifyImage = self.track.album?.images?.last else {
//            return
//        }
//
//        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
//        // a request to load the image is made, the previous cancellable
//        // assigned to `loadImageCancellable` is deallocated, which cancels the
//        // publisher.
//        self.loadImageCancellable = spotifyImage.load()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { image in
//                    self.image = image
//                }
//            )
    }
}
