//
//  SoccerView.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 18/04/22.
//

import SwiftUI
import SceneKit
import SpriteKit
import Vision
import CoreImage
import AVFoundation
import ARKit

struct SoccerView: View {
    static var showedTutorial = false
    
    @Environment(\.dismiss) var dismiss
    
    @State private var points = 0
    @State private var gameOver = false
    @State private var showTutorial = false {
        didSet { updatePause() }
    }
    
    @StateObject private var gameScene = SoccerScene()
    
    
    func endGame() {
        gameOver = true
    }
    
    func addPoint() {
        points += 1
    }
    
    func updatePause() {
        self.gameScene.pause(showTutorial)
    }
    
    var body: some View {
        if gameOver {
            GameOverView(game: .Soccer, points: points)
        } else {
            ZStack() {
                SceneView(scene: gameScene.scene)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image("Goal").resizable()
                        .resizable()
                        .frame(height: UIScreen.height * 0.15)
                        .edgesIgnoringSafeArea(.all)
                    Spacer()
                }
                
                FrameView(image: gameScene.currentFrame)
                
                if gameScene.target != nil {
                    Image("Target")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .offset(x: gameScene.target!.x, y: gameScene.target!.y)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if gameScene.leftHand != nil {
                    Image("leftGlove")
                        .resizable()
                        .frame(width: 160, height: 160)
                        .offset(x: gameScene.leftHand!.x, y: gameScene.leftHand!.y)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if gameScene.rightHand != nil {
                    Image("rightGlove")
                        .resizable()
                        .frame(width: 160, height: 160)
                        .offset(x: gameScene.rightHand!.x, y: gameScene.rightHand!.y)
                        .edgesIgnoringSafeArea(.all)
                }
                
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
                
                if !gameScene.running {
                    Text("TAP TO START")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .edgesIgnoringSafeArea(.all)
                        .expand()
                        .background(Color.gray.opacity(0.5))
                        .onTapGesture {
                            gameScene.run()
                        }
                }
            }
            .expand()
            .background(Color.white)
            .showTutorial(for: .Soccer, isShowing: $showTutorial, onTap: {
                updatePause()
            })
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .animation(.linear(duration: 0.5), value: showTutorial)
            .onAppear {
                gameOver = false
                points = 0
                gameScene.mainView = self
                self.showTutorial = !SoccerView.showedTutorial
                SoccerView.showedTutorial = true
                gameScene.start()
            }
            .onDisappear {
                gameScene.stop()
            }
        }
    }
}

class SoccerScene: NSObject, ObservableObject {
    let scene = SCNScene(named: "SoccerScene.scn")!
    
    var mainView: SoccerView?
    
    var rootNode: SCNNode { scene.rootNode }
    
    var cameraNode: SCNNode { rootNode.childNode(withName: "camera", recursively: false)! }
    
    var screenNode: SCNNode!
    
    var targetNode: SCNNode?
    
    var proportion = 0.0
    
    var ball: SCNNode?
    
    @Published var target: CGPoint?
    @Published var hands = [CGPoint]()
    @Published var currentFrame: CGImage?
    
    @Published var running = false
    
    var requests = [VNRequest]()
    
    var configured = false
    
    var sessionRunning = false
    
    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    private let sessionQueue = DispatchQueue(label: "com.phcs.InteractionOlympics.Soccer.SessionQ")
    
    @Published var current: CVPixelBuffer?
    @Published var leftHand: CGPoint?
    var leftHandBuffer = [CGPoint]()
    @Published var rightHand: CGPoint?
    var rightHandBuffer = [CGPoint]()
    
    let videoOutputQueue = DispatchQueue(
        label: "com.phcs.InteractionOlympics.Soccer.VideoOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    let session = AVCaptureSession()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    func run() {
        running = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.spawnBall()
        }
    }
    
    func stop() {
        running = false
        self.session.stopRunning()
    }
    
    override init() {
        super.init()
        set(self, queue: videoOutputQueue)
        configure()
    }
    
    func configure() {
        checkPermissions()
        sessionQueue.async {
            self.configureSession()
            self.session.startRunning()
        }
        configVision()
    }
    
