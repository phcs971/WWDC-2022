import SwiftUI

struct TutorialDialog: ViewModifier {
    var game: GameEnum
    @Binding var isShowing: Bool
    var onTap: (()->Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                VisualEffectView(effect: UIBlurEffect(style: .dark)).edgesIgnoringSafeArea(.all)
                ZStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 32) {
                        ForEach(game.tutorials) { tutorial in
                            if tutorial.image {
                                Image(tutorial.value)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                            } else {
                                Text(tutorial.value)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    VStack {
                        HStack {
                            Image(systemName: "xmark")
                                .resizable()
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                            Spacer()
                        }.padding([.horizontal, .top], 48)
                        Spacer()
                    }
                }
                .expand()
                .background(Color("Overlay"))
                .transition(.opacity)
                .onTapGesture {
                    isShowing = false
                    onTap?()
                }
            }
        }
    }
}

extension View {
    func showTutorial(for game: GameEnum, isShowing: Binding<Bool>, onTap: (()->Void)?) -> some View {
        self.modifier(TutorialDialog(game: game, isShowing: isShowing, onTap: onTap))
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
