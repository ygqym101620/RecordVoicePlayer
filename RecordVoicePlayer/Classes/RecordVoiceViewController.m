//
//  RecordVoiceViewController.m
//  TestAudioApp
//
//  Created by 杨国强 on 15/8/26.
//  Copyright (c) 2015年 ygq. All rights reserved.
//

#import "RecordVoiceViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface RecordVoiceViewController ()<AVAudioPlayerDelegate,AVAudioRecorderDelegate>
@property(nonatomic,strong)UIButton    *recordBtn;
@property(nonatomic,strong)UIButton    *playerBtn;
@property(nonatomic,strong)UIButton    *deleteBtn;
@property(nonatomic,strong)UILabel     *recordTimeLbl;
@property(nonatomic,strong)UILabel     *playerTimeLbl;
@property(nonatomic,strong)UIImageView *anmitionView;
@property(nonatomic,strong)NSTimer     *myTimer;
@property(nonatomic,assign)NSInteger   recordNumber;
@property(nonatomic,strong)AVAudioPlayer *audioPlayer;
@property(nonatomic,strong)AVAudioRecorder *audioRecorder;
@property(nonatomic,strong)AVAudioSession *audioSession;
@property(nonatomic,strong)NSURL       *recordingUrl;
@property(nonatomic,assign)NSInteger   recordTime;
@property(nonatomic,assign)NSInteger   playerTime;
@property(nonatomic,assign)BOOL        hasRecord;
@property(nonatomic,assign)BOOL        stopCountDown;
@property(nonatomic,strong)NSMutableArray     *imageArray;
@end

