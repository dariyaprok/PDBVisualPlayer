//
//  Player.h
//  Player
//
//  Created by Dasha on 4/21/17.
//  Copyright © 2017 Basquare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Player : NSObject

@property (strong, nonatomic) NSURL *path;
@property (nonatomic) NSInteger startFromTime; //in miliseconds
@property (nonatomic) NSInteger delayTime;
@property (nonatomic) float pitch;
@property (nonatomic) float tempo;
@property (nonatomic) NSInteger finishAtTime;
@property (nonatomic) BOOL isLoop;
@property (nonatomic) NSInteger currentDuration;

- (void)play;
- (void)stop;
- (void)prepareInputFile;

@end
