//
//  WBVideoFrame.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBMediaFrame.h"
#import <UIKit/UIKit.h>

// 视频帧格式类型
typedef NS_ENUM(NSUInteger, WBVideoFrameFormat)
{
    kWBVideoFrameFormatRGB,
    kWBVideoFrameFormatYUV
};

/**
 *  视频帧
 */
@interface WBVideoFrame : WBMediaFrame
@property (nonatomic, assign) WBVideoFrameFormat format;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@end

/**
 *  RGB
 */
@interface WBVideoFrameRGB : WBVideoFrame
@property (nonatomic, assign) NSUInteger linesize;
@property (nonatomic, strong) NSData *rgb;
- (UIImage *)asImage;
@end

/**
 *  YUV
 */
@interface WBVideoFrameYUV : WBVideoFrame
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@end