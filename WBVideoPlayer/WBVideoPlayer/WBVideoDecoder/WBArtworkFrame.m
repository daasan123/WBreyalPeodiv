//
//  WBArtworkFrame.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBArtworkFrame.h"

@implementation WBArtworkFrame

- (WBMediaFrameType)type
{
    return kWBMediaFrameTypeArtwork;
}

- (UIImage *)asImage
{
    UIImage *image = nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_picture));
    if (provider) {
        
        CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(provider,
                                                                NULL,
                                                                YES,
                                                                kCGRenderingIntentDefault);
        if (imageRef) {
            
            image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        CGDataProviderRelease(provider);
    }
    
    return image;
    
}
@end
