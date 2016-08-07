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
    
    CGFloat             _videoTimeBase;
    CGFloat             _audioTimeBase;
    
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

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        WBVPLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
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

#pragma mark - Getters and Setters

- (CGFloat)startTime
{
    // 优先使用视频的
    if (self.validVideo) {
        
        AVStream *st = _formatCtx->streams[_videoStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _videoTimeBase;
        return 0;
    }
    
    // 其次使用音频的
    if (self.validAudio) {
        
        AVStream *st = _formatCtx->streams[_audioStream];
        if (AV_NOPTS_VALUE != st->start_time)
            return st->start_time * _audioTimeBase;
        return 0;
    }
    
    return 0;
}

- (CGFloat)duration
{
    if (!_formatCtx)
        return 0;
    if (_formatCtx->duration == AV_NOPTS_VALUE)
        return MAXFLOAT;
    return (CGFloat)_formatCtx->duration / AV_TIME_BASE;
}

- (void)setPosition: (CGFloat)seconds
{
    _position = seconds;
    _isEOF = NO;
	   
    if (self.validVideo) {
        int64_t ts = (int64_t)(seconds / _videoTimeBase);
        avformat_seek_file(_formatCtx, _videoStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(_videoCodecCtx);
    }
    
//    if (self.validAudio) {
//        int64_t ts = (int64_t)(seconds / _audioTimeBase);
//        avformat_seek_file(_formatCtx, _audioStream, ts, ts, ts, AVSEEK_FLAG_FRAME);
//        avcodec_flush_buffers(_audioCodecCtx);
//    }
}

- (NSUInteger) frameWidth
{
    return _videoCodecCtx ? _videoCodecCtx->width : 0;
}

- (NSUInteger) frameHeight
{
    return _videoCodecCtx ? _videoCodecCtx->height : 0;
}

- (CGFloat) sampleRate
{
    return _audioCodecCtx ? _audioCodecCtx->sample_rate : 0;
}

- (NSUInteger) audioStreamsCount
{
    return [_audioStreams count];
}

- (NSUInteger) subtitleStreamsCount
{
    return [_subtitleStreams count];
}

- (BOOL)validAudio
{
    return _audioStream != -1;
}

- (BOOL)validVideo
{
    return _videoStream != -1;
}

- (BOOL)validSubtitles
{
    return _subtitleStream != -1;
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

- (NSError *)openVideo:(NSString *)url;
{
    if (!url)
    {
        WBVPLog(@"open video failed: url nil");
        return mediaErrorWithCode(kWBMediaErrorBadUrl);
    }
    
    if (_formatCtx)
    {
        WBVPLog(@"video already opened");
        return nil;
    }
    
    
    _isNetwork = isNetworkPath(url);
    /*
    // 网络初始化
    static BOOL needNetworkInit = YES;
    if (needNetworkInit && isNetwork)
    {
        needNetworkInit = NO;
        avformat_network_init();
    }*/
    
    _path = url;
    
    // 获取上下文
    WBMediaError errCode = [self openInput: _path];
    
    // 打开流
    if (errCode == kWBMediaErrorNone)
    {
        WBMediaError videoErr = [self openVideoStream];
        WBMediaError audioErr = [self openAudioStream];
        
        _subtitleStream = -1;
        
        if (videoErr != kWBMediaErrorNone &&
            audioErr != kWBMediaErrorNone) {
            
            errCode = videoErr; // both fails
            
        } else {
            
            _subtitleStreams = [self collectStreams:_formatCtx forMediaType:AVMEDIA_TYPE_SUBTITLE];
        }

    }
    // 报错
    if (errCode != kWBMediaErrorNone)
    {
        [self close];
        return mediaErrorWithCode(errCode);
    }
    
    return nil;
}

- (NSArray *)collectStreams:(AVFormatContext *)formatCtx forMediaType:(enum AVMediaType)mediaType
{
    NSMutableArray *streamIndexArray = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; i++)
    {
        if (mediaType == formatCtx->streams[i]->codec->codec_type)
        {
            [streamIndexArray addObject:@(i)];
        }
    }
    return streamIndexArray;
}

- (WBMediaError) openVideoStream
{
    WBMediaError errCode = kWBMediaErrorStreamNotFound;
    _videoStream = -1;
    _artworkStream = -1;
    _videoStreams = [self collectStreams:_formatCtx forMediaType:AVMEDIA_TYPE_VIDEO];
    for (NSNumber *videoIndex in _videoStreams)
    {
        NSInteger videoIndexInt = videoIndex.integerValue;
        // ?
        if (0 == (_formatCtx->streams[videoIndexInt]->disposition & AV_DISPOSITION_ATTACHED_PIC))
        {
            _videoStream = videoIndexInt;
            errCode = [self openVideoStreamWithIndex:_videoStream];
            if (kWBMediaErrorNone == errCode)
            {
                break;
            }
        }
        else
        {
            _artworkStream = videoIndexInt;
        }
    }
    return errCode;
}

- (WBMediaError)openVideoStreamWithIndex:(NSUInteger)videoStream
{
    // get a pointer to the codec context for the video stream
    AVCodecContext *codecCtx = _formatCtx->streams[videoStream]->codec;
    
    // find the decoder for the video stream
    AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
    if (!codec)
        return kWBMediaErrorCodecNotFound;
    
    // inform the codec that we can handle truncated bitstreams -- i.e.,
    // bitstreams where frame boundaries can fall in the middle of packets
    //if(codec->capabilities & CODEC_CAP_TRUNCATED)
    //    _codecCtx->flags |= CODEC_FLAG_TRUNCATED;
    
    // open codec
    if (avcodec_open2(codecCtx, codec, NULL) < 0)
        return kWBMediaErrorOpenCodec;
    
    _videoFrame = av_frame_alloc();
    
    if (!_videoFrame) {
        avcodec_close(codecCtx);
        return kWBMediaErrorAllocateFrame;
    }
    
    _videoStream = videoStream;
    _videoCodecCtx = codecCtx;
    
    // determine fps
    
    AVStream *st = _formatCtx->streams[_videoStream];
    avStreamFPSTimeBase(st, 0.04, &_fps, &_videoTimeBase);
    
    WBVPLog(@"video codec size: %zd:%zd fps: %.3f tb: %f",
            self.frameWidth,
            self.frameHeight,
            _fps,
            _videoTimeBase);
    
    WBVPLog(@"video start time %f", st->start_time * _videoTimeBase);
    WBVPLog(@"video disposition %d", st->disposition);
    
    return kWBMediaErrorNone;
}
- (WBMediaError) openAudioStream
{
    return 0;
}

- (WBMediaError) openInput: (NSString *) path
{
    AVFormatContext *formatCtx = NULL;
    if (_interruptCallback) {
        
        formatCtx = avformat_alloc_context();
        if (!formatCtx)
            return kWBMediaErrorOpenFile;
        
        AVIOInterruptCB cb = {interrupt_callback, (__bridge void *)(self)};
        formatCtx->interrupt_callback = cb;
    }
    
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL) < 0) {
        
        if (formatCtx)
            avformat_free_context(formatCtx);
        return kWBMediaErrorOpenFile;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        
        avformat_close_input(&formatCtx);
        return kWBMediaErrorStreamInfoNotFound;
    }
    
    av_dump_format(formatCtx, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], false);
    
    _formatCtx = formatCtx;
    return kWBMediaErrorNone;
}

