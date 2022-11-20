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
    @State private var bgColor: Color = .gray
    
    @State private var didRequestImage = false
    @State private var image = Image(.spotifyAlbumPlaceholder)

    @State private var alert: AlertItem? = nil
    
    
    let track: Track
    
    var body: some View {
        HStack() {
            image
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 42, height: 42)
            VStack(alignment: .leading) {
                Text(track.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Text(trackArtists())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 15)
            Spacer()
        }
        .animation(Animation.easeInOut(duration: 0.2), value: self.bgOpacity)
        .animation(Animation.easeInOut(duration: 0.2), value: self.bgColor)
        .background(bgColor.opacity(self.bgOpacity))
        .fixedSize(horizontal: false, vertical: true)
        .cornerRadius(13)
        .padding([.trailing, .leading], 13)
        .contentShape(Rectangle())
        .onAppear {
            loadImage()
        }
        .onTapGesture {
            self.bgColor = .green
            self.bgOpacity = 0.7
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.bgOpacity = 0.1
                self.bgColor = .gray
            }
            queueTrack()
        }
        .onLongPressGesture(perform: {
            self.bgColor = .blue
            self.bgOpacity = 0.7
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.bgOpacity = 0.1
                self.bgColor = .gray
            }
            if let link = track.externalURLs?["spotify"] {
                UIPasteboard.general.setValue(link.absoluteString,
                            forPasteboardType: UTType.plainText.identifier)
            }
        })
    }
    
    /// add track to end of queue
    func queueTrack() {
        if let uri = self.track.uri {
            spotify.api.addToQueue(uri)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                print("Getting context completion: \(completion)")
            }, receiveValue: { context in
                print("Got context: \(context)")
            })
            .store(in: &cancellables)
        } else {
            print("\(self.track) has no uri?")
        }
    }
    
    /// The display name for the track. E.g., "Eclipse - Pink Floyd".
    func trackArtists() -> String {
        var display = ""
        if let artists = track.artists {
            for artist in artists {
                display += "\(artist.name), "
            }
            display = String(display.dropLast(2))
        }
        return display
    }
    
    /// load album image
    func loadImage() {
        // Return early if the image has already been requested. We can't just
        // check if `self.image == nil` because the image might have already
        // been requested, but not loaded yet.
        if self.didRequestImage {
            // print("already requested image for '\(self.track.name)'")
            return
        }
        self.didRequestImage = true
        
        guard let spotifyImage = self.track.album?.images?.largest else {
            // print("no image found for '\(self.track.name)'")
            return
        }

        // print("loading image for '\(self.track.name)'")
        
        // Note that a `Set<AnyCancellable>` is NOT being used so that each time
        // a request to load the image is made, the previous cancellable
        // assigned to `loadImageCancellable` is deallocated, which cancels the
        // publisher.
        self.loadImageCancellable = spotifyImage.load()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { image in
                    // print("received image for '\(self.track.name)'")
                    self.image = image
                }
            )
    }
}
