//
//  File.swift
//  Interaction Olympics
//
//  Created by Pedro Henrique Cordeiro Soares on 24/04/22.
//

import SwiftUI
import ARKit
import SceneKit

struct ArcheryView: View {
    static var showedTutorial = false
    
    @Environment(\.dismiss) var dismiss
    
    
    @State private var points = 0
    @State private var gameOver = false
    @State private var showTutorial = false {
        didSet { updatePause() }
    }
    
    @StateObject private var gameScene = ArcheryScene()
    
    func updatePause() {
        gameScene.pause(showTutorial)
    }
    
    func endGame() {
        gameOver = true
    }
    
    func addPoint() {
        points += 1
    }
    
    var body: some View {
        if gameOver {
            GameOverView(game: .Archery, points: points)
        } else {
            ZStack() {
                SceneView(scene: gameScene.scene)
                    .edgesIgnoringSafeArea(.all)
                    . onTapGesture {
                        gameScene.shoot()
                    }
                
                FrameView(image: gameScene.currentFrame)
                
                if gameScene.target != nil {
                    Image("WhiteTarget")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .offset(x: gameScene.target!.x, y: gameScene.target!.y)
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
            }
            .expand()
            .background(Color.white)
            .showTutorial(for: .Archery, isShowing: $showTutorial, onTap: {
                updatePause()
            })
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .animation(.linear(duration: 0.5), value: showTutorial)
            .onAppear {
                gameOver = false
                points = 0
                gameScene.mainView = self
                //                self.showTutorial = !ArcheryView.showedTutorial
                ArcheryView.showedTutorial = true
                gameScene.start()
                
            }
            .onDisappear {
                gameScene.stop()
            }
        }
    }
}


class ArcheryScene: NSObject, ObservableObject {
    let scene = SCNScene(named: "ArcheryScene.scn")!
    
    var mainView: ArcheryView?
    
    var rootNode: SCNNode { scene.rootNode }
    
    var cameraNode: SCNNode { rootNode.childNode(withName: "camera", recursively: false)! }
    
    var screenNode: SCNNode!
    var targetNode: SCNNode!
    var arrow: SCNNode?
    
    var radius: CGFloat = 1.0
    let side = sqrt(3) * 2 / 3
    
    @Published var currentFrame: CGImage?
    
    var requests = [VNRequest]()
    var faceBox: CGRect?
    
    func set(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    let videoOutputQueue = DispatchQueue(
        label: "com.phcs.InteractionOlympics.Archery.VideoOutputQ",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    private let sessionQueue = DispatchQueue(label: "com.phcs.InteractionOlympics.Archery.SessionQ")
    
    @Published var current: CVPixelBuffer?
    @Published var target: CGPoint?
    
    let session = AVCaptureSession()
    
    var isShooting = false
    var proportion: Double = 0.0
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
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
        radius = 1.0
        isShooting = false
        
        for node in rootNode.childNodes where ["arrow"].contains(node.name) { node.removeFromParentNode() }
        
        screenNode = cameraNode.childNode(withName: "screen", recursively: false)!
        let geo: SCNPlane = screenNode.geometry as! SCNPlane
        geo.firstMaterial!.diffuse.contents = UIColor.clear
        geo.height = CGFloat(abs(2 * (screenNode.position.z))) * tan(cameraNode.camera!.fieldOfView / 2) * 0.741
        proportion = geo.height / UIScreen.height
        geo.width = proportion * UIScreen.width
        
        screenNode.physicsBody = .static()
        screenNode.physicsBody?.isAffectedByGravity = false
        screenNode.physicsBody?.categoryBitMask =    0b0100
        screenNode.physicsBody?.contactTestBitMask = 0b1000
        screenNode.physicsBody?.collisionBitMask =   0b0000
        
        let geo2 = SCNSphere(radius: 0.03)
        geo2.firstMaterial!.diffuse.contents = UIColor.clear
        targetNode = SCNNode(geometry: geo2)
        targetNode?.name = "user_target"
        targetNode?.position = .init(0,0,0)
        screenNode.addChildNode(targetNode!)
        
        scene.physicsWorld.contactDelegate = self
        
        nextLevel()
    }
    
    func stop() {
        self.session.stopRunning()
        //        arView.sceneView.session.pause()
    }
    
    func pause(_ value: Bool) {
        scene.isPaused = value
        rootNode.isPaused = value
    }
    
    
    
    func nextLevel() {
        let target = rootNode.childNode(withName: "target", recursively: false)!
        let geo = target.geometry as! SCNCylinder
        geo.radius = radius
        
        if !target.hasActions {
            target.position = .init(x: 0, y: 1.5, z: 0)
            
            let sequence = [
                SCNAction.moveBy(x: 2, y: 0, z: 0, duration: radius),
                SCNAction.moveBy(x: -4, y: 0, z: 0, duration: radius * 2),
                SCNAction.moveBy(x: 2, y: 0, z: 0, duration: radius)
            ]
            let movement = SCNAction.sequence(sequence)
            let action = SCNAction.repeatForever(movement)
            target.runAction(action)
        }
    }
    
    func shoot() {
        if isShooting { return }
        isShooting = true
        let geo = SCNCylinder(radius: 0.01, height: 1)
        geo.firstMaterial!.diffuse.contents = UIColor.brown
        arrow = SCNNode(geometry: geo)
        arrow?.position = cameraNode.position
        arrow?.physicsBody = .dynamic()
        arrow?.name = "arrow"
        arrow?.eulerAngles = .init(x: .pi/2, y: 0, z: 0)
        arrow?.physicsBody?.categoryBitMask = 0b1000
        arrow?.physicsBody?.collisionBitMask = 0b0000
        arrow?.physicsBody?.contactTestBitMask = 0b0111
        arrow?.physicsBody?.isAffectedByGravity = false
        rootNode.addChildNode(arrow!)
        
        
        let end = targetNode.worldPosition
        let start = arrow!.worldPosition
        
        let t: Float = 1
        let dx: Float = end.x - start.x
        let dz: Float = end.z - start.z
        let dy: Float = end.y - start.y
        let Vy: Float = dy / t
        let Vx: Float = dx / t
        let Vz: Float = dz / t
        let V: SCNVector3 = .init(Vx, Vy, Vz)
        arrow?.physicsBody?.velocity = V
        
    }
    
    func miss() {
        isShooting = false
        mainView?.endGame()
    }
    
    func hit() {
        mainView?.addPoint()
        radius /= 1.05
        isShooting = false
        nextLevel()
    }
}

extension ArcheryScene: AVCaptureVideoDataOutputSampleBufferDelegate {
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

extension ArcheryScene {
    func configVision() {
        let faceRequest = VNDetectFaceRectanglesRequest(completionHandler: rectanglesHandler)
        let request = VNDetectFaceLandmarksRequest(completionHandler: faceHandler)
        self.requests = [
            faceRequest,
            request
        ]
    }
    
