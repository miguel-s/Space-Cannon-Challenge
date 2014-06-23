//
//  MSBall.h
//  Space Cannon Challenge
//
//  Created by Miguel Serrano on 21/06/14.
//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface MSBall : SKSpriteNode

@property (weak, nonatomic) SKEmitterNode *trail;
@property (nonatomic, assign) int bounces;

- (void)updateTrail;

@end
