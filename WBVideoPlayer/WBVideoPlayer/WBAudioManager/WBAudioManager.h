//
//  WBAudioManager.h
//  WBVideoPlayer
//
//  Created by wubing on 16/8/9.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

@protocol WBAudioPlayerProtocol;

@interface WBAudioManager : NSObject

+ (id <WBAudioPlayerProtocol>)sharedAudioManager;

@end
