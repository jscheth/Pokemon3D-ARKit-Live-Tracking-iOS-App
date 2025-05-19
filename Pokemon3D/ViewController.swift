//
//  ViewController.swift
//  Pokemon3D
//
//  Created by Jonathan Cheth on 5/18/25.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true

        let scene = SCNScene()
        sceneView.scene = scene
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Pokemon-Cards", bundle: Bundle.main) else {
            print("❌ Failed to load image tracking resources.")
            return
        }

        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = trackingImages
        configuration.maximumNumberOfTrackedImages = 5 // Track up to 5 Pokémon cards at once
        
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let referenceImage = imageAnchor.referenceImage
        let imageName = referenceImage.name?.lowercased() ?? "unknown"
        print("Detected image: \(imageName)")
        
        // Visualize detected image with a semi-transparent plane
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        
        // Load the corresponding model
        if let modelNode = loadModel(named: imageName) {
            modelNode.position = SCNVector3Zero
            
            // Rotate model to face user (adjust if needed)
            modelNode.eulerAngles.y = Float.pi // 180 degrees to face camera
            
            // Optional: make model always face the camera dynamically on Y-axis
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            modelNode.constraints = [billboardConstraint]
            
            planeNode.addChildNode(modelNode)
        } else {
            print("⚠️ No model found for \(imageName)")
        }
    }


    // MARK: - Helper

    func loadModel(named name: String) -> SCNNode? {
        let path = "art.scnassets/\(name).scn"
        guard let scene = SCNScene(named: path) else {
            print("❌ Could not load model at \(path)")
            return nil
        }
        return scene.rootNode.childNodes.first
    }

}
