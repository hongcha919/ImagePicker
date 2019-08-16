//
//  AudioRecordVC.m
//  HelloCordova
//
//  Created by haoqi on 2019/7/22.
//

#import "AudioRecordVC.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+LFMECoreText.h"
#import "lame.h"
#import "UIAlertView+LF_Block.h"
#import "CustomUploadVC.h"
#import "LFResultObject_property.h"
#import "NSBundle+LFImagePicker.h"

#define myTempFilePath [NSString stringWithFormat:@"%@/tmp/audio/",NSHomeDirectory()]
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)

@interface AudioRecordVC ()<AVAudioRecorderDelegate>
{
    //音频录制对象
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    NSURL *pathURL;
    
    //进度视图
    UIView *progressView;
    UILabel *leftRecTimeLab; //左侧录制时间
    UILabel *totalTimeLab; //录制总时间
    UIProgressView *progressBarView;
    //录制时间
    UILabel *recTimeLab;
    //控制视图
    UIView *controllView;
    UIButton *resetBtn;
    UIButton *recordBtn;
    UIButton *okBtn;
    UIButton *dismissBtn;
    //录制计时器
    NSTimer *recordTimer;
    NSTimeInterval timeLen;//录音时长
    double lowPassResults;
    //是否暂停录音
    BOOL isPause;
}

@end

@implementation AudioRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initData];
    
    [self createContentView];
}

-(void)initData {
    isPause = YES;
    
}

/**
 创建内容视图
 */
-(void)createContentView {
    //进度视图
    UIView *proView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-320, self.view.frame.size.width, 60)];
    proView.backgroundColor = [UIColor clearColor];
    progressView = proView;
    [self.view addSubview:progressView];
    
    UILabel *leftLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, progressView.frame.size.height)];
    leftLab.textAlignment = NSTextAlignmentRight;
    leftLab.font = [UIFont systemFontOfSize:18];
    leftLab.textColor = [UIColor whiteColor];
    leftLab.text = @"00:00";
    leftRecTimeLab = leftLab;
    [progressView addSubview:leftRecTimeLab];
    
    UILabel *rightLab = [[UILabel alloc] initWithFrame:CGRectMake(progressView.frame.size.width-80, 0, 80, progressView.frame.size.height)];
    rightLab.textAlignment = NSTextAlignmentLeft;
    rightLab.font = [UIFont systemFontOfSize:16];
    rightLab.textColor = [UIColor whiteColor];
    rightLab.text = [NSString getSafeStrWithStr:[self getShowTimeWithTime:self.maxRecTime isShowMS:NO] showNull:@"00:00"];
    totalTimeLab = rightLab;
    [progressView addSubview:totalTimeLab];
    
    //进度视图
    //实例化一个进度条，有两种样式，一种是UIProgressViewStyleBar一种是UIProgressViewStyleDefault，然并卵-->>几乎无区别
    progressBarView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    //设置的高度对进度条的高度没影响，整个高度=进度条的高度，进度条也是个圆角矩形
    progressBarView.frame=CGRectMake(CGRectGetMaxX(leftRecTimeLab.frame)+10, 29, progressView.frame.size.width - 180, 0);
    //设置进度条颜色
//    progressBarView.trackTintColor=[UIColor colorWithPatternImage:[NSBundle lf_MediaPickerUploadImage:pic_yinlang_white"]];
    //设置进度默认值，这个相当于百分比，范围在0~1之间，不可以设置最大最小值
    //progressBarView.progress=0.7;
    //设置进度条上进度的颜色
    progressBarView.progressTintColor=[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1];
    //设置进度条的背景图片
    progressBarView.trackImage = [NSBundle lf_MediaPickerUploadImage:@"中间灰色周围黑色"];
    //设置进度条上进度的背景图片
