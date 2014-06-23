//
//  MSMyScene.h
//  Space Cannon Challenge
//

//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface MSMyScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic, assign) int ammo;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) int pointValue;
@property (nonatomic, assign) BOOL multiMode;
@property (nonatomic, assign) BOOL gamePaused;

@end
