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
    
    kxMovieErrorNone,
    kxMoveiErrorBadUrl,
    kxMovieErrorOpenFile,
    kxMovieErrorStreamInfoNotFound,
    kxMovieErrorStreamNotFound,
    kxMovieErrorCodecNotFound,
    kxMovieErrorOpenCodec,
    kxMovieErrorAllocateFrame,
    kxMovieErroSetupScaler,
    kxMovieErroReSampler,
    kxMovieErroUnsupported,
    
} kxMovieError;

//NSString * const kxmovieErrorDomain = @"com.wubing.WBVideoPlayer";

static NSString * errorMessage (kxMovieError errorCode)
{
    switch (errorCode) {
        case kxMovieErrorNone:
            return @"";
        case kxMoveiErrorBadUrl:
            return NSLocalizedString(@"bad url", nil);
        case kxMovieErrorOpenFile:
            return NSLocalizedString(@"Unable to open file", nil);
            
        case kxMovieErrorStreamInfoNotFound:
            return NSLocalizedString(@"Unable to find stream information", nil);
            
        case kxMovieErrorStreamNotFound:
            return NSLocalizedString(@"Unable to find stream", nil);
            
        case kxMovieErrorCodecNotFound:
            return NSLocalizedString(@"Unable to find codec", nil);
            
        case kxMovieErrorOpenCodec:
            return NSLocalizedString(@"Unable to open codec", nil);
            
        case kxMovieErrorAllocateFrame:
            return NSLocalizedString(@"Unable to allocate frame", nil);
            
        case kxMovieErroSetupScaler:
            return NSLocalizedString(@"Unable to setup scaler", nil);
            
        case kxMovieErroReSampler:
            return NSLocalizedString(@"Unable to setup resampler", nil);
            
        case kxMovieErroUnsupported:
            return NSLocalizedString(@"The ability is not supported", nil);
    }
}

static NSError * kxmovieError (NSInteger code, id info)
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

static NSError * mediaErrorWithCode(kxMovieError errorCode)
{
    return kxmovieError(errorCode, errorMessage(errorCode));
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
