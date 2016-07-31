//
//  WBVideoPlayer.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/27.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBVideoPlayer.h"

@implementation WBVideoPlayer
{
    WBVideoDecoder      *_decoder;
    NSString            *_url;
    dispatch_queue_t    _taskQueue;
    NSMutableArray      *_videoFrames;
    
    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    
    BOOL                _isDecoding;
}

#pragma mark - LifeCycle
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _taskQueue  = dispatch_queue_create("DecodeQueue", DISPATCH_QUEUE_SERIAL);
        _videoFrames = [[NSMutableArray alloc] init];
        
        _minBufferedDuration = 2;
        _maxBufferedDuration = 8;

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
    if (_isDecoding)
        return;
    
    _isDecoding = YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_taskQueue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;
        BOOL hasMore = YES;
        while (hasMore)
        {
            hasMore = NO;
            @autoreleasepool
            {
                if (_decoder && (_decoder.validVideo || _decoder.validAudio))
                {
                    NSArray *frames = [_decoder decodeFrames:duration];
                    hasMore = [strongSelf addFrames:frames];
                }
            }
            _isDecoding = NO;
        }
    });
}

- (BOOL)addFrames:(NSArray *)frames
{
    if (frames.count <= 0)
    {
        return NO;
    }
    
    if (_decoder.validVideo)
    {
        @synchronized(_videoFrames)
        {
            for (WBVideoFrame *frame in frames)
            {
                if (frame.type == kWBMediaFrameTypeVideo)
                {
                    [_videoFrames addObject:frame];
                    _bufferedDuration += frame.duration;
                    //NSLog(@"bufferdDuration1:%lf", _bufferedDuration);

                }
            }
        }
    }
    
    return (_status == kWBVideoPlayerStatusPlaying) && _bufferedDuration < _maxBufferedDuration;
}

- (void)resume
{
    if (self.status == kWBVideoPlayerStatusPlaying)
    {
        return;
    }
     _status = kWBVideoPlayerStatusPlaying;
    
    // test
     [_decoder setupVideoFrameFormat:kWBVideoFrameFormatRGB];
    
    [self decodeFrame];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
}

- (void)renderFrame
{
    WBVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0)
        {
            frame = _videoFrames[0];
            _bufferedDuration -= frame.duration;
            
            // TODO: test
           
            UIImage *image = [_videoFrames[0] asImage];
            self.view.image = image;
            
            
            // 进度
            _position = frame.position;
            
            [_videoFrames removeObjectAtIndex:0];
            //NSLog(@"bufferdDuration2:%lf", _bufferedDuration);
        }
    }
}

- (void)tick
{
    if (_status != kWBVideoPlayerStatusPlaying)
    {
        return;
    }
    
    // 显示
    [self renderFrame];
    
    // 解码
    [self decodeFrame];
    
    // 循环
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1/50.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
}

- (CGFloat)duration
{
    return _decoder.duration;
}

- (void)pause
{
     _status = kWBVideoPlayerStatusPaused;
}

- (void)stop
{
    _status = kWBVideoPlayerStatusStopped;
    //[_decoder close];
}

- (void)seekToPosition:(CGFloat)position
{
    _decoder.position = position;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self stop];
    _taskQueue = NULL;
}

@end
