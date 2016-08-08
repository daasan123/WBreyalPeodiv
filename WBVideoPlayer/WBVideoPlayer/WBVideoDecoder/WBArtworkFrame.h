//
//  WBArtworkFrame.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBMediaFrame.h"
#import <UIKit/UIKit.h>

@interface WBArtworkFrame : WBMediaFrame
@property (readonly, nonatomic, strong) NSData *picture;
- (UIImage *)asImage;
@end
