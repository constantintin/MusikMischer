//
//  SharedTypes.swift
//  Musik
//
//  Created by Constantin Loew on 08.12.22.
//

import Foundation
import SpotifyWebAPI
import MusicKit

public struct MusikTrack: Hashable {
    public let title: String
    public let artists: [String]
    public let album_id: String
    public let id: String
    
    public init(spotifyTrack: SpotifyWebAPI.Track) {
        self.id = spotifyTrack.id ?? ""
        self.title = spotifyTrack.name
        self.album_id = spotifyTrack.album.id ?? ""
        if let artists = spotifyTrack.artists {
            self.artists = artists.map { $0.name }
        } else {
            self.artists = []
        }
    }
    
    public init(appleTrack: MusicKit.Track) {
        self.id = appleTrack.id.rawValue
        self.title = appleTrack.title
        if let artists = appleTrack.artists {
            self.artists = artists.map { $0.name }
        } else {
            self.artists = []
        }
    }
}
