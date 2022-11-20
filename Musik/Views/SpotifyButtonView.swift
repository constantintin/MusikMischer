//
//  SpotifyButtonView.swift
//  Musik
//
//  Created by Constantin Loew on 20.11.22.
//

import Foundation
import SwiftUI

struct SpotifyButtonView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            if let url = URL(string: "https://open.spotify.com") {
                openURL(url)
            }
        } label: {
            Image("spotify logo green")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 42, maxHeight: 42)
        }
        .buttonStyle(.plain)
    }
}
