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
    
    BOOL                _isBufferring;
    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    
    NSData              *_currentAudioFrame;
    NSUInteger          _currentAudioFramePos;
    
    
    BOOL                _isDecoding;
    
    UIImageView         *_imageView;
    WBVideoGLView       *_glView;
    
#ifdef DEBUG
    NSUInteger          _debugAudioStatus;
    NSDate              *_debugAudioStatusTS;
#endif
    
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
    
    [self enableAudio:YES];
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
    
    if (_isBufferring && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {
        _isBufferring = NO;
    }
    
    const NSUInteger leftFrames =
    (_decoder.validVideo ? _videoFrames.count : 0) +
    (_decoder.validAudio ? _audioFrames.count : 0);
    
    if (0 == leftFrames)
    {
        if (_decoder.isEOF)
        {
            [self pause];
            return;
        }
        
        if (_minBufferedDuration > 0 && !_isBufferring)
        {
            _isBufferring = YES;
        }
    }
    
    // 显示
    [self renderFrame];
    
    // 解码
    [self decodeFrame];
    
    // 循环
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1/40.0 * NSEC_PER_SEC);
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
    if (_status == kWBVideoPlayerStatusPaused)
    {
        return;
    }
     _status = kWBVideoPlayerStatusPaused;
    [self enableAudio:NO];
}

- (void)stop
{
    _status = kWBVideoPlayerStatusStopped;
    //[_decoder close];
    [self enableAudio:NO];
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

#pragma mark - Audio

- (void)enableAudio:(BOOL)on
{
    id<WBAudioPlayerProtocol> audioManager = [WBAudioManager sharedAudioManager];
    
    if (on && _decoder.validAudio)
    {
        __weak typeof(self) weakSelf = self;
        audioManager.outputBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {
            
            [weakSelf audioCallbackFillData: outData numFrames:numFrames numChannels:numChannels];
        };
        
        [audioManager play];
        
        WBVPLog(@"audio device smr: %d fmt: %d chn: %d",
                    (int)audioManager.samplingRate,
                    (int)audioManager.numBytesPerSample,
                    (int)audioManager.numOutputChannels);
        
    } else {
        
        [audioManager pause];
        audioManager.outputBlock = nil;
    }
}

- (void) audioCallbackFillData: (float *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels
{
    //fillSignalF(outData,numFrames,numChannels);
    //return;
    
    if (_isBufferring) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }
    
    @autoreleasepool {
        
        while (numFrames > 0) {
            
            if (!_currentAudioFrame) {
                
                @synchronized(_audioFrames) {
                    
                    NSUInteger count = _audioFrames.count;
                    
                    if (count > 0) {
                        
                        WBAudioFrame *frame = _audioFrames[0];
                        
#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                        if (_decoder.validVideo) {
                            
                            const CGFloat delta = _position - frame.position;
                            
                            if (delta < -0.1) {
                                
                                memset(outData, 0, numFrames * numChannels * sizeof(float));
#ifdef DEBUG
                                WBVPLog(@"desync audio (outrun) wait %.4f %.4f", _position, frame.position);
                                _debugAudioStatus = 1;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                break; // silence and exit
                            }
                            
                            [_audioFrames removeObjectAtIndex:0];
                            
                            if (delta > 0.1 && count > 1) {
                                
#ifdef DEBUG
                                WBVPLog(@"desync audio (lags) skip %.4f %.4f", _position, frame.position);
                                _debugAudioStatus = 2;
                                _debugAudioStatusTS = [NSDate date];
#endif
                                continue;
                            }
                            
                        } else {
                            
                            [_audioFrames removeObjectAtIndex:0];
                            _position = frame.position;
                            _bufferedDuration -= frame.duration;
                        }
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;
                    }
                }
            }
            
            if (_currentAudioFrame) {
                
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;
                
            } else {
                
                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
#ifdef DEBUG
                _debugAudioStatus = 3;
                _debugAudioStatusTS = [NSDate date];
#endif
                break;
            }
        }
    }
}

@end
