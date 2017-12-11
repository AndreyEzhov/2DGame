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

    var currentLevel: Int = 1
    
    var background: SKTileMapNode!
    var obstaclesTileMap: SKTileMapNode?
    var bugsprayTileMap: SKTileMapNode?
    var player = Player()
    var bugsNode = SKNode()
    
    var firebugCount:Int = 0

    var hud = HUD()

    var timeLimit: Int = 10

    var elapsedTime: Int = 0
    var startTime: Int?

    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
        }
    }

    func transitionToScene(level: Int) {
        // 1
        guard let newScene = SKScene(fileNamed: "Level\(level)") as? GameScene else {
            fatalError("Level: \(level) not found")
        }
        // 2
        newScene.currentLevel = level
        view!.presentScene(newScene,
                           transition: SKTransition.flipVertical(withDuration: 0.5))
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        background = childNode(withName: "background") as! SKTileMapNode
        setupWorldPhysics()
        obstaclesTileMap = childNode(withName: "obstacles") as? SKTileMapNode
        if let timeLimit = userData?.object(forKey: "timeLimit") as? Int {
            self.timeLimit = timeLimit
        }
        let savedGameState = aDecoder.decodeInteger(
            forKey: "Scene.gameState")
        if let gameState = GameState(rawValue: savedGameState),
            gameState == .pause {
            self.gameState = gameState
            firebugCount = aDecoder.decodeInteger(
                forKey: "Scene.firebugCount")
            elapsedTime = aDecoder.decodeInteger(
                forKey: "Scene.elapsedTime")
            currentLevel = aDecoder.decodeInteger(
                forKey: "Scene.currentLevel")
            // 2
            player = childNode(withName: "Player") as! Player
            hud = camera!.childNode(withName: "HUD") as! HUD
            bugsNode = childNode(withName: "Bugs")!
            bugsprayTileMap = childNode(withName: "Bugspray")
                as? SKTileMapNode
        }
        addObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMove(to view: SKView) {
        if gameState == .initial {
            addChild(player)
            setupWorldPhysics()
            createBugs()
            setupObstaclePhysics()
            if firebugCount > 0 {
                createBugspray(quantity: firebugCount + 10)
            }
            setupHUD()
            gameState = .start
        }
        setupCamera()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else { return }
        switch gameState {
        // 1
        case .start:
            gameState = .play
            isPaused = false
            startTime = nil
            elapsedTime = 0
        // 2
        case .play:
            player.move(target: touch.location(in: self))
        case .win:
            transitionToScene(level: currentLevel + 1)
        case .lose:
            transitionToScene(level: 1)
        case .reload:
            // 1
            if let touchedNode = atPoint(touch.location(in: self)) as? SKLabelNode {
                // 2
                if touchedNode.name == HUDMessages.yes {
                    isPaused = false
                    startTime = nil
                    gameState = .play
                    // 3
                } else if touchedNode.name == HUDMessages.no {
                    transitionToScene(level: 1)
                }
            }
        default:
            break
        } }

    func setupHUD() {
        camera?.addChild(hud)
        hud.addTimer(time: timeLimit)
    }

    func updateHUD(currentTime: TimeInterval) {
        if let startTime = startTime {
            elapsedTime = Int(currentTime) - startTime
        } else {
            startTime = Int(currentTime) - elapsedTime
        }
        hud.updateTimer(time: timeLimit - elapsedTime)
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
                bug.moveBug()
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
        case PhysicsCategory.Breakable:
            if let obstacleNode = other.node {
                advanceBreakableTile(locatedAt: obstacleNode)
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
        for row in 0..<obstaclesTileMap.numberOfRows {
            for column in 0..<obstaclesTileMap.numberOfColumns {
                // 2
                guard let tile = tile(in: obstaclesTileMap, at: (column, row)) else {
                    continue
                }
                guard tile.userData?.object(forKey: "obstacle") != nil else {
                    continue
                }
                
                // 3
                let node = SKNode()
                node.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
                node.physicsBody?.isDynamic = false
                node.physicsBody?.friction = 0
                node.physicsBody?.categoryBitMask = PhysicsCategory.Breakable
                node.position = obstaclesTileMap.centerOfTile(atColumn: column, row: row)
                obstaclesTileMap.addChild(node)
            }
        }
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
        if gameState != .play  {
            isPaused = true
            return
        }
        if !player.hasBugspray {
            updateBugspray()
        }
        updateHUD(currentTime: currentTime)
        checkEndGame()

    }

    func checkEndGame() {
        if bugsNode.children.count == 0 {
            player.physicsBody?.linearDamping = 1
            gameState = .win
        } else if timeLimit - elapsedTime <= 0 {
            player.physicsBody?.linearDamping = 1
            gameState = .lose
        }
    }
    
    func tileGroupForName(tileSet: SKTileSet, name: String) -> SKTileGroup? {
        let tileGroup = tileSet.tileGroups
            .filter { $0.name == name }.first
        return tileGroup
    }
    
    func advanceBreakableTile(locatedAt node: SKNode) {
        let nodePosition = node.position
        guard let obstaclesTileMap = obstaclesTileMap else { return }
        // 1
        let (column, row) = tileCoordinates(in: obstaclesTileMap,
                                            at: nodePosition)
        let obstacle = tile(in: obstaclesTileMap, at: (column, row))
        guard let nextTileGroupName = next(for: obstacle) else {
            return
        }
        // 4
        if let nextTileGroup = tileGroupForName(tileSet: obstaclesTileMap.tileSet, name: nextTileGroupName) {
            obstaclesTileMap.setTileGroup(nextTileGroup,
                                          forColumn: column, row: row)
        }
        if next(for: tile(in: obstaclesTileMap, at: (column, row))) == nil {
            node.removeFromParent()
        }
    }

    func next(for obstacle: SKTileDefinition?) -> String? {
        return obstacle?.userData?.object(forKey: "breakable") as? String
    }
}

extension GameScene {

    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground, object: nil)
    }

    @objc func applicationDidBecomeActive() {
        if gameState == .pause {
            gameState = .reload
        }
    }
    @objc func applicationWillResignActive() {
        isPaused = true
        if gameState != .lose {
            gameState = .pause
        }
    }
    @objc func applicationDidEnterBackground() {
        if gameState != .lose {
            saveGame() }
    }
}

