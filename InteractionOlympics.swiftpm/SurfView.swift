//
//  File.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 11/04/22.
//

import Foundation
import SwiftUI
import SpriteKit
import CoreMotion


struct SurfView: View {
    static var showedTutorial = false
    
    @Environment(\.dismiss) var dismiss
    
    @State private var points = 0
    @State private var gameOver = false
    @State private var showTutorial = false {
        didSet { updatePause() }
    }
    
    func updatePause() {
        //        self.backgroundScene.isPaused = !showTutorial
        //        self._gameScene.isPaused = !showTutorial
        self._gameScene.pause(showTutorial)
    }
    
    @State var backgroundScene: WaterScene = {
        let scene = WaterScene()
        scene.size = UIScreen.size
        scene.scaleMode = .fill
        return scene
    }()
    
    @State var _gameScene: SurfScene = {
        let scene = SurfScene()
        scene.scaleMode = .fill
        return scene
    }()
    
    func gameScene(size: CGSize) -> SKScene {
        _gameScene.mainView = self
        _gameScene.size = size
        return _gameScene
    }
    
    func endGame() {
        gameOver = true
    }
    
    func addPoint() {
        points += 1
    }
    
    var body: some View {
        if gameOver {
            GameOverView(game: .Surf, points: points)
        } else {
            ZStack() {
                SpriteView(scene: backgroundScene)
                    .edgesIgnoringSafeArea(.all)
                GeometryReader { geometry in
                    SpriteView(scene: gameScene(size: geometry.size), options: [.allowsTransparency])
                        .expand()
                        .background(Color.clear)
                }
                .edgesIgnoringSafeArea(.bottom)
                VStack {
                    HStack(alignment: .center, spacing: 48) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(width: 48, height: 48)
                        }
                        Button {
                            showTutorial = true
                        } label: {
                            Image(systemName: "info.circle")
                                .resizable()
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(width: 48, height: 48)
                        }
                        Spacer()
                        Text("\(points)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                    }.padding([.horizontal, .top], 48)
                    Spacer()
                }
            }
            .expand()
            .showTutorial(for: .Surf, isShowing: $showTutorial, onTap: {
                updatePause()
            })
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .animation(.linear(duration: 0.5), value: showTutorial)
            .onAppear {
                gameOver = false
                points = 0
                self._gameScene.stop()
                
                self._gameScene = SurfScene()
                self._gameScene.scaleMode = .fill
                
                self.backgroundScene = WaterScene()
                self.backgroundScene.size = UIScreen.size
                self.backgroundScene.scaleMode = .fill
                
                self.showTutorial = !SurfView.showedTutorial
                SurfView.showedTutorial = true
                updatePause()
            }
        }
        
    }
}

class WaterScene: SKScene {
    private var waters: [SKSpriteNode] = {
        var array = [SKSpriteNode]()
        for index in (1...7) {
            
            let node = SKSpriteNode(texture: SKTexture(imageNamed: "Water\(index)"))
            node.size = CGSize(width: 5120, height: CGFloat(index == 1 ? 480 : 640))
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.position = CGPoint(x: -CGFloat.random(in: 500...1000 ), y: 160 + (index <= 2 ? 0.0 : UIScreen.height / Double(9-index)))
            node.zPosition = CGFloat(7-index)
            node.name = "\(index)"
            array.append(node)
            
        }
        return array
    }()
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.backgroundColor = .init(named: "BlueLightest")!
        
        let background = SKShapeNode(rect: CGRect(x: 0, y: 0, width: view.frame.width, height: 161))
        background.zPosition = 8
        background.position = CGPoint(x: 0, y: 0)
        background.strokeColor = .clear
        background.fillColor = .init(named: "WaterColor7")!
        
        self.addChild(background)
        
        for water in waters {
            self.addChild(water)
            let id = Int(water.name!)!
            let positive = id % 2 == 0
            let dx = CGFloat(positive ? 1 : -1) * CGFloat.random(in: 200...450)
            let move = SKAction.move(by: CGVector(dx: dx, dy: 0), duration: 3)
            water.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        move,
                        move.reversed()
                    ])
                )
            )
        }
    }
}

class SurfScene: SKScene, SKPhysicsContactDelegate {
    static let ballSize: CGFloat = 80.0
    static let ringSize: CGFloat = 64.0
    var movementMultiplier: CGFloat = 2.5
    
    var mainView: SurfView?
    
    var running = false
    
    private let boardNode: SKSpriteNode = {
        let texture = SKTexture(imageNamed: "Board")
        let node = SKSpriteNode(texture: texture)
        node.name = "board"
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return node
    }()
    
    private let ballNode: SKSpriteNode = {
        let node = SKSpriteNode(imageNamed: "Ball")
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.name = "ball"
        node.size = CGSize(width: SurfScene.ballSize, height: SurfScene.ballSize)
        let body = SKPhysicsBody(circleOfRadius: SurfScene.ballSize / 2)
        body.contactTestBitMask = 0b11
        body.affectedByGravity = true
        body.collisionBitMask = 0b00
        body.pinned = false
        body.allowsRotation = true
        node.physicsBody = body
        
        return node
    }()
    
