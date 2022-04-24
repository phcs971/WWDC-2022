import Foundation
import SwiftUI

struct HomeButton: View {
    let color: Color
    let borderColor: Color
    let imageName: String
    let size: Double
    
    var body: some View {
        Image(imageName)
            .resizable()
            .renderingMode(.template)
            .frame(width: size / 1.6, height: size / 1.6, alignment: .center)
            .foregroundColor(color)
            .frame(width: size, height: size, alignment: .center)
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: size / 16)
            )
    }
}
