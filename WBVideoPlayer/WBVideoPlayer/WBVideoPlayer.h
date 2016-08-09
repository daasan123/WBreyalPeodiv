//
//  WBVideoPlayer.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/27.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBVideoDecoder.h"
#import "WBVideoGLView.h"
#import "WBAudioPlayer.h"

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
    kWBVideoPlayerStatusPlayEnd,
    kWBVideoPlayerStatusStopped,
};

@protocol WBVideoPlayerDelegate <NSObject>

- (void)wbVideoPlayerCallbackWithEvent:(WBVideoPlayerEvent)event;

- (void)wbVideoPlayerDidError:(NSError *)error;

@end

@interface WBVideoPlayer : NSObject
@property (nonatomic, assign) WBVideoPlayerStatus status;
@property (nonatomic, weak) id <WBVideoPlayerDelegate> delegate;
@property (nonatomic, strong) UIView *view;

@property (nonatomic, readonly, assign) CGFloat duration;
@property (nonatomic, readonly, assign) CGFloat position;
@property (nonatomic, assign) CGRect frame;
@property (readwrite, strong) WBArtworkFrame *artworkFrame;


- (void)prepareToPlayWithUrl:(NSString *)url;

- (void)resume;
- (void)pause;
- (void)stop;
- (void)seekToPosition:(CGFloat)position;
@end
