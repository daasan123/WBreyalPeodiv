//
//  ViewController.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/26.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "ViewController.h"

#import "WBVideoPlayer.h"

@interface ViewController ()<WBVideoPlayerDelegate>
{
    WBVideoPlayer *player;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *url = @"http://127.0.0.1/video/1.mp4";
    
    
    player = [[WBVideoPlayer alloc] init];
    player.delegate = self;
    [player prepareToPlayWithUrl:url];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)wbVideoPlayerCallbackWithEvent:(WBVideoPlayerEvent)event
{
    NSLog(@"event:%zd", event);
    if (event == kWBVideoPlayerEventPrepared)
    {
        [player resume];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
