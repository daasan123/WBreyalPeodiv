//
//  WBAudioPlayer.h
//  WBVideoPlayer
//
//  Created by wubing on 16/8/9.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import "WBVPLog.h"
#import "WBAudioManager.h"

typedef void (^WBAudioPlayerOutputBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@protocol WBAudioPlayerProtocol <NSObject>

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readonly) Float32            outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;

@property (readwrite, copy) WBAudioPlayerOutputBlock outputBlock;

- (BOOL) activateAudioSession;
- (void) deactivateAudioSession;
- (BOOL) play;
- (void) pause;

@end

@interface WBAudioPlayer : WBAudioManager <WBAudioPlayerProtocol>

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readwrite) Float32           outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;


@property (readwrite, copy) WBAudioPlayerOutputBlock outputBlock;
@property (readwrite) BOOL playAfterSessionEndInterruption;



- (BOOL)checkAudioRoute;
- (BOOL)setupAudio;
- (BOOL)checkSessionProperties;
- (BOOL)renderFrames:(UInt32) numFrames ioData:(AudioBufferList *)ioData;

@end
