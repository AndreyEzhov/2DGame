//
//  Player.swift
//  Pest
//
//  Created by Andrey on 12/7/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit

class Player: SKSpriteNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("Use init()")
    }
    
    init() {
        let texture = SKTexture(imageNamed: "player_ft1")
        super.init(texture: texture, color: .white,
                   size: texture.size())
        name = "Player"
        zPosition = 50
    }
}
