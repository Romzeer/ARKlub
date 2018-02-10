//
//  ViewController.swift
//  ARKlub
//
//  Created by eemi on 04/12/2017.
//  Copyright © 2017 eemi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class BasketController: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var startBtn: UIButton!
    
    var currentNode:SCNNode!
    var currentBallNode:SCNNode!
    
    var configuration : ARWorldTrackingConfiguration?
    
    struct CollisionCategory: OptionSet {
        let rawValue:  Int
        
        static let balls  = CollisionCategory(rawValue: 1 << 1) // 00...01
        static let blocks = CollisionCategory(rawValue: 1 << 0) // 00..10
    }
    
    class Block: SCNNode {
        override init() {
            super.init()
            let box = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0)
            self.geometry = box
            let shape = SCNPhysicsShape(geometry: box, options: nil)
            self.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            self.physicsBody?.isAffectedByGravity = false
            
            
            // add texture
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "text.png")
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeSceneView()
        configureLighting()
        registerGestureRecognizer()
        addNewBlock()
        
    }
    
    func initializeSceneView() {
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create new scene and attach the scene to the sceneView
        sceneView.scene = SCNScene()
        
        sceneView.autoenablesDefaultLighting = true
        
        // Add the SCNDebugOptions options
        // showConstraints, showLightExtents are SCNDebugOptions
        // showFeaturePoints and showWorldOrigin are ARSCNDebugOptions
       // sceneView.debugOptions  = [SCNDebugOptions.showConstraints, SCNDebugOptions.showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        //shows fps rate
        sceneView.showsStatistics = true
        
        sceneView.automaticallyUpdatesLighting = true
    }

    func registerGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
    }
    
    
   
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func floatBetween(_ first: Float,  and second: Float) -> Float { // random float between upper and lower bound (inclusive)
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        // sceneview qui va etre accéder
        // acces au point de vue de la scene view, initialisé au milieu
    
        
        addBallElement(gestureRecognizer: gestureRecognizer)
    
    }
    
    
    
    // The hoop of basketball
    func addTargetElem() {
        guard let targetElemenScene = SCNScene(named: "art.scnassets/hoop.scn") else {
            return
        }

        guard let targetElemNode = targetElemenScene.rootNode.childNode(withName: "backboard", recursively: false) else {
            return
        }
        //
        targetElemNode.position = SCNVector3(x: 0,y: 0.5,z: -4)
        
        //We make a physic shape with these option for that the ball can enter in the ring of the hoop
        let physicsShape = SCNPhysicsShape(node: targetElemNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)

        targetElemNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(targetElemNode)

        currentNode = targetElemNode
    }
    
 
    //Just is a little block for decoration
    func addFootElem() {
        guard let targetElemenScene = SCNScene(named: "art.scnassets/slime.scn") else {
            return
        }
        
        guard let targetElemNode = targetElemenScene.rootNode.childNode(withName: "Armature", recursively: false) else {
            return
        }
        
        
        targetElemNode.position = SCNVector3(x: -0.5,y: 0.5,z: -1)
        
        //let physicsShape = SCNPhysicsShape(node: targetElemNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let physicsBody = SCNPhysicsBody.static()
        
        targetElemNode.physicsBody = physicsBody
        targetElemNode.physicsBody?.isAffectedByGravity = false
        
       
        sceneView.scene.rootNode.addChildNode(targetElemNode)
        
    }
    
    // The basket ball
    func addBallElement(gestureRecognizer: UIGestureRecognizer) {
        
        guard let sceneView = gestureRecognizer.view as? ARSCNView else {
            return
        }
        guard let centerPoint = sceneView.pointOfView else {
            return
        }
        
        // We want the ball start at the center of the screen
        //We play with the matrix of the camera scene
        let cameraTransform = centerPoint.transform
        let cameraLocation  = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
        let cameraOrientation  = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
        
        let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)
        //We create a ball and apply it a basketball texture
        let ball = SCNSphere(radius: 0.10)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "basketballSkin.png")
        ball.materials = [material]
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = cameraPosition
        
        let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        
        ballNode.physicsBody = physicsBody
        
        //We apply a force vector, same that PaperTossController
        let forceVetcor:Float = 6
        ballNode.physicsBody?.applyForce(SCNVector3(x: cameraOrientation.x * forceVetcor, y: cameraOrientation.y * forceVetcor, z: cameraOrientation.z * forceVetcor), asImpulse: true)
      
        
        
        sceneView.scene.rootNode.addChildNode(ballNode)
        currentBallNode = ballNode
    }
    
    // An obstacle for increase difficulty
    func addNewBlock() {
        let cubeNode = Block()
        
        let posX = floatBetween(-0.5, and: 0.5)
        let posY = floatBetween(-0.5, and: 0.5  )
        cubeNode.position = SCNVector3(posX, posY, -1) // SceneKit/AR coordinates are in meters
        sceneView.scene.rootNode.addChildNode(cubeNode)
    }
    
    
    
    func horizontalAction(node: SCNNode) {
        let leftAction = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 0), duration: 3)
        let RightAction = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 3)
        
       // let quart1Action = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: -1), duration: 3)
       // let quart2Action = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: -1), duration: 3)
       // let quart3Action = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 1), duration: 3)
       // let quart4Action = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 1), duration: 3)
        
         let actionSequence = SCNAction.sequence([leftAction, RightAction])
        
        //let actionSequence = SCNAction.sequence([quart1Action, quart2Action, quart3Action, quart4Action])
        
        node.runAction(SCNAction.repeatForever(actionSequence))
    }
    
    func roundAction(node: SCNNode) {
        let upLeft = SCNAction.move(by: SCNVector3(x: 1, y: 1, z: 0), duration: 2)
        let downRight = SCNAction.move(by: SCNVector3(x: 1, y: -1, z: 0), duration: 2)
        let downLeft = SCNAction.move(by: SCNVector3(x: -1, y: -1, z: 0), duration: 2)
        let upRight = SCNAction.move(by: SCNVector3(x: -1, y: 1, z: 0), duration: 2)
        
        let actionSequence = SCNAction.sequence([upLeft, downRight, downLeft, upRight])
        
        node.runAction(SCNAction.repeatForever(actionSequence))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    @IBAction func startGame(_ sender: Any) {
        addTargetElem()
        addFootElem()
        //addBallElement()
        startBtn.isHidden = true
        
    }
    
    @IBAction func startHorizontalAction(_ sender: Any) {
        
        horizontalAction(node: currentNode)
    }
    
    @IBAction func stopAction(_ sender: Any) {
        currentNode.removeAllActions()
    }
    
    @IBAction func startRoundAction(_ sender: Any) {
        roundAction(node: currentNode)
    }
    

    
    
}