@implementation RecordVoiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title=@"录制音频及播放";
    self.view.backgroundColor=[UIColor whiteColor];
    
    self.recordBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    self.recordBtn.frame=CGRectMake(0, 0, 182/2, 182/2);
    self.recordBtn.center=self.view.center;
    [self.view addSubview:self.recordBtn];
    [self.recordBtn setBackgroundImage:[UIImage imageNamed:@"voice_record"] forState:UIControlStateNormal];
    
    self.playerBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    self.playerBtn.frame=CGRectMake(0, 0, 102/2, 105/2);
    self.playerBtn.center=CGPointMake(self.view.center.x-51/2-80, self.view.center.y);
    [self.view addSubview:self.playerBtn];
    [self.playerBtn setBackgroundImage:[UIImage imageNamed:@"voice_play"] forState:UIControlStateNormal];
    [self.playerBtn setBackgroundImage:[UIImage imageNamed:@"voice_pause"] forState:UIControlStateSelected];
    self.playerBtn.selected=NO;
    
    self.deleteBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteBtn.frame=CGRectMake(0, 0, 102/2, 105/2);
    self.deleteBtn.center=CGPointMake(self.view.center.x+51/2+80, self.view.center.y);
    [self.view addSubview:self.deleteBtn];
    [self.deleteBtn setBackgroundImage:[UIImage imageNamed:@"voice_delete"] forState:UIControlStateNormal];
    
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
    label.center=CGPointMake(self.view.center.x, CGRectGetMaxY(self.recordBtn.frame)+15);
    [self.view addSubview:label];
    label.backgroundColor=[UIColor clearColor];
    label.textAlignment=NSTextAlignmentCenter;
    label.font=[UIFont systemFontOfSize:16];
    label.text=@"长按 录音";
    
    self.anmitionView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 202/2, 67/2)];
    self.anmitionView.center=CGPointMake(self.view.center.x, CGRectGetMinY(self.recordBtn.frame)-100);
    [self.view addSubview:self.anmitionView];
    self.anmitionView.image=[UIImage imageNamed:@"voice_0"];
    
    self.playerTimeLbl=[[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.anmitionView.frame)+5, CGRectGetMinY(self.anmitionView.frame), 90, 67/2)];
    [self.view addSubview:self.playerTimeLbl];
    self.playerTimeLbl.backgroundColor=[UIColor clearColor];
    self.playerTimeLbl.font=[UIFont systemFontOfSize:14];
    self.playerTimeLbl.textAlignment=NSTextAlignmentLeft;
    self.playerTimeLbl.text=@"3\"";
    
    self.recordTimeLbl=[[UILabel alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/2-50, CGRectGetMinY(self.recordBtn.frame)-35, 100, 30)];
    [self.view addSubview:self.recordTimeLbl];
    self.recordTimeLbl.textAlignment=NSTextAlignmentCenter;
    self.recordTimeLbl.font=[UIFont systemFontOfSize:14];
    self.recordTimeLbl.text=@"00:00";
    
    self.recordNumber=0;
    self.recordTime  =0;
    self.playerTime  =0;
    self.hasRecord   =NO;
    self.imageArray  =[[NSMutableArray alloc]init];
    for(int i=1;i<=3;i++){
        UIImage *image=[UIImage imageNamed:[NSString stringWithFormat:@"voice_%d",i]];
        [self.imageArray addObject:image];
    }
    self.anmitionView.hidden=YES;
    self.playerTimeLbl.hidden=YES;
    [self prepareForRecord];
    
    @weakify(self);
    
    [RACObserve(self, recordTime)subscribeNext:^(NSNumber *vaule){
        @strongify(self);
        NSInteger num=[vaule integerValue];
        self.recordTimeLbl.text=[self calculateTime:num];
    }];
    
    [RACObserve(self, playerTime)subscribeNext:^(NSNumber *value){
        NSInteger num=[value integerValue];
        self.playerTimeLbl.text=[NSString stringWithFormat:@"%ld\"",num];
    }];
    
    [[self.recordBtn rac_signalForControlEvents:UIControlEventTouchDown]subscribeNext:^(id x){
        @strongify(self);
        [self startRecordMethod];
    }];
    [[self.recordBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x){
        @strongify(self);
        [self endRecordMethod];
    }];
    [[self.recordBtn rac_signalForControlEvents:UIControlEventTouchUpOutside]subscribeNext:^(id x){
        @strongify(self);
        [self endRecordMethod];
    }];
    
    [[self.playerBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x){
        @strongify(self);
        if(self.playerBtn.selected==NO){
           [self startPlayerMethod];
        }
        else{
            [self endPlayerMethod];
        }
    }];
    
    [[self.deleteBtn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(id x){
        [self deleteMethod];
    }];
    
    
}
-(void)prepareForRecord{
    _audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"audioSession:%@ %d %@", [error domain], (int)[error code], [[error userInfo] description]);
        return;
    }
    [_audioSession setActive:YES error:&error];
    error = nil;
    if (error) {
        NSLog(@"audioSession:%@ %d %@", [error domain], (int)[error code], [[error userInfo] description]);
        return;
    }
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey, nil];
    
    _recordingUrl = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"selfRecord.wav"]];
    NSLog(@"----%@",_recordingUrl);
    error = nil;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:_recordingUrl settings:recordSetting error:&error];
    _audioRecorder.meteringEnabled = YES;
    _audioRecorder.delegate = self;
}
-(void)startRecordMethod{
    if(self.recordNumber>0){
        [self recordAgain];
    }
    _audioSession = [AVAudioSession sharedInstance];
    
    if (!_audioRecorder.recording) {
        
        _recordNumber++;
        [_audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [_audioSession setActive:YES error:nil];
        [_audioRecorder prepareToRecord];
        [_audioRecorder peakPowerForChannel:0.0];
        [_audioRecorder record];
        _recordTime = 0;
        [self recordTimeStart];
    }
}
-(void)recordTimeStart{
    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(recordTimesTick) userInfo:nil repeats:YES];
}
-(void)recordTimesTick{
    self.recordTime++;
}
-(void)endRecordMethod{
    _audioSession = [AVAudioSession sharedInstance];
    
    if (_audioRecorder.isRecording) {
        [_audioRecorder stop];
        [_audioSession setActive:NO error:nil];
        [self.myTimer invalidate];
        self.hasRecord=YES;
    }
}
-(void)startPlayerMethod{
    @weakify(self);
    if(self.hasRecord==YES){
        self.playerBtn.selected=YES;
        [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [_audioSession setActive:YES error:nil];
        
        NSError *error = nil;
        if (_recordingUrl != nil) {
            
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_recordingUrl error:&error];
            _audioPlayer.delegate=self;
        }
        if (error) {
            NSLog(@"error:%@", [error description]);
        }
        self.stopCountDown=NO;
        [[[[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]]
           takeUntil:[RACObserve(self, stopCountDown) filter:^BOOL(NSNumber* value) {
            return value.boolValue;
        }]] doNext:^(id x) {
            @strongify(self);
            self.playerTime=self.audioPlayer.currentTime;
        }]subscribeNext:^(id x){
            
        }];
        [self.anmitionView setAnimationImages:self.imageArray];
        self.anmitionView.animationDuration=1;
        self.anmitionView.animationRepeatCount=0;
        [self.anmitionView startAnimating];
        [_audioPlayer prepareToPlay];
        _audioPlayer.volume = 1;
        [_audioPlayer play];
        
    }
}
-(void)endPlayerMethod{
    self.playerBtn.selected=NO;
    self.stopCountDown=YES;
    self.playerTime   =0;
    [self.anmitionView stopAnimating];
    self.anmitionView.image=[UIImage imageNamed:@"voice_0"];
    [_audioPlayer pause];
    [_audioSession setActive:NO error:nil];
    self.playerBtn.selected=NO;
}
-(void)recordAgain{
    [_audioPlayer stop];
    [_audioRecorder stop];
    [_audioSession setActive:NO error:nil];
    [self.myTimer invalidate];
    _recordTime = 0;
    _playerTime =0;
    
}

