//
//  Bug.swift
//  Pest
//
//  Created by Andrey on 12/8/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit

enum BugSettings {
    static let bugDistance: CGFloat = 16
}

class Bug: SKSpriteNode, Animatable {

    var animations: [SKAction] = []

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use init()")
    }

    init() {
        let texture = SKTexture(pixelImageNamed: "bug_ft1")
        super.init(texture: texture, color: .white,
                   size: texture.size())
        name = "Bug"
        zPosition = 50

        physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
        physicsBody?.restitution = 0.5
        physicsBody?.linearDamping = 0.5
        physicsBody?.friction = 0
        physicsBody?.allowsRotation = false
        createAnimations(character: "bug")
        physicsBody?.categoryBitMask = PhysicsCategory.Bug
    }

    func move() {
        // 1
        let randomX = CGFloat(Int.random(min: -1, max: 1))
        let randomY = CGFloat(Int.random(min: -1, max: 1))
        let vector = CGVector(dx: randomX * BugSettings.bugDistance,
                              // 2
            dy: randomY * BugSettings.bugDistance)
        let moveBy = SKAction.move(by: vector, duration: 1)
        let moveAgain = SKAction.run(move)

        let direction = animationDirection(for: vector)
        // 2
        if direction == .left {
            xScale = abs(xScale)
        } else if direction == .right {
            xScale = -abs(xScale)
        }
        // 3
        run(animations[direction.rawValue], withKey: "animation")
        run(SKAction.sequence([moveBy, moveAgain]))
    }

    func die() {
        // 1
        removeAllActions()
        texture = SKTexture(pixelImageNamed: "bug_lt1")
        yScale = -1
        // 2
        physicsBody = nil
        // 3
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 3), SKAction.run(removeFromParent)]))
    }
}
