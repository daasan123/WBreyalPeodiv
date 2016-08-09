//
//  WBAudioManager.m
//  WBVideoPlayer
//
//  Created by wubing on 16/8/9.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "WBAudioManager.h"
#import "WBAudioPlayer.h"

@implementation WBAudioManager

+ (id <WBAudioPlayerProtocol>)sharedAudioManager
{
    static WBAudioPlayer *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WBAudioPlayer alloc] init];
    });
    return manager;
}

@end