    func rectanglesHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation], error == nil else { return print(error!)}
        faceBox = observations.first?.boundingBox ?? faceBox
    }
    
    
    func faceHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation], error == nil else { return print(error!) }
        if let faceBox = faceBox {
            observations.forEach { processFace($0, box: faceBox) }
        }
    }
    
    func processFace(_ observation: VNFaceObservation, box: CGRect) {
        if observation.confidence < 0.2 { return }
        var points = [CGPoint]()
        let face = box.scaled(to: UIScreen.size)
        var blinks = [CGFloat]()
        if let left = observation.landmarks?.leftEye {
            
            let norms = left.normalizedPoints
            
            let p1 = norms[0].x
            let p2 = norms[1].y
            let p3 = norms[2].y
            let p4 = norms[3].x
            let p5 = norms[4].y
            let p6 = norms[5].y

            let eye_ar = (abs(p2-p6) + abs(p3-p5)) / (2 * abs(p1-p4))
            blinks.append(eye_ar)
            points.append(contentsOf: norms)
        }
        if let right = observation.landmarks?.rightEye {
            let norms = right.normalizedPoints

            let p1 = norms[0].x
            let p2 = norms[1].y
            let p3 = norms[2].y
            let p4 = norms[3].x
            let p5 = norms[4].y
            let p6 = norms[5].y

            let eye_ar = (abs(p2-p6) + abs(p3-p5)) / (2 * abs(p1-p4))
            blinks.append(eye_ar)
            points.append(contentsOf: norms)
        }
        let isBlinking = (blinks.average ?? 1) < 0.1

        var updateTargetTo: CGPoint? = nil
        if let p = points.average {
            let norm = CGPoint(
                x: p.x * face.width + face.origin.x,
                y: p.y * face.height + face.origin.y
            )
            updateTargetTo =  .init(
                x: -(norm.x - UIScreen.width / 2),
                y: -(norm.y - UIScreen.height / 2)
            )
        }
        DispatchQueue.main.async {
            self.target = updateTargetTo
            if let t = updateTargetTo {    
                self.targetNode.position = .init(
                    x: Float(t.x * self.proportion),
                    y: -Float(t.y * self.proportion) - 0.03,
                    z: 0
                )
            }
            
            if isBlinking { self.shoot() }
        }
    }
}


extension ArcheryScene: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if arrow != nil {
            print("CONTACT")
            print(contact.nodeA.name ?? "A")
            print(contact.nodeB.name ?? "B")
            print()
            let nodes: [SCNNode] = [contact.nodeA, contact.nodeB]
            let other = nodes.first { $0.name != "arrow" }
            self.arrow?.removeFromParentNode()
            self.arrow = nil
            DispatchQueue.main.async {
                if other?.name == "target" {
                    self.hit()
                } else {
                    self.miss()
                }
            }
        }
    }
}

