//
//  ViewController1.m
//  WBVideoPlayer
//
//  Created by wubing on 16/7/30.
//  Copyright © 2016年 wubing. All rights reserved.
//

#import "ViewController1.h"
#import "WBVideoPlayer.h"

@interface ViewController1 ()<WBVideoPlayerDelegate>
{
    WBVideoPlayer *player;
}
@end

@implementation ViewController1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor blackColor];
    
    
    NSString *url = @"http://127.0.0.1/video/1.mp4";
    
    player = [[WBVideoPlayer alloc] init];
    player.delegate = self;
    [player prepareToPlayWithUrl:url];
    
    player.view = imageView;
    
    // Do any additional setup after loading the view.
}

- (void)wbVideoPlayerCallbackWithEvent:(WBVideoPlayerEvent)event
{
    NSLog(@"event:%zd", event);
    if (event == kWBVideoPlayerEventPrepared)
    {
        
        NSLog(@"duration:%lf", player.duration);
        
        slider.value = 0;
        slider.maximumValue = player.duration;
        
        [player resume];
    }
}

- (void)dealloc
{
    [player stop];
}

- (IBAction)play:(id)sender
{
    [player resume];
}

- (IBAction)pause:(id)sender
{
    [player pause];
}

- (IBAction)slider:(UISlider *)sender
{
    [player seekToPosition:sender.value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