//    progressBarView.progressImage = [UIImage imageNamed:@"pic_yinlang_blue"];
    //由于pro的高度不变 使用放大的原理让其改变
    progressBarView.transform = CGAffineTransformMakeScale(1.0f, 30.0f);
    //自己设置的一个值 和进度条作比较 其实为了实现动画进度
    progressBarView.progress= 0.0;
    [progressView addSubview:progressBarView];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:progressBarView.frame];
    imgView.image = [NSBundle lf_MediaPickerUploadImage:@"中间透明周围黑色"];
    [progressView addSubview:imgView];
    
//    UIImage *image3 = [UIImage imageNamed:@"pic_yinlang_blue"];
//    CALayer *_maskLayer = [CALayer new];
//    _maskLayer.frame =CGRectMake(0, 0, 0, 10);
//    _maskLayer.anchorPoint = CGPointMake(0.5, 1);//单独使用bounds动画，大小改变，中心点不变，需要调整锚点使蒙层的锚点在(0,0.5)位置（默认锚点为(0.5, 0.5)）
//    _maskLayer.backgroundColor = [UIColor colorWithPatternImage:image3].CGColor;//这种方法绘制背景色比较耗内存，图片尽量小点
//    [progressBarView.layer addSublayer:_maskLayer];
//
//    CABasicAnimation *widthAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
//    widthAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 0, 20)];
//    widthAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, progressBarView.frame.size.width, 20)];
//    widthAnimation.duration = 60;
//    widthAnimation.repeatCount = HUGE_VALF; //无限循环
//    [_maskLayer addAnimation:widthAnimation forKey:@"coverScroll"];
//
    //录制时间
    UILabel *recLab = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(progressView.frame)+10, self.view.frame.size.width, 60)];
    recLab.textAlignment = NSTextAlignmentCenter;
    recLab.font = [UIFont systemFontOfSize:30];
    recLab.textColor = [UIColor whiteColor];
    recLab.text = @"00:00.00";
    recTimeLab = recLab;
    [self.view addSubview:recTimeLab];
    
    //控制视图
    UIView *contView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(recTimeLab.frame)+20, self.view.frame.size.width, 180)];
    contView.backgroundColor = [UIColor clearColor];
    controllView = contView;
    [self.view addSubview:controllView];
    //录音、暂停按钮
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake(controllView.frame.size.width/2-40, 0, 80, 80);
    [recordButton setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(recordStart_PauseBtn:) forControlEvents:UIControlEventTouchUpInside];
    recordBtn = recordButton;
    [controllView addSubview:recordBtn];
    //重置按钮
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.frame = CGRectMake(CGRectGetMaxX(recordBtn.frame)-recordBtn.frame.size.width-80, CGRectGetMaxY(recordBtn.frame)-recordBtn.frame.size.height/2-20, 40, 40);
    [resetButton setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_reset_default"] forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetBtn:) forControlEvents:UIControlEventTouchUpInside];
    resetBtn = resetButton;
    resetBtn.enabled = NO;
    resetBtn.alpha = 0.5;
    [controllView addSubview:resetBtn];
    //完成按钮
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    okButton.frame = CGRectMake(CGRectGetMaxX(recordBtn.frame)+40, CGRectGetMaxY(recordBtn.frame)-recordBtn.frame.size.height/2-20, 40, 40);
    [okButton setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_ok__default"] forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okBtn:) forControlEvents:UIControlEventTouchUpInside];
    okBtn = okButton;
    okBtn.enabled = NO;
    okBtn.alpha = 0.5;
    [controllView addSubview:okBtn];
    //删除按钮
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.frame = CGRectMake(controllView.frame.size.width/2-30, CGRectGetMaxY(recordBtn.frame)+10, 60, 60);
    [deleteButton setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_cancel"] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteBtn:) forControlEvents:UIControlEventTouchUpInside];
    dismissBtn = deleteButton;
    [controllView addSubview:dismissBtn];
}
#pragma mark =============== 按钮事件 ===============
/**
 录音、暂停按钮

 @param btn 按钮
 */
-(void)recordStart_PauseBtn:(UIButton*)btn {
    if (![self canRecord]) {
        [self showAlertWithTitle:@"无法打开麦克风，请确定在隐私>麦克风设置中打开了权限" complete:^{
            
        }];
        return;
    }
    
    if (isPause) {
        isPause = NO;
        [recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_press"] forState:UIControlStateNormal];
        
        resetBtn.enabled = NO;
        resetBtn.alpha = 0.5;
        
        dismissBtn.enabled = NO;
        dismissBtn.alpha = 0.5;
        
        okBtn.enabled = NO;
        okBtn.alpha = 0.5;
        
        if (!audioRecorder) {
            //开始继续录音
            NSDictionary *settings=[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithFloat:16000],AVSampleRateKey,
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                    [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                    nil];
            
            NSError *error;
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: &error];
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            
            NSURL *url = [NSURL fileURLWithPath:[self getAudioFilePath]];
            pathURL = url;
            
            audioRecorder = [[AVAudioRecorder alloc] initWithURL:pathURL settings:settings error:&error];
            audioRecorder.delegate = self;
        }
        
        recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateRecordTime:) userInfo:nil repeats:YES];
        [recordTimer fire];
        BOOL flag = NO;
        flag = [audioRecorder prepareToRecord];
        [audioRecorder setMeteringEnabled:YES];
        flag = [audioRecorder peakPowerForChannel:1];
        flag = [audioRecorder record];
        
    }else{
        isPause = YES;
        [recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
        
        resetBtn.enabled = YES;
        resetBtn.alpha = 1;
        
        okBtn.enabled = YES;
        okBtn.alpha = 1;
        
        dismissBtn.enabled = YES;
        dismissBtn.alpha = 1;
        
        //暂停录音
        [audioRecorder pause];
        [recordTimer invalidate];
        recordTimer = nil;
    }
}

/**
 重置按钮
 
 @param btn 按钮
 */
-(void)resetBtn:(UIButton*)btn {
    [recordTimer invalidate];
    recordTimer = nil;
    isPause = YES;
    [recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
    
    [audioRecorder pause];
    [audioRecorder stop];
    audioRecorder = nil;
    
    //删除录制文件
    [self deleteWithContentPath:pathURL.path];
    
    leftRecTimeLab.text = @"00:00";
    recTimeLab.text = @"00:00.00";
    
    resetBtn.enabled = NO;
    resetBtn.alpha = 0.5;
    
    dismissBtn.enabled = YES;
    dismissBtn.alpha = 1;
    
    okBtn.enabled = NO;
    okBtn.alpha = 0.5;
    
    recordBtn.enabled = YES;
    recordBtn.alpha = 1;
    
    progressBarView.progress = 0.0f;
    
}

/**
 完成按钮
 
 @param btn 按钮
 */
-(void)okBtn:(UIButton*)btn {
    [recordTimer invalidate];
    recordTimer = nil;
    isPause = YES;
    
    [audioRecorder pause];
    [audioRecorder stop];
    audioRecorder = nil;
    
    if (timeLen<1){
        timeLen = 1;
    }
    NSString *mp3Path = [self wavTomp3:pathURL.path];
    NSLog(@"mp3Path...%@", mp3Path);
    
    if (self.isGetCloudRes) {
        //跳转上传页面
        CustomUploadVC *uploadVC = [[CustomUploadVC alloc] init];
        
        LFResultVideo *result = [LFResultVideo new];
        result.coverImage = nil;
        
        NSData *data = [NSData dataWithContentsOfFile:mp3Path];
        
        result.data = data;
        result.url = [NSURL fileURLWithPath:mp3Path];
        NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:mp3Path] options:opts];
        NSTimeInterval duration = CMTimeGetSeconds(urlAsset.duration);
        result.duration = duration;
        
        LFResultInfo *info = [LFResultInfo new];
        info.name =[mp3Path lastPathComponent];
        result.info = info;
        
        uploadVC.uploadArray = [NSMutableArray arrayWithArray:@[result]];
        uploadVC.isAudio = YES;
        
        [uploadVC setBackButtonClickBlock:^{
            NSLog(@"backButtonClickBlock");
        }];
        [uploadVC setDoneButtonClickBlock:^(NSMutableArray * _Nonnull resultArray) {
            NSLog(@"doneButtonClickBlock");
            [self->recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
            self->leftRecTimeLab.text = @"00:00";
            self->recTimeLab.text = @"00:00.00";
            
            [self deleteWithContentPath:self->pathURL.path];
            
            [self dismissViewControllerAnimated:YES completion:^{
                //执行回调方法
                if (self.doneButtonClickBlock) {
                    self.doneButtonClickBlock(resultArray);
                }
            }];
        }];
        
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:uploadVC];
        
        [self presentViewController:navVC animated:YES completion:^{
            
        }];
    }else{
        [self->recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
        self->leftRecTimeLab.text = @"00:00";
        self->recTimeLab.text = @"00:00.00";
        
        [self deleteWithContentPath:self->pathURL.path];
        
        [self dismissViewControllerAnimated:YES completion:^{
            //执行回调方法
            if (self.doneButtonClickBlock) {
                self.doneButtonClickBlock([@[mp3Path] mutableCopy]);
            }
        }];
    }
}

/**
 删除按钮
 
 @param btn 按钮
 */
-(void)deleteBtn:(UIButton*)btn {
    [self resetBtn:nil];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


/**
 录音计时器响应方法

 @param timer 计时器
 */
-(void)updateRecordTime:(NSTimer*)timer {
    timeLen = audioRecorder.currentTime;
    
    NSLog(@"timeLen....%f",timeLen);
    
    
    if(timeLen>=self.maxRecTime){
        timeLen = self.maxRecTime;
        [recordTimer invalidate];
        recordTimer = nil;
        isPause = YES;
        
        [audioRecorder pause];
        [audioRecorder stop];
        audioRecorder = nil;
        
        [recordBtn setImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
        resetBtn.enabled = YES;
        resetBtn.alpha = 1;
        okBtn.enabled = YES;
        okBtn.alpha = 1;
        dismissBtn.enabled = YES;
        dismissBtn.alpha = 1;
        recordBtn.enabled = NO;
        recordBtn.alpha = 0.4;
        
        //暂停录音
        [audioRecorder pause];
        [recordTimer invalidate];
        recordTimer = nil;
        isPause = YES;
    }
    
    leftRecTimeLab.text = [self getShowTimeWithTime:timeLen isShowMS:NO];
    recTimeLab.text = [self getShowTimeWithTime:timeLen isShowMS:YES];
    NSLog(@"proView.progress....%f", (timeLen)/(float)self.maxRecTime);
    progressBarView.progress = (timeLen)/(float)self.maxRecTime;
    
    //录音的音量波段大小
    [audioRecorder updateMeters];
    const double alpha=0.5;
    NSLog(@"peakPowerForChannel = %f,%f", [audioRecorder peakPowerForChannel:0],[audioRecorder peakPowerForChannel:1]);
    double peakPowerForChannel=pow(10, (0.05)*[audioRecorder peakPowerForChannel:0]);
    
    lowPassResults=alpha*peakPowerForChannel+(1.0-alpha)*lowPassResults;
    NSLog(@"lowPassResults....%f",lowPassResults);
}

#pragma mark =============== 私有方法 ===============
-(NSString*)getAudioFilePath{
    NSString* s = [NSString uuidString];
    s = [[s stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    NSString *fileName = [NSString stringWithFormat:@"%@.wav",s];
    // 先创建子目录
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:myTempFilePath]) {
        [fileManager createDirectoryAtPath:myTempFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSLog(@"有这个文件了");
    }
    return [myTempFilePath stringByAppendingPathComponent:fileName];
}

/**
 根据时间z获取显示时间字符串

 @param time 时间，已s为单位
 @param isShowMS 是否显示毫秒
 @return 时间字符串
 */
-(NSString*)getShowTimeWithTime:(float)time isShowMS:(BOOL)isShowMS{
    if (time>0) {
        int hour = time/3600;
        int minute = time/60;
        int second = (int)time%60;
        
        if(isShowMS){
            NSString *timeStr = [NSString stringWithFormat:@"%.2f",time];
            NSArray *array = [timeStr componentsSeparatedByString:@"."];
            NSString *msStr;
            if(array.count >= 2){
                msStr = [self getDoubleTime:[array[array.count-1] intValue]];
            }else{
                msStr = @"00";
            }
            if (hour>0) {
                return [NSString stringWithFormat:@"%@:%@:%@.%@",[self getDoubleTime:hour],[self getDoubleTime:minute],[self getDoubleTime:second],msStr];
            }else{
                return [NSString stringWithFormat:@"%@:%@.%@",[self getDoubleTime:minute],[self getDoubleTime:second],msStr];
            }
        }else{
            if (hour>0) {
                return [NSString stringWithFormat:@"%@:%@:%@",[self getDoubleTime:hour],[self getDoubleTime:minute],[self getDoubleTime:second]];
            }else{
                return [NSString stringWithFormat:@"%@:%@",[self getDoubleTime:minute],[self getDoubleTime:second]];
            }
        }
    }else{
        if(isShowMS){
            return @"00:00.00";
        }
        return @"00:00";
    }
}

/**
 根据时间获取两位时间s显示 4-》04 19-》19

 @param time 时间
 @return <#return value description#>
 */
-(NSString *)getDoubleTime:(int)time {
    if (time > 0) {
        if (time < 10) {
            return [NSString stringWithFormat:@"0%d",time];
        }else{
            return [NSString stringWithFormat:@"%d",time];
        }
    }else{
        return @"00";
    }
}


/**
 是否可以录制音频

 @return 是否可以
 */
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 7.0) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    return bCanRecord;
}

//录音文件转码
- (NSString *)wavTomp3:(NSString*)wavPath
{
    NSString *mp3FilePath = [wavPath stringByReplacingOccurrencesOfString:@".wav" withString:@".mp3"];
    NSLog(@"预期存储路径:%@",mp3FilePath);
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([wavPath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb+");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 16000);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        lame_set_num_channels(lame,1); //***修改转码的mp3文件为单声道,不设置默认是双声道
        do {
//            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            read = (int)fread(pcm_buffer,sizeof(short int), PCM_SIZE, pcm); //***双声道第二个参数设置 2*sizeof(shortint)
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer(lame, pcm_buffer,pcm_buffer, read, mp3_buffer, MP3_SIZE);//***单声道写入
//                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);//***双声道写入
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        return @"";
    }
    @finally {
        NSLog(@"MP3生成成功: %@",mp3FilePath);
        return mp3FilePath;
    }
}

- (BOOL) deleteWithContentPath:(NSString *)thePath{
    NSError *error=nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:thePath]) {
        [fileManager removeItemAtPath:thePath error:&error];
    }
    if (error) {
        NSLog(@"删除文件时出现问题:%@",[error localizedDescription]);
        return NO;
    }
    return YES;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark =============== AVAudioRecorderDelegate ===============
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [recordTimer invalidate];
    recordTimer = nil;
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

#pragma mark =============== 提示相关 ===============
- (void)showAlertWithTitle:(NSString *)title {
    [self showAlertWithTitle:title complete:nil];
}

- (void)showAlertWithTitle:(NSString *)title complete:(void (^)(void))complete
{
    [self showAlertWithTitle:title message:nil complete:complete];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message complete:(void (^)(void))complete
{
    [self showAlertWithTitle:title cancelTitle:@"确定" message:message complete:complete];
}

- (void)showAlertWithTitle:(NSString *)title cancelTitle:(NSString *)cancelTitle message:(NSString *)message complete:(void (^)(void))complete
{
    if (iOS8Later) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (complete) {
                complete();
            }
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] lf_initWithTitle:title message:message cancelButtonTitle:cancelTitle otherButtonTitles:nil block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (complete) {
                complete();
            }
        }] show];
    }
}

@end
