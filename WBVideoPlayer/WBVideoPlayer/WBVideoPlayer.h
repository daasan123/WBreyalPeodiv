//
//  WBVideoPlayer.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/27.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WBVideoPlayerEvent) {
    kWBVideoPlayerEventUnknwon = 0,
    kWBVideoPlayerEventPrepared,
    kWBVideoPlayerEventPlaying,
    kWBVideoPlayerEventPaused,
    kWBVideoPlayerEventSeekBegin,
    kWBVideoPlayerEventSeekEnd,
    kWBVideoPlayerEventBufferBegin,
    kWBVideoPlayerEventBufferEnd,
    kWBVideoPlayerEventPlayEnd,
    kWBVideoPlayerEventStopped,
};

typedef NS_ENUM(NSInteger, WBVideoPlayerStatus) {
    kWBVideoPlayerStatusUnknwon = 0,
    kWBVideoPlayerStatusPrepared,
    kWBVideoPlayerStatusPlaying,
    kWBVideoPlayerStatusPaused,
    kWBVideoPlayerStatusSeeking,
    kWBVideoPlayerStatusBufferring,
    kWBVideoPlayerStatusStopped,
};

@protocol WBVideoPlayerDelegate <NSObject>

- (void)wbVideoPlayerCallbackWithEvent:(WBVideoPlayerEvent)event;

- (void)wbVideoPlayerDidError:(NSError *)error;

@end

@interface WBVideoPlayer : NSObject
@property (nonatomic, assign) WBVideoPlayerStatus status;
@property (nonatomic, weak) id <WBVideoPlayerDelegate> delegate;

- (void)prepareToPlayWithUrl:(NSString *)url;

- (void)resume;
- (void)pause;
- (void)stop;

@end
