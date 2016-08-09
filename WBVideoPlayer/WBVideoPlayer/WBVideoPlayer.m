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
    NSMutableArray      *_audioFrames;
    
    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    
    BOOL                _isDecoding;
    
    UIImageView         *_imageView;
    WBVideoGLView       *_glView;
}

#pragma mark - LifeCycle

- (UIView *)view
{
    return _glView ? : _imageView;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _taskQueue  = dispatch_queue_create("DecodeQueue", DISPATCH_QUEUE_SERIAL);
        _videoFrames = [[NSMutableArray alloc] init];
        _audioFrames = [[NSMutableArray alloc] init];
        
        _minBufferedDuration = 2;
        _maxBufferedDuration = 8;
        
        // 音频激活
        [[WBAudioManager sharedAudioManager] activateAudioSession];

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
        // 初始化显示视图（glView or imageView)
        [self setupRenderView];
        
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
    
    // 视频
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
    
    // 音频
    if (_decoder.validAudio)
    {
        @synchronized(_audioFrames)
        {
            for (WBMediaFrame *frame in frames)
            {
                if (frame.type == kWBMediaFrameTypeAudio)
                {
                    [_audioFrames addObject:frame];
                    if (!_decoder.validVideo)
                    {
                        _bufferedDuration += frame.duration;
                    }
                }
                // TODO: ？
                else if (frame.type == kWBMediaFrameTypeArtwork)
                {
                    self.artworkFrame = (WBArtworkFrame *)frame;
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
     //[_decoder setupVideoFrameFormat:kWBVideoFrameFormatRGB];
    
    [self decodeFrame];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });
}

- (void)setupRenderView
{
    if (_decoder.validVideo)
    {
        _glView = [[WBVideoGLView alloc] initWithFrame:_frame decoder:_decoder];
    }
    
    if (!_glView)
    {
        [_decoder setupVideoFrameFormat:kWBVideoFrameFormatRGB];
        _imageView = [[UIImageView alloc] initWithFrame:_frame];
        _imageView.backgroundColor = [UIColor blackColor];
    }
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
            if (_glView)
            {
                [_glView render:frame];
            }
            else
            {
                _imageView.image = [_videoFrames[0] asImage];
            }
            
            // 进度
            _position = frame.position;
            
            [_videoFrames removeObjectAtIndex:0];
            //NSLog(@"bufferdDuration2:%lf", _bufferedDuration);
            
            // 检查结束
            if (_position >= self.duration)
            {
                if ([_delegate respondsToSelector:@selector(wbVideoPlayerCallbackWithEvent:)])
                {
                    _status = kWBVideoPlayerStatusPlayEnd;
                    [_delegate wbVideoPlayerCallbackWithEvent:kWBVideoPlayerEventPlayEnd];
                }
            }
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

- (void)freeBuffers
{
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    _bufferedDuration = 0;
}
- (void)seekToPosition:(CGFloat)position
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(_taskQueue, ^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf pause];
        
        [strongSelf freeBuffers];
        
        _decoder.position = position;
        _position = _decoder.position;
        
        [strongSelf resume];
    });
    
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self stop];
    _taskQueue = NULL;
}

@end
