//
//  MSMyScene.m
//  Space Cannon Challenge
//
//  Created by Miguel Serrano on 18/06/14.
//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import "MSMyScene.h"
#import "MSMenu.h"
#import "MSBall.h"
#import <AVFoundation/AVFoundation.h>

@implementation MSMyScene
{
    AVAudioPlayer *_audioPlayer;
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    NSMutableArray *_shieldPool;
    MSMenu *_menu;
    BOOL _didShoot;
    BOOL _gameOver;
    SKAction *_bounceSound;
    SKAction *_explosionSound;
    SKAction *_deepExplosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    SKAction *_shieldUpSound;
    SKAction *_multiUpSound;
    NSUserDefaults *_userDefaults;
    int _killCount;
}

static const CGFloat kMSBallSpeed       = 1000.0;
static const CGFloat kMSHaloSpeed       = 100.0;
static const CGFloat kMSHaloLowAngle    = 200.0 * M_PI / 180.0;
static const CGFloat kMSHaloHighAngle   = 340.0 * M_PI / 180.0;

static const uint32_t kMSHaloCategory       = 0x1 << 0;
static const uint32_t kMSBallCategory       = 0x1 << 1;
static const uint32_t kMSEdgeCategory       = 0x1 << 2;
static const uint32_t kMSShieldCategory     = 0x1 << 3;
static const uint32_t kMSLifeBarCategory    = 0x1 << 4;
static const uint32_t kMSShieldUpCategory   = 0x1 << 5;
static const uint32_t kMSMultiUpCategory    = 0x1 << 6;

static NSString *const kMSKeyTopScore = @"TopScore";

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        // Setup physicsWorld
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        
        // Add background
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.anchorPoint = CGPointZero;
        background.position = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        [self addChild:background];
        
        // Add side edges
        SKNode *leftEdge = [[SKNode alloc] init];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        leftEdge.physicsBody.categoryBitMask = kMSEdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *righEdge = [[SKNode alloc] init];
        righEdge.position = CGPointMake(self.size.width, 0.0);
        righEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        righEdge.physicsBody.categoryBitMask = kMSEdgeCategory;
        [self addChild:righEdge];
        
        // Add main layer
        _mainLayer = [[SKNode alloc] init];
        [self addChild:_mainLayer];
        
        // Add cannon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        [self addChild:_cannon];
        
        // Add cannon rotation
        SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                      [SKAction rotateByAngle:-M_PI duration:2]]];
        [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
        
        // Add ammo display
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        _ammoDisplay.position = CGPointMake(self.size.width * 0.5, 0.0);
        [self addChild:_ammoDisplay];
        
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1.0],
                                                       [SKAction runBlock:^{
            if (!self.multiMode) {
                self.ammo++;
            }
        }]]];
        [_ammoDisplay runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        // Set up shield pool
        _shieldPool = [[NSMutableArray alloc] init];
        for (int i = 0; i < 6; i++) {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(shield.size.width * 0.85 * i + 35, self.size.height * 0.2);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42.0, 9.0)];
            shield.physicsBody.categoryBitMask = kMSShieldCategory;
            shield.physicsBody.collisionBitMask = 0;
            shield.physicsBody.contactTestBitMask = 0;
            [_shieldPool addObject:shield];
        }
        
        // Add halo spawn
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
        
        // Add shield up spawn
        SKAction *spawnShieldUp = [SKAction sequence:@[[SKAction waitForDuration:15.0 withRange:4.0],
                                                       [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnShieldUp]];
        
        // Add pause button
        _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
        _pauseButton.position = CGPointMake(self.size.width - 30.0, 20.0);
        [self addChild:_pauseButton];
        
        // Add resume button
        _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
        _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_resumeButton];
        
        // Add score label
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 15.0;
        _scoreLabel.position = CGPointMake(15.0, 10.0);
        _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:_scoreLabel];
        
        // Add point multiplier label
        _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _pointLabel.fontSize = 15.0;
        _pointLabel.position = CGPointMake(15.0, 30.0);
        _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:_pointLabel];
        
        // Set up sounds
        _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
        _multiUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
        
        // Set up menu
        _menu = [[MSMenu alloc] init];
        _menu.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_menu];
        
        // Set initial values
        self.ammo = 5;
        self.score = 0;
        self.pointValue = 1;
        self.multiMode = NO;
        _killCount = 0;
        _pauseButton.hidden = YES;
        _resumeButton.hidden = YES;
        _scoreLabel.hidden = YES;
        _pointLabel.hidden = YES;
        [_menu show];
        _gameOver = YES;

        // Load top score
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _menu.topScore = [_userDefaults integerForKey:kMSKeyTopScore];
        
        // Load music
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
        
        NSError *error = nil;
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        
        if (!_audioPlayer) {
            NSLog(@"Error loading music: %@", error);
        } else {
            _audioPlayer.numberOfLoops = -1;
            _audioPlayer.volume = 0.8;
            [_audioPlayer play];
            _menu.musicPlaying = YES;
        }
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if (!_gameOver && !self.gamePaused) {
            if (![_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                _didShoot = YES;
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (_gameOver && _menu.touchable) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([n.name isEqualToString:@"playButton"]) {
                [self newGame];
            } else if ([n.name isEqualToString:@"musicButton"]) {
                _menu.musicPlaying = !_menu.musicPlaying;
                if (_menu.musicPlaying) {
                    [_audioPlayer play];
                } else {
                    [_audioPlayer stop];
                }
            }
        } else if (!_gameOver) {
            if (self.gamePaused) {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]]) {
                    self.gamePaused = NO;
                }
            } else {
                if ([_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]) {
                    self.gamePaused = YES;
                }
            }
        }
    }
}