- (BOOL) setupScaler
{
    [self closeScaler];
    
    _pictureValid = avpicture_alloc(&_picture,
                                    PIX_FMT_RGB24,
                                    _videoCodecCtx->width,
                                    _videoCodecCtx->height) == 0;
    
    if (!_pictureValid)
        return NO;
    
    _swsContext = sws_getCachedContext(_swsContext,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       _videoCodecCtx->pix_fmt,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    return _swsContext != NULL;
}

- (BOOL)setupVideoFrameFormat:(WBVideoFrameFormat) format
{
    if (format == kWBVideoFrameFormatYUV &&
        _videoCodecCtx &&
        (_videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P)) {
        
        _videoFrameFormat = kWBVideoFrameFormatYUV;
        return YES;
    }
    
    _videoFrameFormat = kWBVideoFrameFormatRGB;
    return _videoFrameFormat == format;
}

- (WBVideoFrame *) handleVideoFrame
{
    if (!_videoFrame->data[0])
        return nil;
    
    WBVideoFrame *frame;
    
    if (_videoFrameFormat == kWBVideoFrameFormatYUV) {
        
        WBVideoFrameYUV * yuvFrame = [[WBVideoFrameYUV alloc] init];
        
        yuvFrame.luma = copyFrameData(_videoFrame->data[0],
                                      _videoFrame->linesize[0],
                                      _videoCodecCtx->width,
                                      _videoCodecCtx->height);
        
        yuvFrame.chromaB = copyFrameData(_videoFrame->data[1],
                                         _videoFrame->linesize[1],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        
        yuvFrame.chromaR = copyFrameData(_videoFrame->data[2],
                                         _videoFrame->linesize[2],
                                         _videoCodecCtx->width / 2,
                                         _videoCodecCtx->height / 2);
        
        frame = yuvFrame;
        
    } else {
        
        if (!_swsContext &&
            ![self setupScaler]) {
            
            WBVPLog(@"fail setup video scaler");
            return nil;
        }
        
        sws_scale(_swsContext,
                  (const uint8_t **)_videoFrame->data,
                  _videoFrame->linesize,
                  0,
                  _videoCodecCtx->height,
                  _picture.data,
                  _picture.linesize);
        
        
        WBVideoFrameRGB *rgbFrame = [[WBVideoFrameRGB alloc] init];
        
        rgbFrame.linesize = _picture.linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                      length:rgbFrame.linesize * _videoCodecCtx->height];
        frame = rgbFrame;
    }
    
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    frame.position = av_frame_get_best_effort_timestamp(_videoFrame) * _videoTimeBase;
    
    const int64_t frameDuration = av_frame_get_pkt_duration(_videoFrame);
    if (frameDuration) {
        
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
        
        //if (_videoFrame->repeat_pict > 0) {
        //    LoggerVideo(0, @"_videoFrame.repeat_pict %d", _videoFrame->repeat_pict);
        //}
        
    } else {
        
        // sometimes, ffmpeg unable to determine a frame duration
        // as example yuvj420p stream from web camera
        frame.duration = 1.0 / _fps;
    }
    
#if 0
    LoggerVideo(2, @"VFD: %.4f %.4f | %lld ",
                frame.position,
                frame.duration,
                av_frame_get_pkt_pos(_videoFrame));
#endif
    
    return frame;
}

- (NSArray *)decodeFrames:(CGFloat)minDuration
{
    if ((!self.validVideo && !self.validAudio) || _isDecoding)
    {
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    AVPacket packet;
    
    CGFloat decodedDuration = 0;
    
    BOOL finished = NO;
    _isDecoding = YES;
    
    while (!finished) {
        
        if (av_read_frame(_formatCtx, &packet) < 0) {
            _isEOF = YES;
            break;
        }
        
        if (packet.stream_index ==_videoStream) {
            
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                
                int gotframe = 0;
                int len = avcodec_decode_video2(_videoCodecCtx,
                                                _videoFrame,
                                                &gotframe,
                                                &packet);
                
                if (len < 0) {
                    WBVPLog(@"decode video error, skip packet");
                    break;
                }
                
                if (gotframe) {
                    
                    if (!_disableDeinterlacing &&
                        _videoFrame->interlaced_frame) {
                        
                        avpicture_deinterlace((AVPicture*)_videoFrame,
                                              (AVPicture*)_videoFrame,
                                              _videoCodecCtx->pix_fmt,
                                              _videoCodecCtx->width,
                                              _videoCodecCtx->height);
                    }
                    
                    WBVideoFrame *frame = [self handleVideoFrame];
                    if (frame) {
                        
                        [result addObject:frame];
                        
                        _position = frame.position;
                        decodedDuration += frame.duration;
                        if (decodedDuration > minDuration)
                            finished = YES;
                    }
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
            
        }
        /*
        else if (packet.stream_index == _audioStream) {
            
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                
                int gotframe = 0;
                int len = avcodec_decode_audio4(_audioCodecCtx,
                                                _audioFrame,
                                                &gotframe,
                                                &packet);
                
                if (len < 0) {
                    WBVPLog(@"decode audio error, skip packet");
                    break;
                }
                
                if (gotframe) {
                    
                    WBAudioFrame * frame = [self handleAudioFrame];
                    if (frame) {
                        
                        [result addObject:frame];
                        
                        if (_videoStream == -1) {
                            
                            _position = frame.position;
                            decodedDuration += frame.duration;
                            if (decodedDuration > minDuration)
                                finished = YES;
                        }
                    }
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
            
        } else if (packet.stream_index == _artworkStream) {
            
            if (packet.size) {
                
                KxArtworkFrame *frame = [[KxArtworkFrame alloc] init];
                frame.picture = [NSData dataWithBytes:packet.data length:packet.size];
                [result addObject:frame];
            }
            
        } else if (packet.stream_index == _subtitleStream) {
            
            int pktSize = packet.size;
            
            while (pktSize > 0) {
                
                AVSubtitle subtitle;
                int gotsubtitle = 0;
                int len = avcodec_decode_subtitle2(_subtitleCodecCtx,
                                                   &subtitle,
                                                   &gotsubtitle,
                                                   &packet);
                
                if (len < 0) {
                    LoggerStream(0, @"decode subtitle error, skip packet");
                    break;
                }
                
                if (gotsubtitle) {
                    
                    KxSubtitleFrame *frame = [self handleSubtitle: &subtitle];
                    if (frame) {
                        [result addObject:frame];
                    }
                    avsubtitle_free(&subtitle);
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
        }
         */
        
        av_free_packet(&packet);
    }
    _isDecoding = NO;
    return result;
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
