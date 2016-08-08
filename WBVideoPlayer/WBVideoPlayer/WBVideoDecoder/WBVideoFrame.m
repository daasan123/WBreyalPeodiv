//
//  WBVideoFrame.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBVideoFrame.h"

#pragma mark - WBVideoFrameRGB
@implementation WBVideoFrame

- (WBMediaFrameType)type
{
    return kWBMediaFrameTypeVideo;
}

@end

#pragma mark - WBVideoFrameRGB
@implementation WBVideoFrameRGB

- (WBVideoFrameFormat)format
{
    return kWBVideoFrameFormatRGB;
}

- (UIImage *)asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
}

@end

#pragma mark - WBVideoFrameYUV
@implementation WBVideoFrameYUV
- (WBVideoFrameFormat)format
{
    return kWBVideoFrameFormatYUV;
}
@end