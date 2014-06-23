//
//  MSMenu.h
//  Space Cannon Challenge
//
//  Created by Miguel Serrano on 21/06/14.
//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface MSMenu : SKNode

@property (nonatomic, assign) int score;
@property (nonatomic, assign) int topScore;
@property (nonatomic, assign) BOOL touchable;
@property (nonatomic, assign) BOOL musicPlaying;

- (void)hide;
- (void)show;

@end