    func start() {
        
        for node in rootNode.childNodes where ["ball", "target"].contains(node.name) {
            node.removeFromParentNode()
        }
        
        time = 5.0
        
        scene.physicsWorld.contactDelegate = self
        
        screenNode = cameraNode.childNode(withName: "screen", recursively: false)!
        let geo: SCNPlane = screenNode.geometry as! SCNPlane
        geo.firstMaterial!.diffuse.contents = UIColor.clear
        geo.height = CGFloat(abs(2 * (screenNode.position.z))) * tan(cameraNode.camera!.fieldOfView / 2) * 0.741
        proportion = geo.height / UIScreen.height
        geo.width = proportion * UIScreen.width
        
        screenNode.physicsBody = .static()
        screenNode.physicsBody?.isAffectedByGravity = false
        screenNode.physicsBody?.categoryBitMask =    0b0100
        screenNode.physicsBody?.contactTestBitMask = 0b0001
        screenNode.physicsBody?.collisionBitMask =   0b0000
        
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.spawnBall() }
    }
    
    var time: Float = 5.0
    
    func spawnBall() {
        target = CGPoint(
            x: CGFloat.random(in: -0.3...0.3) * UIScreen.width,
            y: CGFloat.random(in: -0.25...0.4) * UIScreen.height
        )
        
        let geo = SCNSphere(radius: 0.03)
        geo.firstMaterial!.diffuse.contents = UIColor.clear
        targetNode = SCNNode(geometry: geo)
        targetNode?.name = "target"
        targetNode?.position = .init(
            target!.x * proportion,
            -target!.y * proportion - 0.015,
            0
        )
        screenNode.addChildNode(targetNode!)
        
        
        ball = SCNNode(geometry: SCNSphere(radius: 0.2))
        ball?.name = "ball"
        ball?.position = .init(.random(in: -1.0...1.0), 0.2, .random(in: -3.0...0.0))
        ball?.physicsBody = .dynamic()
        ball?.physicsBody?.categoryBitMask =    0b0001
        ball?.physicsBody?.collisionBitMask =   0b0000
        ball?.physicsBody?.contactTestBitMask = 0b1100
        ball?.physicsBody?.isAffectedByGravity = false
        
        rootNode.addChildNode(ball!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.applyForce()
        }
    }
    
    func applyForce() {
        if let body = ball?.physicsBody {
            
            let end = targetNode!.worldPosition
            let start = ball!.worldPosition
            //            let g: Float  = abs(scene.physicsWorld.gravity.y)
            let t: Float = time
            let h: Float = end.y - start.y
            let dx: Float = end.x - start.x
            let dz: Float = end.z - start.z
            //            let Vy: Float = (h + g * t * t / 2) / t
            //            let Vy: Float = sqrt(2 * g * h)
            let Vy: Float = h / t
            let Vx: Float = dx / t
            let Vz: Float = dz / t
            let V: SCNVector3 = .init(Vx, Vy, Vz)
            body.velocity = V
        }
        
    }
    
    func pause(_ value: Bool) {
        scene.isPaused = value
        rootNode.isPaused = value
    }
}

//MARK: SESSION
extension SoccerScene: AVCaptureVideoDataOutputSampleBufferDelegate {
    func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front)
        guard let camera = device else { return }
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(cameraInput) {
                session.addInput(cameraInput)
            } else { return }
        } catch { return }
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
        } else { return }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                self.sessionQueue.resume()
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            let context = CIContext()
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let imgRequestHandler = VNImageRequestHandler(cgImage: cgImage)
                try? imgRequestHandler.perform(requests)
                DispatchQueue.main.async {
                    self.current = buffer
                    self.currentFrame = cgImage
                }
            }
        }
    }
}

//MARK: VISION
extension SoccerScene {
    
    func configVision() {
        let request = VNDetectHumanBodyPoseRequest(completionHandler: poseHandler)
        self.requests = [ request ]
    }
    
    func poseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation], error == nil else { return print(error!) }
        
        observations.forEach { processPose($0) }
    }

    
    func processPose(_ observation: VNHumanBodyPoseObservation) {
        if let left = try? observation.recognizedPoint(.leftWrist) {
            if (left.confidence > 0) {
                let normalized = VNImagePointForNormalizedPoint(left.location, Int(UIScreen.width), Int(UIScreen.height))
                leftHandBuffer.append(.init(x: -(normalized.x - UIScreen.width / 2), y: -(normalized.y - UIScreen.height / 2)))
            }
        }
        if let right = try? observation.recognizedPoint(.rightWrist) {
            if (right.confidence > 0) {
                let normalized = VNImagePointForNormalizedPoint(right.location, Int(UIScreen.width), Int(UIScreen.height))
                rightHandBuffer.append(.init(x: -(normalized.x - UIScreen.width / 2), y: -(normalized.y - UIScreen.height / 2)))
            }
        }
        DispatchQueue.main.async {
            self.leftHandBuffer = self.leftHandBuffer.suffix(1)
            self.rightHandBuffer = self.rightHandBuffer.suffix(1)
            
            self.leftHand = self.leftHandBuffer.average
            self.rightHand = self.rightHandBuffer.average
        }
        
    }
}

extension SoccerScene: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodes: [String] = [contact.nodeA.name ?? "", contact.nodeB.name ?? ""].sorted()
        if nodes.contains("screen") && nodes.contains("ball") {
            ballCrossScreen()
        }
        
    }
    
    func gloveDistanceToBall() -> CGFloat? {
        if let target = target {
            let distances: [CGFloat] = [leftHand?.distance(to: target), rightHand?.distance(to: target)].compactMap { $0 }
            return distances.min()
        }
        return nil
    }
    
    func ballCrossScreen() {
        if let ball = ball {
            ball.name = "ball_used"
            let dist = gloveDistanceToBall() ?? .infinity
            print(dist)
            let covered = dist <= 120
            DispatchQueue.main.async {
                self.target = nil
                self.targetNode?.removeFromParentNode()
                self.targetNode = nil
                if covered {
                    ball.removeFromParentNode()
                    self.ball = nil
                    self.time /= 1.1
                    self.mainView?.addPoint()
                    self.spawnBall()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        ball.removeFromParentNode()
                        self.ball = nil
                        self.mainView?.endGame()
                    }
                }
            }
        }
    }
}
