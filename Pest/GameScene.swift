//
//  GameScene.swift
//  Pest
//
//  Created by Andrey on 12/7/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var background: SKTileMapNode!
    let player = Player()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        background = childNode(withName: "background") as! SKTileMapNode
    }
    
    override func didMove(to view: SKView) {
        addChild(player)
    }
}
