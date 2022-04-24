import SwiftUI

@main
struct MyApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

struct AppView: View {
    @State var landscape = false
    var body: some View {
        NavigationView {
            Text("OI")
//            HomeView()
//            SurfView()
//            SoccerView()
//            ArcheryView()
        }
        .navigationViewStyle(.stack)
    }
}

struct RotateView: View {
    var body: some View {
        Text("Please rotate\nthe iPad")
            .font(.system(size: UIScreen.height / 10, weight: .black, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundColor(Color("Gold"))
            .expand()
            .background(
                Image("Background Cropped")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            )
    }
}

//https://developer.apple.com/forums/thread/131006
