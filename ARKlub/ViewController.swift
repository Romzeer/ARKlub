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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        addTargetElem()
        
        registerGestureRecognizer()
    }
    
    func registerGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        // sceneview qui va etre accéder
        // acces au point de vue de la scene view, initialisé au milieu
        guard let sceneView = gestureRecognizer.view as? ARSCNView else {
            return
        }
        guard let centerPoint = sceneView.pointOfView else {
            return
        }
        
        // Trasnformer matricx
        //Check de l'orientation
        // emplacement de la caméra
        // Orientation et emplacement pour déterminer la position de la caméra, et c'est a ce poitn qu'on vont placer la balle
        
        let cameraTransform = centerPoint.transform
        let cameraLocation  = SCNVector3(x: cameraTransform.m41, y: cameraTransform.m42, z: cameraTransform.m43)
        let cameraOrientation  = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
        
        let cameraPosition = SCNVector3Make(cameraLocation.x + cameraOrientation.x, cameraLocation.y + cameraOrientation.y, cameraLocation.z + cameraOrientation.z)
        
        let ball = SCNSphere(radius: 0.15)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "basketballSkin.png")
        ball.materials = [material]
        
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = cameraPosition
        
        let physicsShape = SCNPhysicsShape(node: ballNode, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        
        ballNode.physicsBody = physicsBody
        
        let forceVetcor:Float = 6
        ballNode.physicsBody?.applyForce(SCNVector3(x: cameraOrientation.x * forceVetcor, y: cameraOrientation.y * forceVetcor, z: cameraOrientation.z * forceVetcor), asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    func addTargetElem() {
        guard let targetElemenScene = SCNScene(named: "art.scnassets/hoop.scn") else {
            return
        }
        
        guard let targetElemNode = targetElemenScene.rootNode.childNode(withName: "backboard", recursively: false) else {
            return
        }
        targetElemNode.position = SCNVector3(x: 0,y: 0.5,z: -3)
        
        let physicsShape = SCNPhysicsShape(node: targetElemNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        
        targetElemNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(targetElemNode)
        horizontalAction(node: targetElemNode)
    }
    
    func horizontalAction(node: SCNNode) {
        // let leftAction = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 0), duration: 3)
        // let RightAction = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 3)
        
        let quart1Action = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: -1), duration: 3)
        let quart2Action = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: -1), duration: 3)
        let quart3Action = SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 1), duration: 3)
        let quart4Action = SCNAction.move(by: SCNVector3(x: -1, y: 0, z: 1), duration: 3)
        
        // let actionSequence = SCNAction.sequence([leftAction, RightAction])
        
        let actionSequence = SCNAction.sequence([quart1Action, quart2Action, quart3Action, quart4Action])
        
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
}