    private let motionManager = CMMotionManager()
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = .zero
        self.view?.backgroundColor = .clear
        self.anchorPoint = CGPoint(x: 0.5, y: 0)
        self.backgroundColor = .clear
        
        let height: CGFloat = view.frame.size.height - SurfScene.ballSize * 1.5
        
        boardNode.size = CGSize(width: height * 570 / 1245, height: height)
        boardNode.position = CGPoint(x: 0, y: height/2)
        let texture = SKTexture(imageNamed: "Board")
        
        let body = SKPhysicsBody(texture: texture, size: boardNode.size)
        body.contactTestBitMask = 0b01
        body.collisionBitMask = 0b00
        body.affectedByGravity = false
        body.pinned = true
        body.allowsRotation = false
        boardNode.physicsBody = body
        self.addChild(boardNode)
        
        boardPath = UIBezierPath()
        boardPath.move(to: CGPoint(x: boardNode.frame.midX, y: boardNode.frame.maxY - boardNode.frame.height * 0.03))
        boardPath.addLine(to: CGPoint(x: boardNode.frame.maxX - boardNode.frame.width * 0.05, y: boardNode.frame.midY))
        boardPath.addLine(to: CGPoint(x: boardNode.frame.maxX - boardNode.frame.width * 0.15, y: boardNode.frame.minY))
        boardPath.addLine(to: CGPoint(x: boardNode.frame.minX + boardNode.frame.width * 0.15, y: boardNode.frame.minY))
        boardPath.addLine(to: CGPoint(x: boardNode.frame.minX + boardNode.frame.width * 0.05, y: boardNode.frame.midY))
        boardPath.close()
        
        ballNode.position = CGPoint(x: 0, y: height/2)
        self.addChild(ballNode)
        
        start()
        
        spawnRing()
    }
    
    func stop() {
        if (!running) { return }
        self.physicsWorld.gravity = .zero
        running = false
        motionManager.stopAccelerometerUpdates()
    }
    
    func start() {
        if (running) { return }
        running = true
        motionManager.accelerometerUpdateInterval = 1/30
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            if let data = data {
                self.onMotion(CGVector(
                    dx: data.acceleration.x * self.movementMultiplier,
                    dy: data.acceleration.y * self.movementMultiplier
                ))
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let c = contact.bodyA.contactTestBitMask & contact.bodyB.contactTestBitMask
        if (c & 0b01 == 0b01) {
            mainView?.endGame()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let c = contact.bodyA.contactTestBitMask & contact.bodyB.contactTestBitMask
        if (c & 0b10 == 0b10) {
            let ringBody = contact.bodyA.contactTestBitMask == 0b10 ? contact.bodyA : contact.bodyB
            if let ring = ringBody.node {
                ring.removeFromParent()
                mainView?.addPoint()
                spawnRing()
            }
        }
    }
    
    private var ringIndex = 0
    private var boardPath = UIBezierPath()
    private var _isPaused = false
//    pr
    
    func pause(_ value: Bool) {
        _isPaused = value
        self.isPaused = value
        self.scene?.isPaused = value
        self.view?.isPaused = value
//        if _isPaused {
//            self.physicsWorld.gravity = .zero
//        }
        
    }
    
    func spawnRing() {
        let ring = SKSpriteNode(imageNamed: "Ring\(ringIndex)")
        ring.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ring.name = "ring"
        ring.size = CGSize(width: SurfScene.ringSize, height: SurfScene.ringSize)
        let body = SKPhysicsBody(circleOfRadius: SurfScene.ringSize / 2)
        body.contactTestBitMask = 0b10
        body.affectedByGravity = false
        body.collisionBitMask = 0b00
        body.pinned = true
        body.allowsRotation = false
        ring.physicsBody = body
        
        var point = CGPoint.zero
        repeat {
            point = CGPoint(x: CGFloat.random(in: boardNode.frame.minX...boardNode.frame.maxX), y: CGFloat.random(in: (boardNode.frame.minY + SurfScene.ringSize)...boardNode.frame.maxY))
        } while !boardPath.contains(point) || distanceToBall(point) <= 2 * SurfScene.ballSize
        ring.position = point
        
        self.addChild(ring)
        
        ringIndex += 1
        if ringIndex == 4 { ringIndex = 0}
    }
    
    func distanceToBall(_ point: CGPoint) -> CGFloat {
        sqrt(pow(point.x - ballNode.frame.midX, 2) + pow(point.y - ballNode.frame.midY, 2))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (_isPaused != self.isPaused) {
            pause(_isPaused)
        }
        self.movementMultiplier += 0.005
    }
    
    func onMotion(_ vector: CGVector) {
//        if _isPaused {self.physicsWorld.gravity = .zero }
//        else {
#if targetEnvironment(simulator)
            return
#else
            self.physicsWorld.gravity = vector
#endif
//        }
    }
}
