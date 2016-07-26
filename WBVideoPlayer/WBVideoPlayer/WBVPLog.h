//
//  WBVPLog.h
//  WBVideoPlayer
//
//  Created by peter on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#ifndef WBVPLog_h
#define WBVPLog_h

#ifdef DEBUG

#define WBVPLog(...)   NSLog(__VA_ARGS__)

#else

#define WBVPLog(...)   while(0) {}

#endif

#endif /* WBVPLog_h */
