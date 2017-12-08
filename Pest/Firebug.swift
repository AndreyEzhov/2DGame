//
//  Firebug.swift
//  Pest
//
//  Created by Andrey on 12/8/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit
class Firebug: Bug {
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    override init() {
        super.init()
        name = "Firebug"
        color = .red
        colorBlendFactor = 0.8
        physicsBody?.categoryBitMask = PhysicsCategory.Firebug
    }
}
