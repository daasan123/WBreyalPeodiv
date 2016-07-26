//
//  WBMediaFrame.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
//#import "WBVPLog.h"

// 帧数据类型
typedef NS_ENUM(NSUInteger, WBMediaFrameType)
{
    kWBMediaFrameTypeAudio,     // 音频
    kWBMediaFrameTypeVideo,     // 视频
    kWBMediaFrameTypeArtwork,   //
    kWBMediaFrameTypeSubtitle,  // 字幕
};



/**
 *  帧数据基类
 */
@interface WBMediaFrame : NSObject
@property (readonly, nonatomic) WBMediaFrameType type;
@property (readonly, nonatomic) CGFloat position;
@property (readonly, nonatomic) CGFloat duration;
@end





