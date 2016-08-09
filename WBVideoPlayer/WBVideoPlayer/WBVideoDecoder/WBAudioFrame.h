//
//  WBAudioFrame.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBMediaFrame.h"

/**
 *  音频帧
 */
@interface WBAudioFrame : WBMediaFrame
@property (nonatomic, strong) NSData *samples;
@end