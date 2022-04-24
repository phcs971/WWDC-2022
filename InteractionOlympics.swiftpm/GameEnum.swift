//
//  File.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 12/04/22.
//

import SwiftUI

enum GameEnum {
    case Surf
    case Soccer
    case Archery
    
    var color: Color {
        switch self {
        case .Surf:
            return Color("Green")
        case .Soccer:
            return Color("Blue")
        case .Archery:
            return Color("Red")
        }
    }
    
    var lightColor: Color {
        switch self {
        case .Surf:
            return Color("GreenLight")
        case .Soccer:
            return Color("BlueLight")
        case .Archery:
            return Color("RedLight")
        }
    }
    
    var imageName: String {
            switch self {
            case .Surf:
                return "Surfing"
            case .Soccer:
                return "Soccer"
            case .Archery:
                return "Archery"
            }
    }
    
    var tutorials: [Tutorial] {
        switch self {
        case .Surf:
            return [
                Tutorial(value: "Tilt your device\nto play"),
                Tutorial(image: true, value: "Tutorial1"),
                Tutorial(value: "Don't lose\nyour balance"),
                Tutorial(value: "Keep the ball\non the board"),
                Tutorial(value: "Grab the rings\nto get points")
            ]
        case .Soccer:
            return [
                Tutorial(value: "Place the iPad\nin front of you"),
                Tutorial(value: "Move your hands\nto play"),
                Tutorial(image: true, value: "Tutorial2"),
                Tutorial(value: "Defend your\ngoal"),
                Tutorial(value: "Don't let the\nball through")
            ]
        case .Archery:
            return [
                Tutorial(value: "Move your head\nand eyes to play"),
                Tutorial(image: true, value: "Tutorial3"),
                Tutorial(value: "Aim for the\n target"),
                Tutorial(value: "Blink to shoot")
            ]
        }
    }
}

struct Tutorial: Identifiable {
    let id = UUID()
    var image: Bool = false
    let value: String
}
