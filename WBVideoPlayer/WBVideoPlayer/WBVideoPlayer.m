//
//  WBVideoPlayer.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/27.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBVideoPlayer.h"
#import "WBVideoDecoder.h"

@implementation WBVideoPlayer
{
    WBVideoDecoder *_decoder;
    NSString *_url;
    dispatch_queue_t _taskQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _taskQueue  = dispatch_queue_create("KxMovie", DISPATCH_QUEUE_SERIAL);

    }
    return self;
}

- (void)prepareToPlayWithUrl:(NSString *)url
{
    _url = url;
    if (!_decoder)
    {
        _decoder = [[WBVideoDecoder alloc] init];
    }
    
    NSError *error = [_decoder openVideo:_url];
    if (error)
    {
        if ([_delegate respondsToSelector:@selector(wbVideoPlayerDidError:)])
        {
            [_delegate wbVideoPlayerDidError:error];
        }
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(wbVideoPlayerCallbackWithEvent:)])
        {
            [_delegate wbVideoPlayerCallbackWithEvent:kWBVideoPlayerEventPrepared];
        }
    }
    
}

- (void)decodeFrame
{
    if (!_decoder || !(_decoder.validVideo || _decoder.validAudio))
    {
        return;
    }
    dispatch_async(_taskQueue, ^{
        const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;
        NSArray *frames = [_decoder decodeFrames:duration];
    });
}
                   
- (void)resume
{
    if (self.status == kWBVideoPlayerStatusPlaying)
    {
        return;
    }
    
    [self decodeFrame];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
}

- (void)tick
{
    
}

- (void)pause
{
    
}

- (void)stop
{
    
}

@end
