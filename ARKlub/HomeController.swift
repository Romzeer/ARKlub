//
//  Homecontroller.swift
//  ARKlub
//
//  Created by eemi on 05/12/2017.
//  Copyright © 2017 eemi. All rights reserved.
//

import UIKit
import AVFoundation

//The main controller where we display the games
class HomeController: UIViewController {
    
    @IBOutlet weak var TosserBtn: UIButton!
    @IBOutlet weak var BasketBtn: UIButton!
    @IBOutlet weak var petanque: UIButton!
    @IBOutlet weak var PlayObjetsBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        TosserBtn.setImage(UIImage(named: "art.scnassets/LogoPaperToss.png")?.withRenderingMode(.alwaysOriginal), for: .normal)
        BasketBtn.setImage(UIImage(named: "art.scnassets/LogoBasket.png")?.withRenderingMode(.alwaysOriginal), for: .normal)
        PlayObjetsBtn.setImage(UIImage(named: "art.scnassets/LogoArchi3D.png")?.withRenderingMode(.alwaysOriginal), for: .normal)
        petanque.setImage(UIImage(named: "art.scnassets/LogoPétanque.png")?.withRenderingMode(.alwaysOriginal), for: .normal)

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func print(_ sender: UIButton) {
        Swift.print("TestZer")
    }
    
}
