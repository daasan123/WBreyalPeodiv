//
//  ViewController1.h
//  WBVideoPlayer
//
//  Created by wubing on 16/7/30.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController1 : UIViewController
{
    IBOutlet UIButton *playBtn;
    IBOutlet UIButton *pauseBtn;
    IBOutlet UISlider *slider;
    IBOutlet UILabel *positionLabel;
}

@property (nonatomic, strong) NSString *url;
@end
