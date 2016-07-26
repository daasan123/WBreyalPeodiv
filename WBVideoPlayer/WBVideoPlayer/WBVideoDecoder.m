//
//  WBVideoDecoder.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBVideoDecoder.h"
#import <Accelerate/Accelerate.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

#import "WBVideoFrame.h"
#import "WBAudioFrame.h"
#import "WBArtworkFrame.h"
#import "WBSubTitleFrame.h"

#import "WBVideoPlayerHelper.h"



@implementation WBVideoDecoder
{
    AVFormatContext     *_formatCtx;
    
    AVCodecContext      *_videoCodecCtx;
    AVCodecContext      *_audioCodecCtx;
    AVCodecContext      *_subtitleCodecCtx;
    
    AVFrame             *_videoFrame;
    AVFrame             *_audioFrame;
    
    NSInteger           _videoStream;
    NSInteger           _audioStream;
    NSInteger           _subtitleStream;
    
    NSArray             *_videoStreams;
    NSArray             *_audioStreams;
    NSArray             *_subtitleStreams;
    
    AVPicture           _picture;
    BOOL                _pictureValid;
    struct SwsContext   *_swsContext;
    
    SwrContext          *_swrContext;
    void                *_swrBuffer;
    NSUInteger          _swrBufferSize;
    NSDictionary        *_info;
    WBVideoFrameFormat  _videoFrameFormat;
    NSUInteger          _artworkStream;
    NSInteger           _subtitleASSEvents;
}

- (BOOL)interruptDecoder
{
    if (_interruptCallback)
    {
        return _interruptCallback();
    }
    
    return NO;
}

static int interrupt_callback(void *ctx)
{
    if (!ctx)
    {
        return 0;
    }
    
    __unsafe_unretained WBVideoDecoder *p = (__bridge WBVideoDecoder *)ctx;
    const BOOL r = [p interruptDecoder];
    
    if (r)
    {
        WBVPLog(@"DEBUG: INTERRUPT_CALLBACK!");
    }
    return r;
}

#pragma mark - LifeCycle

+ (void)initialize
{
    av_register_all();
    avformat_network_init();
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [self close];
}

- (BOOL)openVideo:(NSString *)url error:(NSError **)error
{
    if (!url)
    {
        WBVPLog(@"open video failed: url nil");
        return NO;
    }
    
    if (_formatCtx)
    {
        WBVPLog(@"video already opened");
        return YES;
    }
    
    /*
    BOOL isNetwork = isNetworkPath(url);
    // 网络初始化
    static BOOL needNetworkInit = YES;
    if (needNetworkInit && isNetwork)
    {
        needNetworkInit = NO;
        avformat_network_init();
    }*/
    
    _path = url;
    
    kxMovieError errCode = [self openInput: _path];
    
    if (errCode == kxMovieErrorNone)
    {
        kxMovieError videoErr = [self openVideoStream];
        kxMovieError audioErr = [self openAudioStream];
        
        _subtitleStream = -1;
        
        if (videoErr != kxMovieErrorNone &&
            audioErr != kxMovieErrorNone) {
            
            errCode = videoErr; // both fails
            
        } else {
            
            _subtitleStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_SUBTITLE);
        }

    }
    else
    {
        [self close];
        NSString *errMsg = errorMessage(errCode);
        WBVPLog(@"%@, %@", errMsg, _path.lastPathComponent);
        if (error)
        {
            *error = kxmovieError(errCode, errMsg);
        }
        return NO;
    }

    return YES;
}

- (kxMovieError) openVideoStream
{
    return 0;
}

- (kxMovieError) openAudioStream
{
    return 0;
}

- (kxMovieError) openInput: (NSString *) path
{
    AVFormatContext *formatCtx = NULL;
    if (_interruptCallback) {
        
        formatCtx = avformat_alloc_context();
        if (!formatCtx)
            return kxMovieErrorOpenFile;
        
        AVIOInterruptCB cb = {interrupt_callback, (__bridge void *)(self)};
        formatCtx->interrupt_callback = cb;
    }
    
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL) < 0) {
        
        if (formatCtx)
            avformat_free_context(formatCtx);
        return kxMovieErrorOpenFile;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        
        avformat_close_input(&formatCtx);
        return kxMovieErrorStreamInfoNotFound;
    }
    
    av_dump_format(formatCtx, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], false);
    
    _formatCtx = formatCtx;
    return kxMovieErrorNone;
}

-(void) close
{
    [self closeAudioStream];
    [self closeVideoStream];
    [self closeSubtitleStream];
    
    _videoStreams = nil;
    _audioStreams = nil;
    _subtitleStreams = nil;
    
    if (_formatCtx) {
        
        _formatCtx->interrupt_callback.opaque = NULL;
        _formatCtx->interrupt_callback.callback = NULL;
        
        avformat_close_input(&_formatCtx);
        _formatCtx = NULL;
    }
}

- (void)closeAudioStream
{
    _audioStream = -1;
    
    if (_swrBuffer) {
        
        free(_swrBuffer);
        _swrBuffer = NULL;
        _swrBufferSize = 0;
    }
    
    if (_swrContext) {
        
        swr_free(&_swrContext);
        _swrContext = NULL;
    }
    
    if (_audioFrame) {
        
        av_free(_audioFrame);
        _audioFrame = NULL;
    }
    
    if (_audioCodecCtx) {
        
        avcodec_close(_audioCodecCtx);
        _audioCodecCtx = NULL;
    }
}

- (void) closeScaler
{
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

- (void)closeVideoStream
{
    _videoStream = -1;
    
    [self closeScaler];
    
    if (_videoFrame) {
        
        av_free(_videoFrame);
        _videoFrame = NULL;
    }
    
    if (_videoCodecCtx) {
        
        avcodec_close(_videoCodecCtx);
        _videoCodecCtx = NULL;
    }
}

- (void)closeSubtitleStream
{
    _subtitleStream = -1;
    
    if (_subtitleCodecCtx) {
        
        avcodec_close(_subtitleCodecCtx);
        _subtitleCodecCtx = NULL;
    }
}


@end
