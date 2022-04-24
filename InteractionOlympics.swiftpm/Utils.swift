import Foundation
import SwiftUI

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
    
    func expand() -> some View {
        self.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

extension UIScreen{
    static var width: Double { UIScreen.main.bounds.size.width }
    static var height: Double { UIScreen.main.bounds.size.height }
    static var size: CGSize { UIScreen.main.bounds.size }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func sendAction() {
        let orientation = UIDevice.current.orientation
        if (orientation.isValidInterfaceOrientation) { action(orientation) }
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear { sendAction() }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in sendAction() }
    }
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

extension Collection where Element == CGPoint, Index == Int {
    var average: CGPoint? {
        guard !isEmpty else {
            return nil
        }

        let sum: CGPoint = reduce(CGPoint(x: 0, y: 0)) { first, second -> CGPoint in
            return first + second
        }

        return sum / CGFloat(count)
    }
}

extension Collection where Element == CGFloat, Index == Int {
    var average: CGFloat? {
        guard !isEmpty else {
            return nil
        }

        let sum: CGFloat = reduce(CGFloat(0)) { first, second -> CGFloat in
            return first + second
        }

        return sum / CGFloat(count)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(x-point.x, 2) + pow(y-point.y, 2))
    }
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
