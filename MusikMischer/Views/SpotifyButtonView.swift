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
    
    let uriString: String
    
    var body: some View {
        Button {
            if let url = URL(string: uriString) {
                openURL(url)
            }
        } label: {
            Image("spotify logo green")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 33, maxHeight: 33)
        }
        .buttonStyle(.plain)
    }
}