- (void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

- (void)didSimulatePhysics {
    
    // Shoot
    if (_didShoot) {
        if (self.ammo > 0) {
            self.ammo--;
            [self shoot];
            if (self.multiMode) {
                for (int i = 1; i < 5; i++) {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                if (self.ammo == 0) {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        _didShoot = NO;
    }
    
    // Remove unused nodes
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position)) {
            self.pointValue = 1;
            [node removeFromParent];
        }
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }
    }];
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
    }];
    [_mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x - node.frame.size.width > self.size.width) {
            [node removeFromParent];
        }
    }];
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == kMSHaloCategory && secondBody.categoryBitMask == kMSBallCategory) {
        self.score += self.pointValue;
        _killCount++;
        if (_killCount % 10 == 0) {
            [self spawnMultiShotPowerUp];
        }
        [self addParticleEffectAtLocation:firstBody.node.position witType:@"HaloExplosion"];
        [self runAction:_explosionSound];
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.pointValue++;
        }
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            firstBody.node.name = nil;
            [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addParticleEffectAtLocation:node.position witType:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
    }
    if (firstBody.categoryBitMask == kMSHaloCategory && secondBody.categoryBitMask == kMSShieldCategory) {
        [self addParticleEffectAtLocation:firstBody.node.position witType:@"HaloExplosion"];
        [self runAction:_explosionSound];
        firstBody.categoryBitMask = 0;
        [_shieldPool addObject:secondBody.node];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                [_shieldPool addObject:node];
                [node removeFromParent];
            }];
        }
    }
    if (firstBody.categoryBitMask == kMSHaloCategory && secondBody.categoryBitMask == kMSLifeBarCategory) {
        [self addParticleEffectAtLocation:secondBody.node.position witType:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        firstBody.categoryBitMask = 0;
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    if (firstBody.categoryBitMask == kMSHaloCategory && secondBody.categoryBitMask == kMSEdgeCategory) {
        [self runAction:_zapSound];
    }
    if (firstBody.categoryBitMask == kMSBallCategory && secondBody.categoryBitMask == kMSEdgeCategory) {
        [self addParticleEffectAtLocation:firstBody.node.position witType:@"BounceExplosion"];
        [self runAction:_bounceSound];
        
        if ([firstBody.node isKindOfClass:[MSBall class]]) {
            ((MSBall*)firstBody.node).bounces++;
            if (((MSBall*)firstBody.node).bounces > 3) {
                self.pointValue = 1;
                [firstBody.node removeFromParent];
            }
        }
    }
    if (firstBody.categoryBitMask == kMSBallCategory && secondBody.categoryBitMask == kMSShieldUpCategory) {
        if (_shieldPool.count > 0) {
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            [self runAction:_shieldUpSound];
            [_mainLayer addChild:_shieldPool[randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if (firstBody.categoryBitMask == kMSBallCategory && secondBody.categoryBitMask == kMSMultiUpCategory) {
        self.multiMode = YES;
        self.ammo = 5;
        [self runAction:_multiUpSound];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

- (void)shoot {
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    
    // Create ball
    MSBall *ball = [MSBall spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx), _cannon.position.y + (_cannon.size.height * 0.5 * rotationVector.dy));
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * kMSBallSpeed, rotationVector.dy * kMSBallSpeed);
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.friction = 0.0;
    
    ball.physicsBody.categoryBitMask = kMSBallCategory;
    ball.physicsBody.collisionBitMask = kMSEdgeCategory;
    ball.physicsBody.contactTestBitMask = kMSEdgeCategory | kMSShieldUpCategory | kMSMultiUpCategory;
    
    [_mainLayer addChild:ball];
    
    // Add trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.targetNode = _mainLayer;
    [_mainLayer addChild:ballTrail];
    
    ball.trail = ballTrail;
    [ball updateTrail];
    
    // Add sound effect
    [self runAction:_laserSound];
}

- (void)spawnHalo {
    // Creat halo
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    CGVector direction = radiansToVector(randomInRange(kMSHaloLowAngle, kMSHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kMSHaloSpeed, direction.dy * kMSHaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    
    halo.physicsBody.categoryBitMask = kMSHaloCategory;
    halo.physicsBody.collisionBitMask = kMSEdgeCategory;
    halo.physicsBody.contactTestBitMask = kMSBallCategory | kMSShieldCategory | kMSLifeBarCategory | kMSEdgeCategory;
    
    // Add bomb halo
    int halosOnScreen = 0;
    for (SKNode *node in _mainLayer.children) {
        if ([node.name isEqualToString:@"halo"]) {
            halosOnScreen++;
        }
    }
    
    if (!_gameOver && halosOnScreen == 4) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKeyPath:@"Bomb"];
    }
    
    // Add multiplier halo
    else if (!_gameOver  && arc4random_uniform(6) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    
    // Increase spawn speed
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if (spawnHaloAction.speed < 1.5) {
        spawnHaloAction.speed += 0.01;
    }
         
    [_mainLayer addChild:halo];
}

- (void)spawnShieldPowerUp {
    if (_shieldPool.count > 0) {
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(150.0, self.size.height - 100));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42.0, 9.0)];
        shieldUp.physicsBody.velocity = CGVectorMake(-100.0, randomInRange(-40.0, 40.0));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0.0;
        shieldUp.physicsBody.angularDamping = 0.0;
        shieldUp.physicsBody.categoryBitMask = kMSShieldUpCategory;
        shieldUp.physicsBody.collisionBitMask = 0;
        shieldUp.physicsBody.contactTestBitMask = 0;
        [_mainLayer addChild:shieldUp];
    }
}

- (void)spawnMultiShotPowerUp {
    SKSpriteNode *multiUp = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiUp.name = @"multiUp";
    multiUp.position = CGPointMake(-multiUp.size.width, randomInRange(150.0, self.size.height - 100));
    multiUp.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12.0];
    multiUp.physicsBody.velocity = CGVectorMake(100.0, randomInRange(-40.0, 40.0));
    multiUp.physicsBody.angularVelocity = -M_PI;
    multiUp.physicsBody.linearDamping = 0.0;
    multiUp.physicsBody.angularDamping = 0.0;
    multiUp.physicsBody.categoryBitMask = kMSMultiUpCategory;
    multiUp.physicsBody.collisionBitMask = 0;
    multiUp.physicsBody.contactTestBitMask = 0;
    [_mainLayer addChild:multiUp];
}

- (void)addParticleEffectAtLocation:(CGPoint)position witType:(NSString *)name {
    NSString *particlePath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *particleEffect = [NSKeyedUnarchiver unarchiveObjectWithFile:particlePath];
    
    particleEffect.position = position;
    [_mainLayer addChild:particleEffect];
    
    SKAction *removeParticleEffect = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                          [SKAction removeFromParent]]];
    [particleEffect runAction:removeParticleEffect];
}

