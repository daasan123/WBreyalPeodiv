//
//  WBVideoGLView.h
//  WBVideoPlayer
//
//  Created by wubing on 16/8/5.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBVideoGLRenderer.h"

enum {
    ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

@class WBVideoFrame;
@class WBVideoDecoder;

@interface WBVideoGLView : UIView

- (instancetype)initWithFrame:(CGRect)frame decoder:(WBVideoDecoder *)decoder;

- (void)render:(WBVideoFrame *)frame;

@end
