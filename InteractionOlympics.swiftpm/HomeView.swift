import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("INTERACTION\nOLYMPICS")
                .font(.system(size: UIScreen.width / 10, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("Gold"))
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Spacer()
//                NavigationLink(destination: SurfView()) {
                    HomeButton(
                        color: Color("GreenLight"),
                        borderColor: Color("Green"),
                        imageName: "Surfing",
                        size: UIScreen.width / 4
                    )
//                }
                Spacer()
//                NavigationLink(destination: SoccerView()) {
                    HomeButton(
                        color: Color("BlueLight"),
                        borderColor: Color("Blue"),
                        imageName: "Soccer",
                        size: UIScreen.width / 4
                    )
//                }
                Spacer()
//                NavigationLink(destination: ArcheryView()) {
                    HomeButton(
                        color: Color("RedLight"),
                        borderColor: Color("Red"),
                        imageName: "Archery",
                        size: UIScreen.width / 4
                    )
//                }
                Spacer()
                Spacer()
            }
            .frame(height: UIScreen.width / 4)
            Spacer()
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