-(void)deleteMethod{
    if (self.hasRecord) {
        _audioSession = [AVAudioSession sharedInstance];
        
        self.hasRecord = NO;
        [_audioPlayer stop];
        [_audioRecorder stop];
        [_audioSession setActive:NO error:nil];
        [_myTimer invalidate];
        self.stopCountDown=YES;
        [_audioRecorder deleteRecording];
        self.anmitionView.hidden=YES;
        self.playerTimeLbl.hidden=YES;
        self.recordTime=0;
    }
}

#pragma mark audioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"record finish");
    self.anmitionView.hidden=NO;
    self.playerTimeLbl.hidden=NO;
}
#pragma mark audioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if(flag==YES){
       [self endPlayerMethod];
    }
}

-(NSString *)calculateTime:(NSInteger)time{
    NSInteger seconds = time % 60;
    NSInteger minutes = (time / 60) % 60;
    NSInteger hours = time / 3600;
    NSString *timeStr;
    if(hours<10){
        if(minutes<10){
            if(seconds<10){
                timeStr=[NSString stringWithFormat:@"0%ld:0%ld:0%ld",hours,minutes,seconds];
            }
            else{
                timeStr=[NSString stringWithFormat:@"0%ld:0%ld:%ld",hours,minutes,seconds];
            }
        }
        else{
            if(seconds<10){
                timeStr=[NSString stringWithFormat:@"0%ld:%ld:0%ld",hours,minutes,seconds];
            }
            else{
                timeStr=[NSString stringWithFormat:@"0%ld:%ld:%ld",hours,minutes,seconds];
            }
        }
    }
    else{
        if(minutes<10){
            if(seconds<10){
                timeStr=[NSString stringWithFormat:@"%ld:0%ld:0%ld",hours,minutes,seconds];
            }
            else{
                timeStr=[NSString stringWithFormat:@"%ld:0%ld:%ld",hours,minutes,seconds];
            }
        }
        else{
            if(seconds<10){
                timeStr=[NSString stringWithFormat:@"%ld:%ld:0%ld",hours,minutes,seconds];
            }
            else{
                timeStr=[NSString stringWithFormat:@"%ld:%ld:%ld",hours,minutes,seconds];
            }
        }
    }
    return timeStr;
}
-(BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    
    return UIInterfaceOrientationPortrait;
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
