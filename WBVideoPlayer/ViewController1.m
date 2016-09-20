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
    
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:imageView];
//    [self.view sendSubviewToBack:imageView];
//    imageView.contentMode = UIViewContentModeScaleAspectFit;
//    imageView.backgroundColor = [UIColor blackColor];

    
    player = [[WBVideoPlayer alloc] init];
    player.delegate = self;
    player.frame = CGRectMake(0, 200, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16.0);

    [player prepareToPlayWithUrl:self.url];
    [self.view addSubview:player.view];
    
    
    
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];

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
        
        [self performSelector:@selector(tick) withObject:nil afterDelay:1.0];
    }
    else if (event == kWBVideoPlayerEventPlayEnd)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)tick
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];
    slider.value = player.position;
    positionLabel.text = [NSString stringWithFormat:@"%lf", slider.value];
    [self performSelector:@selector(tick) withObject:nil afterDelay:1.0];
    NSLog(@"position:%lf", slider.value);
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

- (IBAction)sliderDown:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];
    [player pause];
}

- (IBAction)slider:(UISlider *)sender
{
    [player seekToPosition:sender.value];
    [self performSelector:@selector(tick) withObject:nil afterDelay:1.0];
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
