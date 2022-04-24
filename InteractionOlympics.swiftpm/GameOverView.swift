//
//  File.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 12/04/22.
//

import SwiftUI

struct GameOverView: View {
    let game: GameEnum
    let points: Int
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            Text("GAME OVER")
                .font(.system(size: UIScreen.width / 10, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("Gold"))
            Spacer()
            Text("\(points) POINTS")
                .font(.system(size: UIScreen.width / 15, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("Gold"))
            Spacer()
            HomeButton(
                color: game.lightColor,
                borderColor: game.color,
                imageName: game.imageName,
                size: UIScreen.width / 4
            )
            .frame(height: UIScreen.width / 4)
            Spacer()
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("RETURN")
                    .font(.system(size: UIScreen.width / 20, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .expand()
        .background(
            Image("Background Cropped")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
    }
}
