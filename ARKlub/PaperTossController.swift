//
//  ViewController.swift
//  ARKlub2
//
//  Created by eemi on 06/12/2017.
//  Copyright © 2017 eemi. All rights reserved.
// Homemade

import UIKit
import SceneKit
import ARKit

class PaperTossController: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var cameraStatusLabel: UILabel!
    @IBOutlet weak var launchButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    enum CollisionTypes: Int {
        case solid = 1
        case ball = 2
        
    }
    // Arrays of anchors, planes and planes
    var configuration : ARWorldTrackingConfiguration?
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    // keep track of number of anchor nodes that are added into the scene
    var planeNodesCount = 0
    let planeHeight: CGFloat = 0.01
    // set isPlaneSelected to true when user taps on the anchor plane to select.
    var isPlaneSelected = false
    var isSessionPaused = false
    
    // The trash where the user need to launch the ball
    var trashNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // debug scene to see feature points and world's origin
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        //addNewTrash()
        //loadNodeObject()
        //initializeSceneView()
        initializeMenuButtonStatus()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
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
    
    func startSession() {
        configuration = ARWorldTrackingConfiguration()
        //currenly only planeDetection available is horizontal.
        configuration!.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.run(configuration!, options: [ARSession.RunOptions.removeExistingAnchors,
                                                        ARSession.RunOptions.resetTracking])
        
    }
    
    func pauseSession() {
        sceneView.session.pause()
    }
    
    func continueSession() {
        sceneView.session.run(configuration!)
    }
    
    
    //Check if when the user touch the ground there is a plane (detection of surface from ARKit) and if it's the current plane ground
    //If not we select the plane in question
    // Else we add a trash to the selected location for launching the ball
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if !isPlaneSelected {
            selectExistingPlane(location: location)
        } else {
            addNodeAtLocation(location: location)
        }
    }
    
    func selectExistingPlane(location: CGPoint) {
        // Hit test result from intersecting with an existing plane anchor, taking into account the plane’s extent.
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                for var index in 0...anchors.count - 1 {
                    // remove all the nodes from the scene except for the one that is selected
                    if anchors[index].identifier != planeAnchor.identifier {
                        sceneView.node(for: anchors[index])?.removeFromParentNode()
                        sceneView.session.remove(anchor: anchors[index])
                    }
                    index += 1
                }
                // keep track of selected anchor only
                anchors = [planeAnchor]
                // set isPlaneSelected to true
                isPlaneSelected = true
                print("ok")
                //setPlaneTexture(node: sceneView.node(for: planeAnchor)!)
            }
        }
    }
    
    // checks if anchors are already created. If created, clones the node and adds it the anchor at the specified location
    func addNodeAtLocation(location: CGPoint) {
        guard anchors.count > 0 else {
            print("anchors are not created yet")
            return
        }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            let newLocation = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            let trashNode = Trash()
            
            let physicsShape = SCNPhysicsShape(node: trashNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
            let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
            
            trashNode.physicsBody = physicsBody
            
            
            trashNode.position = newLocation
            sceneView.scene.rootNode.addChildNode(trashNode)
        }
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // add the anchor node only if the plane is not already selected.
        guard !isPlaneSelected else {
            // we don't session to track the anchor for which we don't want to map node.
            sceneView.session.remove(anchor: anchor)
            return nil
        }
        
        
        var node:  SCNNode?
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            //            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: planeHeight, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
            planeGeometry.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
            // planeGeometry.firstMaterial?.specular.contents = UIColor.white
            
            
            let planeNode = SCNNode(geometry: planeGeometry)
            //let shape = SCNPhysicsShape(geometry: planeGeometry, options: nil)
            // planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            let staticBody = SCNPhysicsBody.static()
            planeNode.physicsBody = staticBody
            // planeNode.physicsBody?.categoryBitMask = CollisionTypes.solid.rawValue
            // planeNode.physicsBody?.collisionBitMask = CollisionTypes.ball.rawValue
            planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
            //            since SCNPlane is vertical, needs to be rotated -90 degress on X axis to make a plane
            //            planeNode.transform = SCNMatrix4MakeRotation(Float(-CGFloat.pi/2), 1, 0, 0)
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
            
        } else {
            // haven't encountered this scenario yet
            print("not plane anchor \(anchor)")
        }
        return node
    }
    
    // Called when a new node has been mapped to the given anchor
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeNodesCount += 1
        if node.childNodes.count > 0 && planeNodesCount % 2 == 0 {
            node.childNodes[0].geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        }
    }
    
    // Called when a node has been updated with data from the given anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // update the anchor node size only if the plane is not already selected.
        guard !isPlaneSelected else {
            return
        }
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
                    if let plane = planeNode.geometry as? SCNBox {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.length = CGFloat(planeAnchor.extent.z)
                        plane.height = planeHeight
                    }
                }
            }
        }
    }
    
    /* Called when a mapped node has been removed from the scene graph for the given anchor.
     remove the anchor from the scene view here
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
    }
    // MARK: Menu Buttons' Status and Actions
    func initializeMenuButtonStatus() {
        pauseButton.isHidden = false
        resetButton.isHidden = false
        launchButton.isHidden = false
        pauseButton.setTitle("Pause", for: .normal)
    }
    
    func initiateTracking() {
        // information to "select plane and tap on plane to place object" is visible for 10 seconds
        
    }
    
    @IBAction func pauseButtonTapped(_ sender: Any) {
        pauseButton.isHidden = false
        resetButton.isHidden = false
        
        // toggle button title to continue or pause
        let buttonTitle = isSessionPaused ? "Pause" : "Continue"
        self.pauseButton.setTitle(buttonTitle, for: .normal)
        
        if isSessionPaused {
            isSessionPaused = false
            continueSession()
        } else {
            isSessionPaused = true
            pauseSession()
        }
        
    }
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        pauseButton.isHidden = false
        resetButton.isHidden = false
        pauseButton.setTitle("Pause", for: .normal)
        reset()
    }
    
    @IBAction func launchButtonTapped(_ sender: Any) {
        
        guard let centerPoint = sceneView.pointOfView else {
            return
        }
        print("prout")
        
        let cameraTransform = centerPoint.transform
        let cameraLocation  = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
        let cameraOrientation  = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
        
        let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)
        
        let ball = SCNSphere(radius: 0.10)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "basketballSkin.png")
        ball.materials = [material]
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = cameraPosition
        
        let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        
        
        ballNode.physicsBody = physicsBody
        
        ballNode.physicsBody?.categoryBitMask = CollisionTypes.ball.rawValue
        ballNode.physicsBody?.collisionBitMask = CollisionTypes.solid.rawValue
        
        let forceVetcor:Float = 6
        ballNode.physicsBody?.applyForce(SCNVector3(x: cameraOrientation.x * forceVetcor, y: cameraOrientation.y * forceVetcor, z: cameraOrientation.z * forceVetcor), asImpulse: true)
        
        
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    
    // removes all the nodes, anchors and resets the isPlaneSelected to false
    func reset() {
        isPlaneSelected = false
        isSessionPaused = false
        planeNodesCount = 0
        if anchors.count > 0 {
            for index in 0...anchors.count - 1 {
                sceneView.node(for: anchors[index])?.removeFromParentNode()
            }
        }
        anchors.removeAll()
        for node in sceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
    }
    
    // MARK: session delegates
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            cameraStatusLabel.text = "Normal"
        case .notAvailable:
            cameraStatusLabel.text = "Not Available"
        case .limited(let reason):
            cameraStatusLabel.text = "Limited with reason: "
            switch reason {
            case .excessiveMotion:
                cameraStatusLabel.text = cameraStatusLabel.text! + "excessive camera movement"
            case .insufficientFeatures:
                cameraStatusLabel.text = cameraStatusLabel.text! + "insufficient features"
            case .initializing:
                cameraStatusLabel.text = cameraStatusLabel.text! + "camera initializing in progress"
            }
            
        }
    }
    
    //    func addNewTrash() {
    //        let tubeNode = Trash()
    //        tubeNode.position = SCNVector3(0, 0, -2)
    //        sceneView.scene.rootNode.addChildNode(tubeNode)
    //    }
    
    // It was for testing, not use in code
    func createRemiTrash() {
        guard let targetElemenScene = SCNScene(named: "art.scnassets/toilette.scn") else {
            return
        }
        
        guard let targetElemNode = targetElemenScene.rootNode.childNode(withName: "toilette", recursively: false) else {
            return
        }
        targetElemNode.position = SCNVector3(x: 0,y: 0.5,z: -5)
        
        let physicsShape = SCNPhysicsShape(node: targetElemNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        
        targetElemNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(targetElemNode)
        
    }
    
    // The target trash
    class Trash: SCNNode {
        
        override init() {
            super.init()
            let trash = SCNTube(innerRadius: 0.3, outerRadius: 0.3, height: 0.4)
            self.geometry = trash
            // let shape = SCNPhysicsShape(geometry: trash, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
            // self.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            self.physicsBody?.isAffectedByGravity = false
            
            
            // add texture
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.darkGray
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    
    
    
    
    class VirtualPlane: SCNNode {
        var anchor: ARPlaneAnchor!
        var planeGeometry: SCNPlane!
        
        /**
         * The init method will create a SCNPlane geometry and add a node generated from it.
         */
        init(anchor: ARPlaneAnchor) {
            super.init()
            
            // initialize anchor and geometry, set color for plane
            self.anchor = anchor
            self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
            let material = initializePlaneMaterial()
            self.planeGeometry!.materials = [material]
            
            // create the SceneKit plane node. As planes in SceneKit are vertical, we need to initialize the y coordinate to 0, use the z coordinate,
            // and rotate it 90º.
            let planeNode = SCNNode(geometry: self.planeGeometry)
            planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
            
            // update the material representation for this plane
            updatePlaneMaterialDimensions()
            
            // add this node to our hierarchy.
            self.addChildNode(planeNode)
        }
        
        /**
         * Creates and initializes the material for our plane, a semi-transparent gray area.
         */
        func initializePlaneMaterial() -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
            return material
        }
        
        /**
         * This method will update the plan when it changes.
         * Remember that we corrected the y and z coordinates on init, so we need to take that into account
         * when modifying the plane.
         */
        func updateWithNewAnchor(_ anchor: ARPlaneAnchor) {
            // first, we update the extent of the plan, because it might have changed
            self.planeGeometry.width = CGFloat(anchor.extent.x)
            self.planeGeometry.height = CGFloat(anchor.extent.z)
            
            // now we should update the position (remember the transform applied)
            self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
            
            // update the material representation for this plane
            updatePlaneMaterialDimensions()
        }
        
        /**
         * The material representation of the plane should be updated as the plane gets updated too.
         * This method does just that.
         */
        func updatePlaneMaterialDimensions() {
            // get material or recreate
            let material = self.planeGeometry.materials.first!
            
            // scale material to width and height of the updated plane
            let width = Float(self.planeGeometry.width)
            let height = Float(self.planeGeometry.height)
            material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
    }
    
    
    
}
