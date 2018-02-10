//
// ARKlub
//
//  Created by eemi on 05/12/2017.
//  Copyright © 2017 eemi. All rights reserved.
//
//

import UIKit
import ARKit
class PetanqueController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        //self.registerGestureRecognizers()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // The function for create a "ground",  called when the didAdd of scenerenderer is activated
    // Take a PlaneAnchor in paramater, this plane anchor is the information about the position and orientation of a real-world flat surface detected in a world-tracking AR session.
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(CGFloat(planeAnchor.extent.z))))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians2, 0, 0)
        // We add a physic body for making the "ground" solid
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        return concreteNode
    }
    
    // Called when a new anchor is detected and is adding to the scene
    // This anchor provide information about the position and orientation for placing object in the scene
    // And here we want these information for create a new "ground" so we call the function createConcrete
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
        print("new flat surface detected, new ARPlaneAnchor added")
        
    }
    
    // Call when we update the current scene with new anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("updating floor's anchor...")
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
            
        }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    
    // Call when we update the current scene with new anchor
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
            
        }
        
    }
    
    // This function is call when a user press the button "balls", it's for adding new balls
    
    @IBAction func addBall(_ sender: Any) {
        
        // The node from which the scene’s contents are viewed for rendering
        guard let pointOfView = sceneView.pointOfView else {return}
        // These informations are made for launching the ball at the middle of the screen
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.10))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "petanqueTexture.png")
        sphere.position = currentPositionOfCamera
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: sphere, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        sphere.physicsBody = body
        
        // We create a vector for making a trajectory to the ball
        let forceVetcor:Float = 6
        sphere.physicsBody?.applyForce(SCNVector3(x: orientation.x * forceVetcor, y: orientation.y * forceVetcor, z: orientation.z * forceVetcor), asImpulse: true)
        
        self.sceneView.scene.rootNode.addChildNode(sphere)
    }
    
     // This function is call when a user press the button "cochonnet", it's for adding new cochonnets
    @IBAction func addCochonnet(_ sender: Any) {
        
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.05))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        sphere.position = currentPositionOfCamera
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: sphere, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        sphere.physicsBody = body
        
        let forceVetcor:Float = 5
        sphere.physicsBody?.applyForce(SCNVector3(x: orientation.x * forceVetcor, y: orientation.y * forceVetcor, z: orientation.z * forceVetcor), asImpulse: true)
        
        self.sceneView.scene.rootNode.addChildNode(sphere)
    }
    
    
}

// These functions are for the position of the ground
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}
extension Int {
    var degreesToRadians2: Double { return Double(self) * .pi/180}
}