- (void)newGame {
    [_mainLayer removeAllChildren];
    
    while (_shieldPool.count > 0) {
        [_mainLayer addChild:_shieldPool[0]];
        [_shieldPool removeObjectAtIndex:0];
    }
    
    // Add life bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.name = @"lifeBar";
    lifeBar.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.18);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = kMSLifeBarCategory;
    lifeBar.physicsBody.collisionBitMask = 0;
    lifeBar.physicsBody.contactTestBitMask = 0;
    [_mainLayer addChild:lifeBar];
    
    // Set initial values
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    self.multiMode = NO;
    _killCount = 0;
    _pauseButton.hidden = NO;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    [_menu hide];
    _gameOver = NO;
    [self actionForKey:@"SpawnAction"].speed = 1.0;
}

- (void)gameOver {
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addParticleEffectAtLocation:node.position witType:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [_shieldPool addObject:node];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    _menu.score = self.score;
    if (self.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:kMSKeyTopScore];
        [_userDefaults synchronize];
    }
    
    self.multiMode = NO;
    _killCount = 0;
    _pauseButton.hidden = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _gameOver = YES;
    
    [self runAction:[SKAction waitForDuration:1.5] completion:^{
        [_menu show];
    }];
}

#pragma mark - Helper Methods

static inline CGVector radiansToVector(CGFloat radians) {
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high) {
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

#pragma mark - Setters

- (void)setAmmo:(int)ammo {
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%i", ammo]];
    }
}

- (void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %i", score];
}

- (void)setPointValue:(int)pointValue {
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Multiplier: x%i", pointValue];
}

-(void)setMultiMode:(BOOL)multiMode {
    _multiMode = multiMode;
    if (multiMode) {
        _cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    } else {
        _cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
}

- (void)setGamePaused:(BOOL)gamePaused {
    if (!_gameOver) {
        _gamePaused = gamePaused;
        _pauseButton.hidden = gamePaused;
        _resumeButton.hidden = !gamePaused;
        self.paused = gamePaused;
    }
}

@end