extension GameScene {

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(firebugCount,
                      forKey: "Scene.firebugCount")
        aCoder.encode(elapsedTime,
                      forKey: "Scene.elapsedTime")
        aCoder.encode(gameState.rawValue,
                      forKey: "Scene.gameState")
        aCoder.encode(currentLevel,
                      forKey: "Scene.currentLevel")
        super.encode(with: aCoder)
    }

    func saveGame() {
        // 1
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return
        }

        let saveURL = directory.appendingPathComponent("SavedGames")
        // 3
        do {
            try fileManager.createDirectory(atPath: saveURL.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch let error as NSError {
            fatalError(
                "Failed to create directory: \(error.debugDescription)")
        }
        // 4
        let fileURL = saveURL.appendingPathComponent("saved-game")
        print("* Saving: \(fileURL.path)")
        // 5
        NSKeyedArchiver.archiveRootObject(self, toFile: fileURL.path)
    }

    class func loadGame() -> SKScene? {
        print("* loading game")
        var scene: SKScene?
        // 1
        let fileManager = FileManager.default
        guard let directory =
            fileManager.urls(for: .libraryDirectory,
                             in: .userDomainMask).first
            else { return nil }
        // 2
        let url = directory.appendingPathComponent(
            "SavedGames/saved-game")
        // 3
        if FileManager.default.fileExists(atPath: url.path) {
            scene = NSKeyedUnarchiver.unarchiveObject(
                withFile: url.path) as? GameScene
            _ = try? fileManager.removeItem(at: url)
        }
        return scene
    }
}
