//
//  GameScene.swift
//  Pest
//
//  Created by Andrey on 12/7/17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var background: SKTileMapNode!
    var obstaclesTileMap: SKTileMapNode?
    var bugsprayTileMap: SKTileMapNode?
    let player = Player()
    var bugsNode = SKNode()

    var firebugCount:Int = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        background = childNode(withName: "background") as! SKTileMapNode
        setupWorldPhysics()
        obstaclesTileMap = childNode(withName: "obstacles") as? SKTileMapNode
    }
    
    override func didMove(to view: SKView) {
        addChild(player)
        let bug = Bug()
        bug.position = CGPoint(x: 60.0, y: 0.0)
        addChild(bug)
        setupCamera()
        createBugs()
        setupObstaclePhysics()
        if firebugCount > 0 {
            createBugspray(quantity: firebugCount + 10)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else { return }
        player.move(target: touch.location(in: self))
    }

    func setupCamera() {
        guard let camera = camera, let view = view else { return }
        let zeroDistance = SKRange(constantValue: 0)
        let playerConstraint = SKConstraint.distance(zeroDistance,
                                                     // 1
            to: player)
        let xInset = min(view.bounds.width/2 * camera.xScale,
                         background.frame.width/2)
        let yInset = min(view.bounds.height/2 * camera.yScale,
                         background.frame.height/2)
        // 2
        let constraintRect = background.frame.insetBy(dx: xInset,
                                                      // 3
            dy: yInset)
        let xRange = SKRange(lowerLimit: constraintRect.minX,
                             upperLimit: constraintRect.maxX)
        let yRange = SKRange(lowerLimit: constraintRect.minY,
                             upperLimit: constraintRect.maxY)
        let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        edgeConstraint.referenceNode = background
        // 4
        camera.constraints = [playerConstraint, edgeConstraint]
    }

    func setupWorldPhysics() {
        background.physicsBody = SKPhysicsBody(edgeLoopFrom: background.frame)
        background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
        physicsWorld.contactDelegate = self
    }

    func tile(in tileMap: SKTileMapNode, at coordinates: TileCoordinates) -> SKTileDefinition? {
        return tileMap.tileDefinition(atColumn: coordinates.column, row: coordinates.row)
    }

    func createBugs() {
        guard let bugsMap = childNode(withName: "bugs") as? SKTileMapNode else { return }
        // 1
        for row in 0..<bugsMap.numberOfRows {
            for column in 0..<bugsMap.numberOfColumns {
                // 2
                guard let tile = tile(in: bugsMap, at: (column, row))
                    else { continue }
                // 3
                let bug: Bug
                if tile.userData?.object(forKey: "firebug") != nil {
                    bug = Firebug()
                    firebugCount += 1
                } else {
                    bug = Bug()
                }
                bug.position = bugsMap.centerOfTile(atColumn: column, row: row)
                bugsNode.addChild(bug)
                bug.move()
            }
        }
        // 4
        bugsNode.name = "Bugs"
        addChild(bugsNode)
        // 5
        bugsMap.removeFromParent()
    }

    func remove(bug: Bug) {
        bug.removeFromParent()
        background.addChild(bug)
        bug.die()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
        case PhysicsCategory.Bug:
            if let bug = other.node as? Bug {
                remove(bug: bug)
            }
        case PhysicsCategory.Firebug:
            if player.hasBugspray {
                if let firebug = other.node as? Firebug {
                    remove(bug: firebug)
                    player.hasBugspray = false
                }
            }
        default:
            break
        }

        if let physicsBody = player.physicsBody {
            if physicsBody.velocity.length() > 0 {
                player.checkDirection()
            }
        }
    }

    func setupObstaclePhysics() {
        guard let obstaclesTileMap = obstaclesTileMap else { return }
        // 1
        var physicsBodies = [SKPhysicsBody]()
        // 2
        for row in 0..<obstaclesTileMap.numberOfRows {
            for column in 0..<obstaclesTileMap.numberOfColumns {
                guard let tile = tile(in: obstaclesTileMap, at: (column, row))
                    else { continue }
                // 3

                let center = obstaclesTileMap
                    .centerOfTile(atColumn: column, row: row)
                let body = SKPhysicsBody(rectangleOf: tile.size,center: center)
                physicsBodies.append(body)
            } }
        // 4
        obstaclesTileMap.physicsBody =
            SKPhysicsBody(bodies: physicsBodies)
        obstaclesTileMap.physicsBody?.isDynamic = false
        obstaclesTileMap.physicsBody?.friction = 0
    }

    func createBugspray(quantity: Int) {
        // 1
        let tile = SKTileDefinition(texture: SKTexture(pixelImageNamed: "bugspray"))
        // 2
        let tilerule = SKTileGroupRule(adjacency:
            SKTileAdjacencyMask.adjacencyAll, tileDefinitions: [tile])
        // 3
        let tilegroup = SKTileGroup(rules: [tilerule])
        // 4
        let tileSet = SKTileSet(tileGroups: [tilegroup])
        let columns = background.numberOfColumns
        let rows = background.numberOfRows
        bugsprayTileMap = SKTileMapNode(tileSet: tileSet,
                                        // 6
            columns: columns,
            rows: rows,
            tileSize: tile.size)
        for _ in 1...quantity {
            let column = Int.random(min: 0, max: columns-1)
            let row = Int.random(min: 0, max: rows-1)
            bugsprayTileMap?.setTileGroup(tilegroup,
                                          forColumn: column, row: row)
        }
        // 7
        bugsprayTileMap?.name = "Bugspray"
        addChild(bugsprayTileMap!)
    }

    func tileCoordinates(in tileMap: SKTileMapNode,
                         at position: CGPoint) -> TileCoordinates {
        let column = tileMap.tileColumnIndex(fromPosition: position)
        let row = tileMap.tileRowIndex(fromPosition: position)
        return (column, row)
    }

    func updateBugspray() {
        guard let bugsprayTileMap = bugsprayTileMap else { return }
        let (column, row) = tileCoordinates(in: bugsprayTileMap,
                                            at: player.position)
        if tile(in: bugsprayTileMap, at: (column, row)) != nil {
            bugsprayTileMap.setTileGroup(nil, forColumn: column, row: row)
            player.hasBugspray = true
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if !player.hasBugspray {
            updateBugspray()
        }
    }
}
