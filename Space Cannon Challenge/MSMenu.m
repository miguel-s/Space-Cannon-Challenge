//
//  MSMenu.m
//  Space Cannon Challenge
//
//  Created by Miguel Serrano on 21/06/14.
//  Copyright (c) 2014 Miguel Serrano. All rights reserved.
//

#import "MSMenu.h"

@implementation MSMenu
{
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
    SKSpriteNode *_title;
    SKSpriteNode *_scoreBoard;
    SKSpriteNode *_playButton;
    SKSpriteNode *_musicButton;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        _title.name = @"title";
        _title.position = CGPointMake(0.0, 140.0);
        [self addChild:_title];
        
        _scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        _scoreBoard.name = @"scoreBoard";
        _scoreBoard.position = CGPointMake(0.0, 70.0);
        [self addChild:_scoreBoard];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 30.0;
        _scoreLabel.position = CGPointMake(-52.0, -20.0);
        [_scoreBoard addChild:_scoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 30.0;
        _topScoreLabel.position = CGPointMake(48.0, -20.0);
        [_scoreBoard addChild:_topScoreLabel];
        
        _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        _playButton.name = @"playButton";
        _playButton.position = CGPointMake(0.0, 0.0);
        [self addChild:_playButton];
        
        _musicButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        _musicButton.name = @"musicButton";
        _musicButton.position = CGPointMake(90.0, 0.0);
        [self addChild:_musicButton];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;
    }
    
    return self;
}

- (void)hide {
    self.touchable = NO;
    
    // Animate menu
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}

- (void)show {
    self.hidden = NO;
    self.touchable = NO;
    
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.5];
    
    // Animate title
    _title.position = CGPointMake(0.0, 280.0);
    _title.alpha = 0.0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140.0 duration:0.5],
                                               fadeIn]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [_title runAction:animateTitle];
    
    // Animate score board
    _scoreBoard.xScale = 4.0;
    _scoreBoard.yScale = 4.0;
    _scoreBoard.alpha = 0.0;
    SKAction *animateScoreBoard = [SKAction group:@[[SKAction scaleTo:1.0 duration:0.5],
                                                    fadeIn]];
    animateScoreBoard.timingMode = SKActionTimingEaseOut;
    [_scoreBoard runAction:animateScoreBoard];
    
    // Animate play button
    _playButton.alpha = 0.0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:1.0];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [_playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
    
    // Animate music button
    _musicButton.alpha = 0.0;
    [_musicButton runAction:animatePlayButton];
}

#pragma mark - Setters

- (void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

- (void)setTopScore:(int)topScore {
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

- (void)setMusicPlaying:(BOOL)musicPlaying {
    _musicPlaying = musicPlaying;
    
    if (musicPlaying) {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    } else {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
    }
}

@end
