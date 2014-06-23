//
//  MSBall.m
//  Space Cannon Challenge
//
//  Created by Miguel Serrano on 21/06/14.
//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import "MSBall.h"

@implementation MSBall

- (void)updateTrail {
    if (self.trail) {
        self.trail.position = self.position;
    }
}

- (void)removeFromParent {
    if (self.trail) {
        self.trail.particleBirthRate = 0.0;
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange],
                                                     [SKAction removeFromParent]]];
        [self runAction:removeTrail];
        [super removeFromParent];
    }
}

@end
