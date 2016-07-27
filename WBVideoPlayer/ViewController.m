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
    
    NSString *url = @"http://bst.mobile.live.bestvcdn.com.cn/live/program/live991/weixincctv1hd/live.m3u8?se=weixin&ct=1&_fk=65F79F8F78CF053FDFEAC4E3372A4C036671C0A8C3EEC2D8F0B916E5E3181B1F";
    
    
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
