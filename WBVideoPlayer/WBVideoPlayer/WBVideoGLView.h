//
//  WBVideoGLView.h
//  WBVideoPlayer
//
//  Created by wubing on 16/8/5.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBVideoFrame;
@class WBVideoDecoder;

@interface WBVideoGLView : UIView

- (id) initWithFrame:(CGRect)frame
             decoder: (WBVideoDecoder *) decoder;

- (void) render: (WBVideoFrame *) frame;

@end
