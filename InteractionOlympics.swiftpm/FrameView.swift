//
//  File.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 20/04/22.
//

import SwiftUI

struct FrameView: View {
    var image: CGImage?
    
    var body: some View {
        if let image = image {
            VStack {
                Image(decorative: image, scale: 1.0, orientation: .upMirrored)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        height: UIScreen.height / 5,
                        alignment: .center)
                    .clipped()
                Spacer()
            }
        }
    }
}
