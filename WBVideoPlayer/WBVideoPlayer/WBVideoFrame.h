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
@property (readonly, nonatomic) WBVideoFrameFormat format;
@property (readonly, nonatomic) NSUInteger width;
@property (readonly, nonatomic) NSUInteger height;
@end

/**
 *  RGB
 */
@interface WBVideoFrameRGB : WBVideoFrame
@property (readonly, nonatomic) NSUInteger linesize;
@property (readonly, nonatomic, strong) NSData *rgb;
- (UIImage *)asImage;
@end

/**
 *  YUV
 */
@interface WBVideoFrameYUV : WBVideoFrame
@property (readonly, nonatomic, strong) NSData *luma;
@property (readonly, nonatomic, strong) NSData *chromaB;
@property (readonly, nonatomic, strong) NSData *chromaR;
@end