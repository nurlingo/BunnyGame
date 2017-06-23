//
//  GameScene.swift
//  bunny
//
//  Created by Nursultan Askarbekuly on 21/06/2017.
//  Copyright © 2017 Nursultan Askarbekuly. All rights reserved.
//

import SpriteKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollLayer: SKNode!
    var hero: SKSpriteNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    var restartButton: MSButtonNode!
    var scoreLabel: SKLabelNode!
    var gameState: GameSceneState = .active
    var points = 0
    var sinceTouch : CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 100
    var spawnTimer: CFTimeInterval = 0
    
    override func didMove(to view: SKView) {
        
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        scrollLayer = self.childNode(withName: "scrollLayer")
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        obstacleSource = obstacleLayer.childNode(withName: "obstacle")
        self.physicsWorld.contactDelegate = self
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        restartButton = self.childNode(withName: "restartButton") as! MSButtonNode
        restartButton.selectedHandler = {
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            scene?.scaleMode = .aspectFill
            skView?.presentScene(scene)
            self.points = 0
        }
        restartButton.state = .MSButtonNodeStateHidden
        scoreLabel.text = "\(points)"
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameState != .active {return}
        
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 200))
        hero.physicsBody?.applyAngularImpulse(1)
        sinceTouch = 0
        
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if gameState != .active {return}
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /* Apply falling rotation */
        if sinceTouch > 0.2 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -1, 3)
        
        /* Update last touch timer */
        sinceTouch += fixedDelta
        spawnTimer += fixedDelta
        /* Process world scrolling */
        scrollWorld()
        updateObstacles()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "goal" || nodeB.name == "goal" {
            points += 1
            scoreLabel.text = "\(points)"
            return
        }
        
        if gameState != .active {return}
        gameState = .gameOver
        hero.physicsBody?.allowsRotation = false
        hero.physicsBody?.angularVelocity = 0
        hero.removeAllActions()
        restartButton.state = .MSButtonNodeStateActive
        
        let heroDeath = SKAction.run({
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        hero.run(heroDeath)
        
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        for node in self.children {
            node.run(shakeScene)
        }
    }
    
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            if obstaclePosition.x <= -26 {
                obstacle.removeFromParent()
            }
        }
        
        if spawnTimer >= 1.5 {
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            let randomPosition = CGPoint(x: 352, y:  CGFloat.random(min: 234, max: 439))
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            //
            spawnTimer = 0
        }
        
    }
}
