//
//  WBVideoPlayerHelper.h
//  WBVideoPlayer
//
//  Created by peter on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBVPLog.h"

#pragma mark - Error

typedef enum {
    
    kWBMediaErrorNone,
    kWBMediaErrorBadUrl,
    kWBMediaErrorOpenFile,
    kWBMediaErrorStreamInfoNotFound,
    kWBMediaErrorStreamNotFound,
    kWBMediaErrorCodecNotFound,
    kWBMediaErrorOpenCodec,
    kWBMediaErrorAllocateFrame,
    kWBMediaErroSetupScaler,
    kWBMediaErroReSampler,
    kWBMediaErroUnsupported,
    
} WBMediaError;

//NSString * const WBMediaErrorDomain = @"com.wubing.WBVideoPlayer";

static NSString * errorMessage (WBMediaError errorCode)
{
    switch (errorCode) {
        case kWBMediaErrorNone:
            return @"";
        case kWBMediaErrorBadUrl:
            return NSLocalizedString(@"bad url", nil);
        case kWBMediaErrorOpenFile:
            return NSLocalizedString(@"Unable to open file", nil);
            
        case kWBMediaErrorStreamInfoNotFound:
            return NSLocalizedString(@"Unable to find stream information", nil);
            
        case kWBMediaErrorStreamNotFound:
            return NSLocalizedString(@"Unable to find stream", nil);
            
        case kWBMediaErrorCodecNotFound:
            return NSLocalizedString(@"Unable to find codec", nil);
            
        case kWBMediaErrorOpenCodec:
            return NSLocalizedString(@"Unable to open codec", nil);
            
        case kWBMediaErrorAllocateFrame:
            return NSLocalizedString(@"Unable to allocate frame", nil);
            
        case kWBMediaErroSetupScaler:
            return NSLocalizedString(@"Unable to setup scaler", nil);
            
        case kWBMediaErroReSampler:
            return NSLocalizedString(@"Unable to setup resampler", nil);
            
        case kWBMediaErroUnsupported:
            return NSLocalizedString(@"The ability is not supported", nil);
    }
}

static NSError * wbMediaError (NSInteger code, id info)
{
    NSDictionary *userInfo = nil;
    
    if ([info isKindOfClass: [NSDictionary class]]) {
        
        userInfo = info;
        
    } else if ([info isKindOfClass: [NSString class]]) {
        
        userInfo = @{ NSLocalizedDescriptionKey : info };
    }
    
    return [NSError errorWithDomain:@"com.wubing.WBVideoPlayer"
                               code:code
                           userInfo:userInfo];
}

static NSError * mediaErrorWithCode(WBMediaError errorCode)
{
    return wbMediaError(errorCode, errorMessage(errorCode));
}

#pragma mark - Utility
static BOOL isNetworkPath (NSString *path)
{
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound)
        return NO;
    NSString *scheme = [path substringToIndex:r.length];
    if ([scheme isEqualToString:@"file"])
        return NO;
    return YES;
}

@interface WBVideoPlayerHelper : NSObject

@end
