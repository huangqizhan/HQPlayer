//
//  PlayerViewController.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/7/15.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "PlayerViewController.h"
#import "HQPlayer.h"

@interface PlayerViewController ()

@property (nonatomic,strong) HQPlayer *player;
@property (nonatomic,strong) HQPlayerItem *playItem;


@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[HQPlayer alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:HQPlayerDidChangeInfosNotification object:self.player];
}
- (void)viewDidAppear{
    [super viewDidAppear];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    self.player.videoRenderer.view = self.view;
    self.player.videoRenderer.displayMode = HQDisplayModePlane;
    ///
    NSURL *furl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"mama1" ofType:@"mp4"]];
//    NSURL *furl = [NSURL URLWithString:@"http://200038117.vod.myqcloud.com/200038117_faf831e4acde11e68b47678b6f4187c3.f0.mp4"];
    HQAsset *asset = [HQAsset assetWithUrl:furl];
    
    _playItem = [[HQPlayerItem alloc] initWithAsset:asset];
    self.player.rate = 1.5;
    [self.player replaceWithItem:_playItem];
    [self.player play];
}
- (void)infoChanged:(NSNotification *)info{
    
}
@end
