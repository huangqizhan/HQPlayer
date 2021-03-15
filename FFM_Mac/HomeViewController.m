//
//  De.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/11.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "HomeViewController.h"
#import "ffmpeg_config_info.h"
#import "HQFFmpeg.h"
#import "HQDefine.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVDepthData.h>
#import "HQPlayerHeader.h"
#import "PlayerViewController.h"
#import "ex_h264.h"
#import "filter_1.h"
#import "rec_audio.h"
#import "rec_video.h"
#import "ex_yuv.h"

@interface HomeViewController ()<NSComboBoxDataSource,NSComboBoxDelegate>{
 
}
@property (strong,nonatomic)  NSString *rStr;
@property (copy, nonatomic)  NSString *cStr;

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSComboBox *protocolBox;

@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

@end

@implementation HomeViewController

@synthesize rate = _rate;

- (void)viewDidLoad {
    [super viewDidLoad];
//    char *info = ffm_protocol_info();
//    NSString *strInfo = [[NSString alloc] initWithUTF8String:info];
//    NSArray *arr = [strInfo componentsSeparatedByString:@"\n"];
//    NSLog(@"arr = %@",arr);
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"song" ofType:@"mp4"];
//    audio_info_t(path.UTF8String);
//
//    AVRational time1 = (AVRational){1,25};
//    AVRational time2 = (AVRational){1,90000};
//    uint64_t pts = 2;
//    int64_t d = av_rescale_q(pts, time1, time2);
//    NSLog(@"d = %lld",d);
    
//    TTModel *model = [TTModel new];
//    NSLog(@"name = %@",model.name);
    
    
    
    
    
    
//    AVFormatContext *ctx = avformat_alloc_context();
//    if (!ctx) {
//        NSLog(@"avformar create error");
//    };
////        ctx->interrupt_callback.callback = callback;
////        ctx->interrupt_callback.opaque = opaque;
//
//    NSString *urlString = @"http://200038117.vod.myqcloud.com/200038117_faf831e4acde11e68b47678b6f4187c3.f0.mp4";
////    [[NSBundle mainBundle] pathForResource:@"song" ofType:@"mp4"];
////        AVDictionary *avoptoin = HQDictionaryNS2FFM(optins);;
//    int success = avformat_open_input(&ctx, urlString.UTF8String, NULL, NULL);;
//    success = avformat_find_stream_info(ctx, NULL);;
////    NSLog(@"=====");


}
- (IBAction)buttonAction:(id)sender {
    char *info = ffm_protocol_info();
    NSString *strInfo = [[NSString alloc] initWithUTF8String:info];
    self.textView.string = strInfo;

//    NSString *dataStr = _textView.string;
//    NSData *data = [[dataStr jk_base64DecodedData] jk_gunzippedData];
//    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
//    _textView.string = @"";
//    _textView.string = str;
//    NSString *file = @"http://200038117.vod.myqcloud.com/200038117_faf831e4acde11e68b47678b6f4187c3.f0.mp4";
//    filter_action1(file.UTF8String);
    
    
//    NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadOperation) object:nil];
//    self->_operationQueue = [[NSOperationQueue alloc] init];
//    self->_operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
//    [self->_operationQueue addOperation:operation];
 
}

- (IBAction)recordAction:(id)sender {
    ffmpeg_device();
}

- (NSString *)dencode:(NSString *)base64String{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    return string;
}
- (IBAction)playAction:(NSButton *)sender {
//    PlayerViewController *playVC = [[PlayerViewController alloc] init];
//    [self presentViewControllerAsModalWindow:playVC];
  
//
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"mama1" ofType:@"mp4"];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *yuv_path = [documentPath stringByAppendingPathComponent:@"r1.yuv"];
    NSString *h_path = [documentPath stringByAppendingPathComponent:@"hr.h264"];
    NSLog(@"docmentpath = %@",documentPath);
//    extrac_video(path.UTF8String, yuv_path.UTF8String);
//
    open_video_device(yuv_path.UTF8String, h_path.UTF8String);
    
//    NSString *yuv_path = [documentPath stringByAppendingPathComponent:@"mamam1.yuv"];
//    NSString *url = @"http://200038117.vod.myqcloud.com/200038117_faf831e4acde11e68b47678b6f4187c3.f0.mp4";
//    NSString *local_path = [[NSBundle mainBundle] pathForResource:@"mama1" ofType:@"mp4"];
//    ex_video_yuv(local_path.UTF8String, yuv_path.UTF8String);
    
//    get_device_list();
}
- (void)threadOperation{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *pcm_path = [documentPath stringByAppendingPathComponent:@"p1.pcm"];
//    NSString *aac_path = [documentPath stringByAppendingPathComponent:@"a1.aac"];
    NSLog(@"docmentpath = %@",documentPath);
    rec_audio1(pcm_path.UTF8String);
//    extrac_video(path.UTF8String, documentPath.UTF8String);
//
//    open_video_device(yuv_path.UTF8String, h_path.UTF8String);
}
#pragma mark --- NSComboBoxDataSource NSComboBoxDelegate
@end


