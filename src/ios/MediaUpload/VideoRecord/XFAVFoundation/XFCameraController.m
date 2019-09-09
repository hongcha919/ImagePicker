//
//  QXCameraController.m
//
//
//  Created by xf-ling on 2017/6/1.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import "XFCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "XFCameraButton.h"
#import "XFPhotoLibraryManager.h"
#import <Photos/Photos.h>
#import <CoreMotion/CoreMotion.h>
#import "CustomPhotoEditingController.h"
#import "LFVideoEditingController.h"
#import "LFPhotoEditManager.h"
#import "LFVideoEditManager.h"

#import "CustomUploadVC.h"
#import "LFResultObject_property.h"
#import "NSBundle+LFImagePicker.h"
//#import "LFResultVideo.h"

#define degreeToRadinas(x) (M_PI * (x)/180.0)

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define iSiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define SafeViewBottomHeight (iSiPhoneX ? 24.0 : 0.0)
#define VIDEO_FILEPATH                                              @"video"
#define TIMER_INTERVAL 0.5f                                        // 定时器记录视频间隔
#define VIDEO_RECORDER_MAX_TIME 10.0f                               // 视频最大时长 (单位/秒)
#define VIDEO_RECORDER_MIN_TIME 1.0f                                // 最短视频时长 (单位/秒)
#define START_VIDEO_ANIMATION_DURATION 0.3f                         // 录制视频前的动画时间
#define DEFAULT_VIDEO_ZOOM_FACTOR 3.0f                              // 默认放大倍数

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface XFCameraController() <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate,CustomPhotoEditingControllerDelegate,LFVideoEditingControllerDelegate>

@property (nonatomic, strong) dispatch_queue_t videoQueue;

@property (strong, nonatomic) AVCaptureSession *captureSession;                          //负责输入和输出设备之间的数据传递

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;                          //视频输入
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;                          //声音输入
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (strong, nonatomic) AVCaptureStillImageOutput *captureStillImageOutput;        //照片输出流

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, assign) BOOL canWrite;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;      //预览图层

@property (nonatomic, strong) NSTimer *timer;                                            //记录录制时间

@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (weak, nonatomic) IBOutlet UIButton *rotateCameraButton;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (strong, nonatomic) XFCameraButton *cameraButton;                              //拍摄按钮

//录制视频时间视图,会根据屏幕旋转更新位置
@property (weak, nonatomic) IBOutlet UIView *recordVideoTopTimeView;
@property (weak, nonatomic) IBOutlet UILabel *recordVideoTopTimeLab;
@property (weak, nonatomic) IBOutlet UILabel *recRedTopLab;

@property (weak, nonatomic) IBOutlet UIView *recordVideoLeftTimeView;
@property (weak, nonatomic) IBOutlet UILabel *recordVideoLeftTimeLab;
@property (weak, nonatomic) IBOutlet UILabel *recRedLeftLab;

@property (weak, nonatomic) IBOutlet UIView *recordVideoRightTimeView;
@property (weak, nonatomic) IBOutlet UILabel *recordVideoRightTimeLab;
@property (weak, nonatomic) IBOutlet UILabel *recRedRightLab;


@property (weak, nonatomic) IBOutlet UIButton *videoRecBtn;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;
@property (weak, nonatomic) IBOutlet UIButton *takeButton;                               //拍摄按钮
- (IBAction)videoRecBtn:(id)sender;
- (IBAction)cameraBtn:(id)sender;
- (IBAction)takeButton:(id)sender;


@property (weak, nonatomic) IBOutlet UIImageView *focusImageView;                        //聚焦视图
@property (assign, nonatomic) Boolean isFocusing;                                        //镜头正在聚焦
@property (assign, nonatomic) Boolean isShooting;                                        //正在拍摄
@property (assign, nonatomic) Boolean isRotatingCamera;                                  //正在旋转摄像头

//捏合缩放摄像头
@property (nonatomic,assign) CGFloat beginGestureScale;                                  //记录开始的缩放比例
@property (nonatomic,assign) CGFloat effectiveScale;                                     //最后的缩放比例

//拍照摄像后的预览模块
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (strong, nonatomic) UIView *photoPreviewContainerView;                         //相片预览ContainerView
@property (strong, nonatomic) UIImageView *photoPreviewImageView;                        //相片预览ImageView
@property (strong, nonatomic) UIView *videoPreviewContainerView;                         //视频预览View
@property (strong, nonatomic) NSURL *videoURL;                                           //视频文件地址
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (assign, nonatomic) CGFloat currentVideoTimeLength;                             //当前小视频总时长

@property (assign, nonatomic) UIDeviceOrientation shootingOrientation;                    //手机方向
@property (assign, nonatomic) UIDeviceOrientation currentShootingOrientation;             //拍摄中的手机方向
@property (strong, nonatomic) CMMotionManager *motionManager;

@end

@implementation XFCameraController{
    
    CGFloat timeLength;             //时间长度
    
    UIButton *_progressHUD;
    UIView *_HUDContainer;
    UIActivityIndicatorView *_HUDIndicatorView;
    UILabel *_HUDLabel;

    int currentRecType; //当前选择类型 0:拍照 1:视频
}

#pragma mark - 工厂方法

+ (instancetype)defaultCameraController
{
    XFCameraController *cameraController = [[XFCameraController alloc] initWithNibName:@"XFCameraController" bundle:nil];
    
    return cameraController;
}

#pragma mark - 控制器方法

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 隐藏状态栏
    //    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    if (self.maxRecTime <= 0) {
        self.maxRecTime = VIDEO_RECORDER_MAX_TIME;
    }
    
    _isFocusing = NO;
    _isShooting = NO;
    _isRotatingCamera = NO;
    _canWrite = NO;
    _beginGestureScale = 1.0f;
    _effectiveScale = 1.0f;
    currentRecType = 0;
    
//    [self initCreateRecTimeView];
    
    [self initViewIMage];
    
    
}
////初始创建录音时间视图
//-(void)initCreateRecTimeView {
//
//    UIView *rectimeView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2-60, CGRectGetMinY(self.rotateCameraButton.frame)+  CGRectGetWidth(self.rotateCameraButton.frame)/2-12, 120, 25)];
//    rectimeView.backgroundColor = [UIColor blueColor];
//    [self.view addSubview:rectimeView];
//    self.recordVideoTimeView = rectimeView;
//
//    CGRect timeFrame = CGRectMake(15, 0, CGRectGetWidth(self.recordVideoTimeView.frame)-15, CGRectGetHeight(self.recordVideoTimeView.frame));
//    CGRect redFrame = CGRectMake(CGRectGetMinX(timeFrame)-6, CGRectGetHeight(self.recordVideoTimeView.frame)/2-3, 6, 6);
//
//    UILabel *timeLab = [[UILabel alloc] initWithFrame:timeFrame];
//    timeLab.text = @"00:00:00";
//    timeLab.font = [UIFont systemFontOfSize:20];
//    timeLab.textAlignment = NSTextAlignmentCenter;
//    timeLab.textColor = [UIColor whiteColor];
//    [self.recordVideoTimeView addSubview:timeLab];
//    self.recordVideoTimeLab = timeLab;
//
//    UILabel *redLab = [[UILabel alloc] initWithFrame:redFrame];
//    redLab.text = @"";
//    redLab.font = [UIFont systemFontOfSize:20];
//    redLab.backgroundColor = [UIColor redColor];
//    [self.recordVideoTimeView addSubview:redLab];
//    self.recRedLab = redLab;
//}

-(void)initViewIMage {
    self.recRedTopLab.layer.cornerRadius = 3;
    self.recRedTopLab.layer.masksToBounds = YES;
    self.recRedLeftLab.layer.cornerRadius = 3;
    self.recRedLeftLab.layer.masksToBounds = YES;
    self.recRedRightLab.layer.cornerRadius = 3;
    self.recRedRightLab.layer.masksToBounds = YES;
    
    [self.cancelButton setImage:[NSBundle lf_MediaPickerUploadImage:@"icon_return_n"] forState:UIControlStateNormal];
    [self.confirmButton setImage:[NSBundle lf_MediaPickerUploadImage:@"icon_finish_p"] forState:UIControlStateNormal];
    [self.editButton setImage:[NSBundle lf_MediaPickerUploadImage:@"edit"] forState:UIControlStateNormal];
    
    self.focusImageView.image = [NSBundle lf_MediaPickerUploadImage:@"sight_video_focus"];
    [self.rotateCameraButton setImage:[NSBundle lf_MediaPickerUploadImage:@"icon_change"] forState:UIControlStateNormal];
    [self.closeButton setImage:[NSBundle lf_MediaPickerUploadImage:@"icon_down"] forState:UIControlStateNormal];
    
    [self.takeButton setBackgroundImage:[NSBundle lf_MediaPickerUploadImage:@"btn_camera_write"] forState:UIControlStateNormal];
    [self.videoRecBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cameraBtn setTitleColor:[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1] forState:UIControlStateNormal];
    
    self.recordVideoTopTimeView.hidden = YES;
    self.recordVideoLeftTimeView.hidden = YES;
    self.recordVideoRightTimeView.hidden = YES;
    
    self.recordVideoRightTimeView.transform = CGAffineTransformIdentity;
    self.recordVideoRightTimeView.transform = CGAffineTransformMakeRotation(degreeToRadinas(90));
    
    self.recordVideoLeftTimeView.transform = CGAffineTransformIdentity;
    self.recordVideoLeftTimeView.transform = CGAffineTransformMakeRotation(degreeToRadinas(-90));
    
    self.currentShootingOrientation = UIDeviceOrientationPortrait;
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.shootType == 1) { //拍照
        self.videoRecBtn.hidden = YES;
        self.cameraBtn.hidden = YES;
        
        [self cameraBtn:nil];
        
    }else if (self.shootType == 2) { //录像
        self.videoRecBtn.hidden = YES;
        self.cameraBtn.hidden = YES;
        
        [self videoRecBtn:nil];
    }
    
    if (self.photoPreviewImageView || self.videoURL) {
        return;
    }

    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        [self requestAuthorizationForVideo];
    }
    
    //判断用户是否允许访问麦克风权限
    authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        [self requestAuthorizationForVideo];
    }
    [self requestAuthorizationForPhotoLibrary];
    
    [self initAVCaptureSession];
    
    [self configDefaultUIDisplay];
    
    [self addTapGenstureRecognizerForCamera];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.photoPreviewImageView || self.videoURL) {
        if (self.cutType != 0 && self.cutType != 1) {
            return;
        }
    }
    [self startSession];
    
    [self setFocusCursorWithPoint:self.view.center];
    
//    [self tipLabelAnimation];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 显示状态栏
    //    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopSession];
    
    [self stopUpdateAccelerometer];
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - 控件方法

/**
 *  关闭当前界面
 */
- (IBAction)closeBtnFunc:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  切换前后摄像头
 */
- (IBAction)rotateCameraBtnFunc:(id)sender
{
    _isRotatingCamera = YES;
    
    AVCaptureDevice *currentDevice = [self.videoInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront)
    {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.videoInput];
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput])
    {
        [self.captureSession addInput:toChangeDeviceInput];
        self.videoInput = toChangeDeviceInput;
    }
    
    //提交会话配置
    [self.captureSession commitConfiguration];
    
    _isRotatingCamera = NO;
}

- (IBAction)cancelBtnfunc:(id)sender
{
    [self removePlayerItemNotification];
    
    if (currentRecType == 1) {
        if (self->_shootingOrientation == UIDeviceOrientationPortrait || self->_shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
            self.recordVideoLeftTimeView.hidden = YES;
            self.recordVideoRightTimeView.hidden = YES;
            self.recordVideoTopTimeView.hidden = NO;
            self.recordVideoTopTimeLab.text = @"00:00:00";
        }
        if (self->_shootingOrientation == UIDeviceOrientationLandscapeLeft) {
            self.recordVideoLeftTimeView.hidden = YES;
            self.recordVideoRightTimeView.hidden = NO;
            self.recordVideoTopTimeView.hidden = YES;
            self.recordVideoRightTimeLab.text = @"00:00:00";
        }
        if (self->_shootingOrientation == UIDeviceOrientationLandscapeRight) {
            self.recordVideoLeftTimeView.hidden = NO;
            self.recordVideoRightTimeView.hidden = YES;
            self.recordVideoTopTimeView.hidden = YES;
            self.recordVideoLeftTimeLab.text = @"00:00:00";
        }
        self.recRedTopLab.hidden = NO;
        self.recRedLeftLab.hidden = NO;
        self.recRedRightLab.hidden = NO;
    }
    self.confirmButton.userInteractionEnabled = YES;
    
//    [self initAVCaptureSession];
//
//    [self addTapGenstureRecognizerForCamera];
    
    [self startSession];
    
    [self startAnimationGroup];
}

/**
 *  确认按钮并返回代理
 */
- (IBAction)confirmBtnFunc:(id)sender
{
    __weak __typeof__(self) weakSelf = self;
    if (self.photoPreviewImageView)
    {
        UIImage *finalImage = [self cutImageWithView:self.photoPreviewImageView];
        
        [XFPhotoLibraryManager savePhotoWithImage:finalImage andAssetCollectionName:self.assetCollectionName withCompletion:^(UIImage *image, NSError *error) {
            
            if (error)
            {
                NSLog(@"保存照片失败!");
                if (self->_isGetCloudRes) {
                    if (self.takePhotosCloudCompletionBlock){
                        weakSelf.takePhotosCloudCompletionBlock(nil);
                    }
                }else{
                    if (self.takePhotosCompletionBlock){
                        weakSelf.takePhotosCompletionBlock(nil, error);
                    }
                }
                weakSelf.confirmButton.userInteractionEnabled = YES;
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                NSLog(@"保存照片成功!");
                if (self->_isGetCloudRes) {
                    //当前用户被挤下线
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //跳转上传页面
                        CustomUploadVC *uploadVC = [[CustomUploadVC alloc] init];
                        
                        LFResultImage *result = [LFResultImage new];
                        result.asset = nil;
                        result.thumbnailImage = image;
                        result.thumbnailData = UIImageJPEGRepresentation(image,0.0f);
                        result.originalImage = image;
                        result.originalData = UIImageJPEGRepresentation(image,0.0f);;
                        result.subMediaType = LFImagePickerSubMediaTypeNone;
                        
                        LFResultInfo *info = [LFResultInfo new];
                        result.info = info;
                        uploadVC.uploadArray = [NSMutableArray arrayWithArray:@[result]];
                        uploadVC.errorAlertType = self.errorAlertType;
                        
                        [uploadVC setBackButtonClickBlock:^{
                            NSLog(@"backButtonClickBlock");
                            weakSelf.confirmButton.userInteractionEnabled = YES;
                        }];
                        [uploadVC setDoneButtonClickBlock:^(NSMutableArray * _Nonnull resultArray) {
                            
                            NSLog(@"doneButtonClickBlock");
                            if (weakSelf.takePhotosCloudCompletionBlock) {
                                weakSelf.takePhotosCloudCompletionBlock(resultArray);
                            }
                            weakSelf.confirmButton.userInteractionEnabled = YES;
                            [weakSelf dismissViewControllerAnimated:YES completion:nil];
                        }];
                        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:uploadVC];
                        
                        [weakSelf presentViewController:navVC animated:YES completion:^{
                            
                        }];
                    });
                }else{
                    if (self.takePhotosCompletionBlock){
                        weakSelf.takePhotosCompletionBlock(image, nil);
                    }
                    weakSelf.confirmButton.userInteractionEnabled = YES;
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }];
        
        self.confirmButton.userInteractionEnabled = NO;
        
    }
    else
    {
        NSURL *newUrl = [NSURL fileURLWithPath:[weakSelf createVideoFilePath]];
        [self showProgressHUD];
        //压缩视频
        [weakSelf convertVideoQuailtyWithInputURL:weakSelf.videoURL outputURL:newUrl completeHandler:^(NSString *path,BOOL isSuccess) {
            if (isSuccess) {
                weakSelf.videoURL = [NSURL fileURLWithPath:path];
            }
            [XFPhotoLibraryManager saveVideoWithVideoUrl:weakSelf.videoURL andAssetCollectionName:nil withCompletion:^(NSURL *videoUrl, NSError *error) {
                [weakSelf hideProgressHUD];
                if (error)
                {
                    NSLog(@"保存视频失败!");
                    if (self->_isGetCloudRes) {
                        if (weakSelf.shootCloudCompletionBlock){
                            weakSelf.shootCloudCompletionBlock(nil);
                        }
                    }else{
                        if (weakSelf.shootCompletionBlock){
                            weakSelf.shootCompletionBlock(nil, 0, nil, error);
                        }
                    }
                    weakSelf.confirmButton.userInteractionEnabled = YES;
                    [weakSelf cancelBtnfunc:nil];
                    [[NSFileManager defaultManager] removeItemAtURL:weakSelf.videoURL error:nil];
                    weakSelf.videoURL = nil;
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }
                else
                {
                    NSLog(@"保存视频成功!");
                    
                    // 获取视频的第一帧图片
                    UIImage *image = [weakSelf thumbnailImageRequestWithVideoUrl:videoUrl andTime:0.01f];
                    CGFloat videoDuration = [self getVideoLength:videoUrl];
                    if (!self->_isGetCloudRes) {
                        weakSelf.confirmButton.userInteractionEnabled = YES;
                        if (weakSelf.shootCompletionBlock){
                            weakSelf.shootCompletionBlock(videoUrl, videoDuration, image, nil);
                        }
                        [weakSelf cancelBtnfunc:nil];
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }else{
                        //当前用户被挤下线
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //跳转上传页面
                            CustomUploadVC *uploadVC = [[CustomUploadVC alloc] init];
                            
                            LFResultVideo *result = [LFResultVideo new];
                            result.coverImage = image;
                            result.asset = nil;
                            
                            NSData *data = [NSData dataWithContentsOfFile:videoUrl.absoluteString];
                            result.data = data;
                            result.url = videoUrl;
                            result.duration = videoDuration;
                            
                            LFResultInfo *info = [LFResultInfo new];
                            result.info = info;
                            uploadVC.uploadArray = [NSMutableArray arrayWithArray:@[result]];
                            uploadVC.errorAlertType = self.errorAlertType;
                            
                            [uploadVC setBackButtonClickBlock:^{
                                NSLog(@"backButtonClickBlock");
                                weakSelf.confirmButton.userInteractionEnabled = YES;
                                if (weakSelf.videoURL) {
                                    // 播放完成后重复播放
                                    // 跳到最新的时间点开始播放
                                    [weakSelf.player seekToTime:CMTimeMake(0, 1)];
                                    [weakSelf.player play];
                                }
                            }];
                            [uploadVC setDoneButtonClickBlock:^(NSMutableArray * _Nonnull resultArray) {
                                weakSelf.confirmButton.userInteractionEnabled = YES;
                                if (weakSelf.shootCloudCompletionBlock) {
                                    weakSelf.shootCloudCompletionBlock(resultArray);
                                }
                                [[NSFileManager defaultManager] removeItemAtURL:weakSelf.videoURL error:nil];
                                weakSelf.videoURL = nil;
                                [weakSelf cancelBtnfunc:nil];
                                
                                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                            }];
                            
                            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:uploadVC];
                            
                            [weakSelf presentViewController:navVC animated:YES completion:^{
                                
                            }];
                        });
                    }
                }
                
                weakSelf.confirmButton.userInteractionEnabled = NO;
                
            }];
            
        }];
        
//        [weakSelf cropWithVideoUrlStr:weakSelf.videoURL start:0 end:weakSelf.currentVideoTimeLength completion:^(NSURL *outputURL, Float64 videoDuration, BOOL isSuccess) {
//
//            if (isSuccess)
//            {
//                [XFPhotoLibraryManager saveVideoWithVideoUrl:outputURL andAssetCollectionName:nil withCompletion:^(NSURL *videoUrl, NSError *error) {
//
//                    if (error)
//                    {
//                        NSLog(@"保存视频失败!");
//                        if (self->_isGetCloudRes) {
//                            if (weakSelf.shootCloudCompletionBlock){
//                                weakSelf.shootCloudCompletionBlock(nil);
//                            }
//                        }else{
//                            if (weakSelf.shootCompletionBlock){
//                                weakSelf.shootCompletionBlock(nil, 0, nil, error);
//                            }
//                        }
//                        weakSelf.confirmButton.userInteractionEnabled = YES;
//                        [weakSelf cancelBtnfunc:nil];
//                        [[NSFileManager defaultManager] removeItemAtURL:weakSelf.videoURL error:nil];
//                        weakSelf.videoURL = nil;
//                        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
//                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
//                    }
//                    else
//                    {
//                        NSLog(@"保存视频成功!");
//
//                        // 获取视频的第一帧图片
//                        UIImage *image = [weakSelf thumbnailImageRequestWithVideoUrl:videoUrl andTime:0.01f];
//                        if (!self->_isGetCloudRes) {
//                            weakSelf.confirmButton.userInteractionEnabled = YES;
//                            if (weakSelf.shootCompletionBlock){
//                                weakSelf.shootCompletionBlock(videoUrl, videoDuration, image, nil);
//                            }
//                            [weakSelf cancelBtnfunc:nil];
//                            [weakSelf dismissViewControllerAnimated:YES completion:nil];
//                        }else{
//                            //当前用户被挤下线
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                //跳转上传页面
//                                CustomUploadVC *uploadVC = [[CustomUploadVC alloc] init];
//
//                                LFResultVideo *result = [LFResultVideo new];
//                                result.coverImage = image;
//                                result.asset = nil;
//
//                                NSData *data = [NSData dataWithContentsOfFile:videoUrl.absoluteString];
//                                result.data = data;
//                                result.url = videoUrl;
//                                result.duration = videoDuration;
//
//                                LFResultInfo *info = [LFResultInfo new];
//                                result.info = info;
//                                uploadVC.uploadArray = [NSMutableArray arrayWithArray:@[result]];
//
//                                [uploadVC setBackButtonClickBlock:^{
//                                    NSLog(@"backButtonClickBlock");
//                                    weakSelf.confirmButton.userInteractionEnabled = YES;
//                                    if (weakSelf.videoURL) {
//                                        // 播放完成后重复播放
//                                        // 跳到最新的时间点开始播放
//                                        [weakSelf.player seekToTime:CMTimeMake(0, 1)];
//                                        [weakSelf.player play];
//                                    }
//                                }];
//                                [uploadVC setDoneButtonClickBlock:^(NSMutableArray * _Nonnull resultArray) {
//                                    weakSelf.confirmButton.userInteractionEnabled = YES;
//                                    if (weakSelf.shootCloudCompletionBlock) {
//                                        weakSelf.shootCloudCompletionBlock(resultArray);
//                                    }
//                                    [[NSFileManager defaultManager] removeItemAtURL:weakSelf.videoURL error:nil];
//                                    weakSelf.videoURL = nil;
//                                    [weakSelf cancelBtnfunc:nil];
//
//                                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
//                                }];
//
//                                UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:uploadVC];
//
//                                [weakSelf presentViewController:navVC animated:YES completion:^{
//
//                                }];
//                            });
//                        }
//                    }
//
//                    weakSelf.confirmButton.userInteractionEnabled = NO;
//
//                }];
//            }
//            else
//            {
//                NSLog(@"保存视频失败!");
//                if (self->_isGetCloudRes) {
//                    if (weakSelf.shootCloudCompletionBlock){
//                        weakSelf.shootCloudCompletionBlock(nil);
//                    }
//                }else{
//                    if (weakSelf.shootCompletionBlock){
//                        weakSelf.shootCompletionBlock(nil, 0, nil, nil);
//                    }
//                }
//                [[NSFileManager defaultManager] removeItemAtURL:weakSelf.videoURL error:nil];
//                weakSelf.videoURL = nil;
//                [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
//            }
//
//
//        }];
        
    }
}

/**
 *  编辑按钮
 */
- (IBAction)editBtnFunc:(id)sender
{
    /** 获取缓存编辑对象 */
//    LFAsset *model = [self.models objectAtIndex:self.currentIndex];
    
    LFBaseEditingController *editingVC = nil;
    
    if (self.photoPreviewImageView || currentRecType==0) {
        CustomPhotoEditingController *photoEditingVC = [[CustomPhotoEditingController alloc] init];
        photoEditingVC.cutType = self.cutType;//imagePickerVc.cutType;
        photoEditingVC.aspectWHRatio = self.aspectWHRatio;//imagePickerVc.aspectWHRatio;
        photoEditingVC.customMinZoomScale = self.customMinZoomScale;//imagePickerVc.customMinZoomScale;
        photoEditingVC.allowEditing = YES;//imagePickerVc.allowEditing;

        if (self.editOKButtonTitleColorNormal) {
            photoEditingVC.oKButtonTitleColorNormal = self.editOKButtonTitleColorNormal;
        }
        if (self.editCancelButtonTitleColorNormal) {
            photoEditingVC.cancelButtonTitleColorNormal = self.editCancelButtonTitleColorNormal;
        }
        if (self.editNaviBgColor) {
            photoEditingVC.editNaviBgColor = self.editNaviBgColor;
        }
        if (self.editToolbarBgColor) {
            photoEditingVC.editToolbarBgColor = self.editToolbarBgColor;
        }
        if (self.editToolbarTitleColorNormal) {
            photoEditingVC.editToolbarTitleColorNormal = self.editToolbarTitleColorNormal;
        }
        if (self.editToolbarTitleColorDisabled) {
            photoEditingVC.editToolbarTitleColorDisabled = self.editToolbarTitleColorDisabled;
        }
//        editingVC = photoEditingVC;

        /** 当前显示的图片 */
        UIImage *finalImage = [self cutImageWithView:self.photoPreviewImageView];
        photoEditingVC.editImage = finalImage;
        photoEditingVC.delegate = self;
        editingVC = photoEditingVC;
        
//        if (imagePickerVc.photoEditLabrary) {
//            imagePickerVc.photoEditLabrary(photoEditingVC);
//        }
    } else {
        
        //编辑视频
        LFVideoEditingController *videoEditingVC = [[LFVideoEditingController alloc] init];
        videoEditingVC.minClippingDuration = 3.f;
        videoEditingVC.maxClippingDuration = self.maxRecTime;
        
        // 获取视频的第一帧图片
        UIImage *image = [self thumbnailImageRequestWithVideoUrl:self.videoURL andTime:0.01f];
        
        /** 当前显示的图片 */
        [videoEditingVC setVideoAsset:[AVAsset assetWithURL:self.videoURL] placeholderImage:image];
        
        videoEditingVC.defaultOperationType = LFVideoEditOperationType_clip;
        
        videoEditingVC.delegate = self;
        editingVC = videoEditingVC;
    }
    
    if (editingVC) {
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:editingVC];
        navVC.navigationBarHidden = YES;
        [self presentViewController:navVC animated:YES completion:^{
            
        }];
//        [self.navigationController pushViewController:editingVC animated:NO];
    }
}

#pragma mark - CustomPhotoEditingControllerDelegate
- (void)lf_PhotoEditingController:(CustomPhotoEditingController *)photoEditingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit {
    [photoEditingVC dismissViewControllerAnimated:YES completion:^{
        
    }];
    NSLog(@"lf_PhotoEditingController---didCancelPhotoEdit");
}
- (void)lf_PhotoEditingController:(CustomPhotoEditingController *)photoEditingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit {
    NSLog(@"lf_PhotoEditingController---didFinishPhotoEdit");
    UIImage *finalImage = photoEdit.editPreviewImage;

    float videoRatio = finalImage.size.height /finalImage.size.width; //得到的图片 高/宽

    [self.photoPreviewImageView setFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*videoRatio)];
    self.photoPreviewImageView.image = finalImage;
    self.photoPreviewImageView.center = self.view.center;
    
    if (self.cutType == 0 || self.cutType == 1) {
        [photoEditingVC dismissViewControllerAnimated:YES completion:^{
            [self confirmBtnFunc:nil];
        }];
        
    }else{
        [photoEditingVC dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
    
}

#pragma mark - LFVideoEditingControllerDelegate
- (void)lf_VideoEditingController:(LFVideoEditingController *)videoEditingVC didCancelPhotoEdit:(LFVideoEdit *)videoEdit
{
//    [[self navi] popViewControllerAnimated:NO];
    NSLog(@"lf_VideoEditingController---didCancelPhotoEdit");
    [videoEditingVC dismissViewControllerAnimated:YES completion:^{
        if (self.videoURL) {
            // 播放完成后重复播放
            // 跳到最新的时间点开始播放
            [self.player seekToTime:CMTimeMake(0, 1)];
            [self.player play];
        }
    }];
    
}
- (void)lf_VideoEditingController:(LFVideoEditingController *)videoEditingVC didFinishPhotoEdit:(LFVideoEdit *)videoEdit
{
    NSLog(@"lf_VideoEditingController---didFinishPhotoEdit");
    [videoEditingVC dismissViewControllerAnimated:YES completion:^{
        if (videoEdit != nil) {
            self.videoURL =videoEdit.editFinalURL;
        }
        
        if (self.videoURL == nil)
        {
            return;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.videoURL];
        
        //获取视频总时长
        Float64 duration = CMTimeGetSeconds(asset.duration);
        
        self.currentVideoTimeLength = duration;
        
        self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];

        [self removePlayerItemNotification];
        [self addNotificationWithPlayerItem];
        
        // 播放完成后重复播放
        // 跳到最新的时间点开始播放
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player play];
    }];

//    LFImagePickerController *imagePickerVc = [self navi];
//    if (self.models.count > self.currentIndex) {
//        LFAsset *model = [self.models objectAtIndex:self.currentIndex];
//        /** 缓存对象 */
//        [[LFVideoEditManager manager] setVideoEdit:videoEdit forAsset:model];
//        LFPhotoPreviewVideoCell *cell = [_collectionView visibleCells].firstObject;
//        if (videoEdit.editPreviewImage) { /** 编辑存在 */
//            [cell changeVideoPlayer:[AVAsset assetWithURL:videoEdit.editFinalURL] image:videoEdit.editPreviewImage];
//        } else {
//            [cell changeVideoPlayer:videoEditingVC.asset image:videoEditingVC.placeholderImage];
//        }
//
//        [imagePickerVc popViewControllerAnimated:NO];
//
//        NSTimeInterval duration = videoEdit.editPreviewImage ? videoEdit.duration : model.duration;
//
//        if (imagePickerVc.maxVideosCount > 1) {
//            /** 默认选中编辑后的视频 */
//            if (lf_videoDuration(duration) > imagePickerVc.maxVideoDuration && _selectButton.isSelected) {
//                [self select:_selectButton];
//            } else if (videoEdit.editPreviewImage && !_selectButton.isSelected) {
//                if (lf_videoDuration(duration) <= imagePickerVc.maxVideoDuration) {
//                    [self select:_selectButton];
//                }
//            }
//        }
//    }
}

#pragma mark - 懒加载
- (AVCaptureSession *)captureSession
{
    if (_captureSession == nil)
    {
        _captureSession = [[AVCaptureSession alloc] init];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
        {
            _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    
    return _captureSession;
}

- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue)
    {
        _videoQueue = dispatch_queue_create("XFCameraController", DISPATCH_QUEUE_SERIAL); // dispatch_get_main_queue();
    }
    
    return _videoQueue;
}

- (CMMotionManager *)motionManager
{
    if (!_motionManager)
    {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

#pragma mark - 私有方法

/**
 *  初始化AVCapture会话
 */
- (void)initAVCaptureSession
{
    //1、添加 "视频" 与 "音频" 输入流到session
    [self setupVideo];
    
    [self setupAudio];
    
    //2、添加图片，movie输出流到session
    [self setupCaptureStillImageOutput];
    
    //3、创建视频预览层，用于实时展示摄像头状态
    [self setupCaptureVideoPreviewLayer];
    
    //设置静音状态也可播放声音
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
}

/**
 *  设置视频输入
 */
- (void)setupVideo
{
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    if (!captureDevice)
    {
        NSLog(@"取得后置摄像头时出现问题.");
        
        return;
    }
    
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error)
    {
        NSLog(@"取得设备输入videoInput对象时出错，错误原因：%@", error);
        
        return;
    }
    
    //3、将设备输出添加到会话中
    if ([self.captureSession canAddInput:self.videoInput])
    {
        [self.captureSession addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.captureSession canAddOutput:self.videoOutput])
    {
        [self.captureSession addOutput:self.videoOutput];
    }
}

/**
 *  设置音频录入
 */
- (void)setupAudio
{
    NSError *error = nil;
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    if (error)
    {
        NSLog(@"取得设备输入audioInput对象时出错，错误原因：%@", error);
        
        return;
    }
    if ([self.captureSession canAddInput:self.audioInput])
    {
        [self.captureSession addInput:self.audioInput];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.captureSession canAddOutput:self.audioOutput])
    {
        [self.captureSession addOutput:self.audioOutput];
    }
}

/**
 *  设置图片输出
 */
- (void)setupCaptureStillImageOutput
{
    self.captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{
                                     //                                     AVVideoScalingModeKey:AVVideoScalingModeResizeAspect,
                                     AVVideoCodecKey:AVVideoCodecJPEG
                                     };
    [_captureStillImageOutput setOutputSettings:outputSettings];
    
    if ([self.captureSession canAddOutput:_captureStillImageOutput])
    {
        [self.captureSession addOutput:_captureStillImageOutput];
    }
}

/**
 *  设置预览layer
 */
- (void)setupCaptureVideoPreviewLayer
{
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    
    CALayer *layer = self.view.layer;
    
    _captureVideoPreviewLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;           //填充模式
    
    [layer addSublayer:_captureVideoPreviewLayer];
}

/**
 *  开启会话
 */
- (void)startSession
{
    if (![self.captureSession isRunning])
    {
        [self.captureSession startRunning];
    }
}

/**
 *  停止会话
 */
- (void)stopSession
{
    if ([self.captureSession isRunning])
    {
        [self.captureSession stopRunning];
    }
}

/**
 *  开始拍照录像动画组合
 */
- (void)startAnimationGroup
{
    [self configDefaultUIDisplay];
    
    [self setFocusCursorWithPoint:self.view.center];
    
//    [self tipLabelAnimation];
}

/**
 *  配置默认UI信息
 */
- (void)configDefaultUIDisplay
{
    if (self.photoPreviewImageView)
    {
        [self.photoPreviewImageView removeFromSuperview];
        [self.photoPreviewContainerView removeFromSuperview];
        self.photoPreviewImageView = nil;
        self.photoPreviewContainerView = nil;
    }
    if (self.videoPreviewContainerView)
    {
        [self.player pause];
        self.player = nil;
        self.playerItem = nil;
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
//        self.cameraButton.progressPercentage = 0.0f;
        [self.videoPreviewContainerView removeFromSuperview];
        self.videoPreviewContainerView = nil;
        [[NSFileManager defaultManager] removeItemAtURL:self.videoURL error:nil];
        self.videoURL = nil;
    }
    
    [self.view bringSubviewToFront:self.rotateCameraButton];
    [self.view bringSubviewToFront:self.closeButton];
    [self.view bringSubviewToFront:self.cameraBtn];
    [self.view bringSubviewToFront:self.videoRecBtn];
    [self.view bringSubviewToFront:self.takeButton];
    [self.view bringSubviewToFront:self.recordVideoTopTimeView];
    [self.view bringSubviewToFront:self.recordVideoLeftTimeView];
    [self.view bringSubviewToFront:self.recordVideoRightTimeView];
    [self.rotateCameraButton setHidden:NO];
    [self.closeButton setHidden:NO];
    [self.takeButton setHidden:NO];
    
    if (self.shootType == 0) {
        [self.cameraBtn setHidden:NO];
        [self.videoRecBtn setHidden:NO];
    }
    
//    [self.view bringSubviewToFront:self.tipLabel];
//    [self.tipLabel setAlpha:0];
    
    [self.cancelButton setHidden:YES];
    [self.confirmButton setHidden:YES];
    [self.editButton setHidden:YES];
    
    // 设置拍照按钮
//    if (_cameraButton == nil)
//    {
//        XFCameraButton *cameraButton = [XFCameraButton defaultCameraButton];
//        _cameraButton = cameraButton;
//
//        [self.view addSubview:cameraButton];
//        CGFloat cameraBtnX = (kScreenWidth - cameraButton.bounds.size.width) / 2;
//        CGFloat cameraBtnY = kScreenHeight - cameraButton.bounds.size.height - 60;    //距离底部60
//        cameraButton.frame = CGRectMake(cameraBtnX, cameraBtnY, cameraButton.bounds.size.width, cameraButton.bounds.size.height);
//        [self.view bringSubviewToFront:cameraButton];
//
//        // 设置拍照按钮点击事件
//        __weak __typeof__(self) weakSelf = self;
//        // 配置拍照方法
//        [cameraButton configureTapCameraButtonEventWithBlock:^(UITapGestureRecognizer *tapGestureRecognizer) {
//            [weakSelf takePhotos:tapGestureRecognizer];
//        }];
//        // 配置拍摄方法
//        [cameraButton configureLongPressCameraButtonEventWithBlock:^(UILongPressGestureRecognizer *longPressGestureRecognizer) {
//            [weakSelf longPressCameraButtonFunc:longPressGestureRecognizer];
//        }];
//    }
//    [self.cameraButton setHidden:YES];
//    [self.view bringSubviewToFront:self.cameraButton];
    
    // 对焦imageView
    [self.view bringSubviewToFront:self.focusImageView];
    [self.focusImageView setAlpha:0];
    
    // 监听屏幕方向
    [self startUpdateAccelerometer];
}

/**
 *  提示语动画
 */
- (void)tipLabelAnimation
{
    [self.view bringSubviewToFront:self.tipLabel];
    
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:1.0f delay:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [weakSelf.tipLabel setAlpha:1];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:1.0f delay:3.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            [weakSelf.tipLabel setAlpha:0];
            
        } completion:nil];
        
    }];
}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras)
    {
        if ([camera position] == position)
        {
            return camera;
        }
    }
    return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError *error;
    
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error])
    {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }
    else
    {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

#pragma mark - 拍照功能

/**
 *  拍照方法
 */
- (void)takePhotos:(UITapGestureRecognizer *)tapGestureRecognizer
{
    //根据设备输出获得连接
    __block AVCaptureConnection *captureConnection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
//    [captureConnection setVideoScaleAndCropFactor:self.effectiveScale];
    if (captureConnection.enabled) {
        //根据连接取得设备输出的数据
        [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:imageData];
                
                [self previewPhotoWithImage:image];
                
                captureConnection = nil;
            }
        }];
    }
    
}

/**
 *  预览图片
 */
- (void)previewPhotoWithImage:(UIImage *)image
{
    [self stopUpdateAccelerometer];
    /*
     拍照场景cuttype为0和1时，拍照后直接进入编辑页，编辑页面点完成就上传，点返回就回到拍照页面。（省去了预览功能）
     */
    if (self.cutType == 0 || self.cutType == 1) {
        
        UIImage *finalImage = nil;
        if (self.shootingOrientation == UIDeviceOrientationLandscapeRight)
        {
            finalImage = [self rotateImage:image withOrientation:UIImageOrientationDown];
        }
        else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
        {
            finalImage = [self rotateImage:image withOrientation:UIImageOrientationUp];
        }
        else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            finalImage = [self rotateImage:image withOrientation:UIImageOrientationLeft];
        }
        else
        {
            finalImage = [self rotateImage:image withOrientation:UIImageOrientationRight];
        }
        
        if (!self.photoPreviewImageView) {
            self.photoPreviewImageView = [[UIImageView alloc] init];
        }
        
        float videoRatio = finalImage.size.width / finalImage.size.height; //得到的图片 高/宽
        if (self.shootingOrientation == UIDeviceOrientationLandscapeRight || self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
        {
            CGFloat height = kScreenWidth * videoRatio;
            CGFloat y = (kScreenHeight - height) / 2;
            [self.photoPreviewImageView setFrame:CGRectMake(0, y, kScreenWidth, height)];
        }
        else
        {
            [self.photoPreviewImageView setFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*videoRatio)];
        }
        self.photoPreviewImageView.image = finalImage;
        
        /*
         拍照场景cuttype为0和1时，拍照后直接进入编辑页，编辑页面点完成就上传，点返回就回到拍照页面。（省去了预览功能）
         */
        if (self.cutType == 0 || self.cutType == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self editBtnFunc:nil];
            });
        }
        
        return;
    }
    
//    [self.cameraButton setHidden:YES];
    [self.cameraBtn setHidden:YES];
    [self.videoRecBtn setHidden:YES];
    [self.recordVideoTopTimeView setHidden:YES];
    [self.recordVideoLeftTimeView setHidden:YES];
    [self.recordVideoRightTimeView setHidden:YES];
    [self.takeButton setHidden:YES];
    [self.closeButton setHidden:YES];
    [self.rotateCameraButton setHidden:YES];
    
    UIImage *finalImage = nil;
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationDown];
    }
    else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationUp];
    }
    else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationLeft];
    }
    else
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationRight];
    }

    if (!self.photoPreviewImageView) {
        self.photoPreviewImageView = [[UIImageView alloc] init];
    }
    
    float videoRatio = finalImage.size.width / finalImage.size.height; //得到的图片 高/宽
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight || self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
    {
        CGFloat height = kScreenWidth * videoRatio;
        CGFloat y = (kScreenHeight - height) / 2;
        [self.photoPreviewImageView setFrame:CGRectMake(0, y, kScreenWidth, height)];
    }
    else
    {
        [self.photoPreviewImageView setFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth*videoRatio)];
    }
    self.photoPreviewImageView.image = finalImage;
//    self.photoPreviewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.photoPreviewContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    self.photoPreviewContainerView.backgroundColor = [UIColor blackColor];
    [self.photoPreviewContainerView addSubview:self.photoPreviewImageView];
    [self.view addSubview:self.photoPreviewContainerView];
    self.photoPreviewImageView.center = self.view.center;
    [self.view bringSubviewToFront:self.photoPreviewImageView];
    [self.view bringSubviewToFront:self.cancelButton];
    [self.view bringSubviewToFront:self.confirmButton];
    [self.view bringSubviewToFront:self.editButton];
    [self.cancelButton setHidden:NO];
    [self.confirmButton setHidden:NO];
    [self.editButton setHidden:NO];
}

- (UIImage *)cutImageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - 视频录制

/**
 *  录制视频方法
 */
- (void)longPressCameraButtonFunc:(UILongPressGestureRecognizer *)sender
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return;
    }
    
    //判断用户是否允许访问麦克风权限
    authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return;
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self startVideoRecorder];
            break;
        case UIGestureRecognizerStateCancelled:
            [self stopVideoRecorder];
            break;
        case UIGestureRecognizerStateEnded:
            [self stopVideoRecorder];
            break;
        case UIGestureRecognizerStateFailed:
            [self stopVideoRecorder];
            break;
        default:
            break;
    }
    
}

/**
 *  开始录制视频
 */
- (void)startVideoRecorder
{
    _isShooting = YES;
    self.currentShootingOrientation = _shootingOrientation;
    [self stopUpdateAccelerometer];
    [self.takeButton setBackgroundImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_press"] forState:UIControlStateNormal];
//    [self.cameraButton startShootAnimationWithDuration:START_VIDEO_ANIMATION_DURATION];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(START_VIDEO_ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSURL *url = [NSURL fileURLWithPath:[weakSelf createVideoFilePath]];
        self.videoURL = url;
        
        [self setUpWriter];
        
        [weakSelf timerFired];
        
    });
}

/**
 *  结束录制视频
 */
- (void)stopVideoRecorder
{
    if (_isShooting)
    {
        _isShooting = NO;
        [self.takeButton setBackgroundImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
//        self.cameraButton.progressPercentage = 0.0f;
//        [self.cameraButton stopShootAnimation];
        [self timerStop];
        
        __weak __typeof(self)weakSelf = self;
        if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting)
        {
//            dispatch_async(self.videoQueue, ^{
                [_assetWriter finishWritingWithCompletionHandler:^{
                    weakSelf.canWrite = NO;
                    weakSelf.assetWriter = nil;
                    weakSelf.assetWriterAudioInput = nil;
                    weakSelf.assetWriterVideoInput = nil;
                }];
//            });
        }
        
        if (timeLength < VIDEO_RECORDER_MIN_TIME)
        {
            return;
        }
        
//        [self.cameraButton setHidden:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [weakSelf previewVideoAfterShoot];
            
        });
    }
    else
    {
        // nothing
    }
}

/**
 *  设置写入视频属性
 */
- (void)setUpWriter
{
    if (self.videoURL == nil)
    {
        return;
    }
    
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:nil];
    //写入视频大小
    NSInteger numPixels = kScreenWidth * kScreenHeight;
    
    //每像素比特
    CGFloat bitsPerPixel = 15.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(20),
                                             AVVideoMaxKeyFrameIntervalKey : @(20),
                                             AVVideoAverageBitRateKey:AVCaptureSessionPresetHigh,
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    CGFloat width = kScreenHeight;
    CGFloat height = kScreenWidth;
//    if (iSiPhoneX)
//    {
//        width = kScreenHeight - 146;
//        height = kScreenWidth;
//    }
    //视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                       AVVideoWidthKey : @(width * 2),
                                       AVVideoHeightKey : @(height * 2),
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight)
    {
        _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
    }
    else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
    {
        _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(0);
    }
    else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI + (M_PI / 2.0));
    }
    else
    {
        _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    }
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput])
    {
        [_assetWriter addInput:_assetWriterVideoInput];
    }
    else
    {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    
    if ([_assetWriter canAddInput:_assetWriterAudioInput])
    {
        [_assetWriter addInput:_assetWriterAudioInput];
    }
    else
    {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
    
    _canWrite = NO;
}

- (NSString *)createVideoFilePath
{
    // 创建视频文件的存储路径
    NSString *filePath = [self createVideoFolderPath];
    if (filePath == nil)
    {
        return nil;
    }
    
    NSString *videoType = @".mp4";
    NSString *videoDestDateString = [self createFileNamePrefix];
    NSString *videoFileName = [videoDestDateString stringByAppendingString:videoType];
    
    NSUInteger idx = 1;
    /*We only allow 10000 same file name*/
    NSString *finalPath = [NSString stringWithFormat:@"%@/%@", filePath, videoFileName];
    
    while (idx % 10000 && [[NSFileManager defaultManager] fileExistsAtPath:finalPath])
    {
        finalPath = [NSString stringWithFormat:@"%@/%@_(%lu)%@", filePath, videoDestDateString, (unsigned long)idx++, videoType];
    }
    
    return finalPath;
}

- (NSString *)createVideoFolderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *homePath = NSHomeDirectory();
    
    NSString *tmpFilePath;
    
    if (homePath.length > 0)
    {
        NSString *documentPath = [homePath stringByAppendingString:@"/Documents"];
        if ([fileManager fileExistsAtPath:documentPath isDirectory:NULL] == YES)
        {
            BOOL success = NO;
            
            NSArray *paths = [fileManager contentsOfDirectoryAtPath:documentPath error:nil];
            
            //offline file folder
            tmpFilePath = [documentPath stringByAppendingString:[NSString stringWithFormat:@"/%@", VIDEO_FILEPATH]];
            if ([paths containsObject:VIDEO_FILEPATH] == NO)
            {
                success = [fileManager createDirectoryAtPath:tmpFilePath withIntermediateDirectories:YES attributes:nil error:nil];
                if (!success)
                {
                    tmpFilePath = nil;
                }
            }
            return tmpFilePath;
        }
    }
    
    return false;
}

/**
 *  创建文件名
 */
- (NSString *)createFileNamePrefix
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    
    NSString *destDateString = [dateFormatter stringFromDate:[NSDate date]];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    
    return destDateString;
}

/**
 *  开启定时器
 */
- (void)timerFired
{
    timeLength = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerRecord) userInfo:nil repeats:YES];
}

/**
 *  绿色转圈百分比计算
 */
- (void)timerRecord
{
    if (!_isShooting)
    {
        [self timerStop];
        return ;
    }
    
    // 时间大于VIDEO_RECORDER_MAX_TIME则停止录制
    if (timeLength >= self.maxRecTime)
    {
        [self stopVideoRecorder];
        return;
    }
    
    timeLength += TIMER_INTERVAL;
    
    int time = (int)timeLength;
    if ((timeLength-time) > 0) {
        if (_currentShootingOrientation == UIDeviceOrientationPortrait || self->_shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
            self.recRedTopLab.hidden = YES;
            self.recRedLeftLab.hidden = YES;
            self.recRedRightLab.hidden = YES;
        }
        if (_currentShootingOrientation == UIDeviceOrientationLandscapeLeft) {
            self.recRedTopLab.hidden = YES;
            self.recRedLeftLab.hidden = YES;
            self.recRedRightLab.hidden = YES;
        }
        if (_currentShootingOrientation == UIDeviceOrientationLandscapeRight) {
            self.recRedTopLab.hidden = YES;
            self.recRedLeftLab.hidden = YES;
            self.recRedRightLab.hidden = YES;
        }
    }else{
        if (_currentShootingOrientation == UIDeviceOrientationPortrait || _currentShootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
            self.recRedTopLab.hidden = NO;
            self.recRedLeftLab.hidden = YES;
            self.recRedRightLab.hidden = YES;
        }
        if (_currentShootingOrientation == UIDeviceOrientationLandscapeLeft) {
            self.recRedTopLab.hidden = YES;
            self.recRedLeftLab.hidden = YES;
            self.recRedRightLab.hidden = NO;
        }
        if (_currentShootingOrientation == UIDeviceOrientationLandscapeRight) {
            self.recRedTopLab.hidden = YES;
            self.recRedLeftLab.hidden = NO;
            self.recRedRightLab.hidden = YES;
        }
    }
    
    if (_currentShootingOrientation == UIDeviceOrientationPortrait || _currentShootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.recordVideoTopTimeLab.text = [self getHHMMSSWithSecond:timeLength];
    }
    if (_currentShootingOrientation == UIDeviceOrientationLandscapeLeft) {
        self.recordVideoRightTimeLab.text = [self getHHMMSSWithSecond:timeLength];
    }
    if (_currentShootingOrientation == UIDeviceOrientationLandscapeRight) {
        self.recordVideoLeftTimeLab.text = [self getHHMMSSWithSecond:timeLength];
    }
    
    
    //    NSLog(@"%lf", timeLength / VIDEO_RECORDER_MAX_TIME);
    
//    self.cameraButton.progressPercentage = timeLength / self.maxRecTime;
    
}

- (NSString *)getHHMMSSWithSecond:(NSInteger)second{
    NSString *tmphh = [NSString stringWithFormat:@"%d",(int)(second/60/60)%60];
    if (tmphh.length == 1) {
        tmphh = [NSString stringWithFormat:@"0%@",tmphh];
    }
    
    NSString *tmpmm = [NSString stringWithFormat:@"%d",(int)(second/60)%60];
    if (tmpmm.length == 1) {
        tmpmm = [NSString stringWithFormat:@"0%@",tmpmm];
    }
    NSString *tmpss = [NSString stringWithFormat:@"%d",(int)second%60];
    if (tmpss.length == 1) {
        tmpss = [NSString stringWithFormat:@"0%@",tmpss];
    }
    return [NSString stringWithFormat:@"%@:%@:%@",tmphh,tmpmm,tmpss];
}

/**
 *  停止定时器
 */
- (void)timerStop
{
    if ([self.timer isValid])
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

/**
 *  预览录制的视频
 */
- (void)previewVideoAfterShoot
{
    if (self.videoURL == nil || self.videoPreviewContainerView != nil)
    {
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:self.videoURL];
    
    //获取视频总时长
    Float64 duration = CMTimeGetSeconds(asset.duration);
    
    self.currentVideoTimeLength = duration;
    
    // 初始化AVPlayer
    self.videoPreviewContainerView = [[UIView alloc] init];
    self.videoPreviewContainerView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    self.videoPreviewContainerView.backgroundColor = [UIColor blackColor];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.videoPreviewContainerView.layer addSublayer:self.playerLayer];
    
    // 其余UI布局设置
    [self.view addSubview:self.videoPreviewContainerView];
    [self.view bringSubviewToFront:self.videoPreviewContainerView];
    [self.view bringSubviewToFront:self.cancelButton];
    [self.view bringSubviewToFront:self.confirmButton];
    [self.view bringSubviewToFront:self.editButton];
//    [self.cameraButton setHidden:YES];
    [self.closeButton setHidden:YES];
    [self.cameraBtn setHidden:YES];
    [self.videoRecBtn setHidden:YES];
    [self.takeButton setHidden:YES];
    [self.recordVideoTopTimeView setHidden:YES];
    [self.recordVideoLeftTimeView setHidden:YES];
    [self.recordVideoRightTimeView setHidden:YES];
    [self.rotateCameraButton setHidden:YES];
    [self.cancelButton setHidden:NO];
    [self.confirmButton setHidden:NO];
    [self.editButton setHidden:NO];
    
    
    
    // 重复播放预览视频
    [self addNotificationWithPlayerItem];
    
    // 开始播放
    [self.player play];
}

/**
 *  截取指定时间的视频缩略图
 *
 *  @param timeBySecond 时间点，单位：s
 */
- (UIImage *)thumbnailImageRequestWithVideoUrl:(NSURL *)videoUrl andTime:(CGFloat)timeBySecond
{
    if (self.videoURL == nil)
    {
        return nil;
    }
    
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:videoUrl];
    
    //根据AVURLAsset创建AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    /*截图
     * requestTime:缩略图创建时间
     * actualTime:缩略图实际生成的时间
     */
    NSError *error = nil;
    CMTime requestTime = CMTimeMakeWithSeconds(timeBySecond, 10); //CMTime是表示电影时间信息的结构体，第一个参数表示是视频第几秒，第二个参数表示每秒帧数.(如果要活的某一秒的第几帧可以使用CMTimeMake方法)
    CMTime actualTime;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:requestTime actualTime:&actualTime error:&error];
    if(error)
    {
        NSLog(@"截取视频缩略图时发生错误，错误信息：%@", error.localizedDescription);
        return nil;
    }
    
    CMTimeShow(actualTime);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    UIImage *finalImage = nil;
    if (self.shootingOrientation == UIDeviceOrientationLandscapeRight)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationDown];
    }
    else if (self.shootingOrientation == UIDeviceOrientationLandscapeLeft)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationUp];
    }
    else if (self.shootingOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationLeft];
    }
    else
    {
        finalImage = [self rotateImage:image withOrientation:UIImageOrientationRight];
    }
    
    return finalImage;
}

/**
 *  图片旋转
 */
- (UIImage *)rotateImage:(UIImage *)image withOrientation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation)
    {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

#pragma mark - 截取视频方法

- (void)cropWithVideoUrlStr:(NSURL *)videoUrl start:(CGFloat)startTime end:(CGFloat)endTime completion:(void (^)(NSURL *outputURL, Float64 videoDuration, BOOL isSuccess))completionHandle
{
    AVURLAsset *asset =[[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    //获取视频总时长
    Float64 duration = CMTimeGetSeconds(asset.duration);
    
    if (duration > self.maxRecTime)
    {
        duration = self.maxRecTime;
    }
    
    startTime = 0;
    endTime = duration;
    
    NSString *outputFilePath = [self createVideoFilePath];
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
    {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
        
        NSURL *outputURL = outputFileUrl;
        
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                {
                    NSLog(@"合成失败：%@", [[exportSession error] description]);
                    completionHandle(outputURL, endTime, NO);
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    completionHandle(outputURL, endTime, NO);
                }
                    break;
                case AVAssetExportSessionStatusCompleted:
                {
                    completionHandle(outputURL, endTime, YES);
                }
                    break;
                default:
                {
                    completionHandle(outputURL, endTime, NO);
                } break;
            }
        }];
    }
}

#pragma mark - 预览视频通知
/**
 *  添加播放器通知
 */
-(void)addNotificationWithPlayerItem
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playVideoFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

-(void)removePlayerItemNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playVideoFinished:(NSNotification *)notification
{
    //    NSLog(@"视频播放完成.");
    
    // 播放完成后重复播放
    // 跳到最新的时间点开始播放
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (_isRotatingCamera)
    {
        return;
    }
    
    @autoreleasepool
    {
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo])
        {
            @synchronized(self)
            {
                if (_isShooting)
                {
                    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                }
            }
        }
        
        //音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio])
        {
            @synchronized(self)
            {
                if (_isShooting)
                {
                    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
            }
        }
    }
}


/**
 *  开始写入数据
 */
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL)
    {
        NSLog(@"empty sampleBuffer");
        return;
    }
    
//    CFRetain(sampleBuffer);
//    dispatch_async(self.videoQueue, ^{
        @autoreleasepool
        {
            if (!self.canWrite && mediaType == AVMediaTypeVideo)
            {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            
            //写入视频数据
            if (mediaType == AVMediaTypeVideo)
            {
                if (self.assetWriterVideoInput.readyForMoreMediaData)
                {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success)
                    {
                        @synchronized (self)
                        {
                            [self stopVideoRecorder];
                        }
                    }
                }
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio)
            {
                if (self.assetWriterAudioInput.readyForMoreMediaData)
                {
                    BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                    if (!success)
                    {
                        @synchronized (self)
                        {
                            [self stopVideoRecorder];
                        }
                    }
                }
            }
//            CFRelease(sampleBuffer);
        }
//    });
}

#pragma mark - 摄像头聚焦，与缩放

/**
 *  添加点按手势
 */
- (void)addTapGenstureRecognizerForCamera
{
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    
    pinchGesture.delegate = self;
    
    [self.viewContainer addGestureRecognizer:pinchGesture];
}

/**
 *  点击屏幕，聚焦事件
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 不聚焦的情况：聚焦中，旋转摄像头中，查看录制的视频中，查看照片中
    if (_isFocusing || touches.count == 0 || _isRotatingCamera || _videoPreviewContainerView || _photoPreviewImageView)
    {
        return;
    }
    
    UITouch *touch = nil;
    
    for (UITouch *t in touches)
    {
        touch = t;
        break;
    }
    
    CGPoint point = [touch locationInView:self.viewContainer];;
    
    if (point.y > CGRectGetMaxY(self.tipLabel.frame))
    {
        return;
    }
    
    [self setFocusCursorWithPoint:point];
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
- (void)setFocusCursorWithPoint:(CGPoint)point
{
    self.isFocusing = YES;
    
    self.focusImageView.center = point;
    self.focusImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusImageView.alpha = 1;
    
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self focusWithPoint:cameraPoint];
    
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:1.0 animations:^{
        
        weakSelf.focusImageView.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        
        weakSelf.focusImageView.alpha = 0;
        weakSelf.isFocusing = NO;
        
    }];
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithPoint:(CGPoint)point
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice)
     {
         // 聚焦
         if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
         {
             [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
         }
         if ([captureDevice isFocusPointOfInterestSupported])
         {
             [captureDevice setFocusPointOfInterest:point];
         }
         // 曝光
         if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
         {
             [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
         }
         if ([captureDevice isExposurePointOfInterestSupported])
         {
             [captureDevice setExposurePointOfInterest:point];
         }
     }];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (_isShooting)
    {
        return;
    }
    
    BOOL allTouchesAreOnTheCaptureVideoPreviewLayer = YES;
    
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i)
    {
        CGPoint location = [recognizer locationOfTouch:i inView:self.viewContainer];
        CGPoint convertedLocation = [self.captureVideoPreviewLayer convertPoint:location fromLayer:self.captureVideoPreviewLayer.superlayer];
        if (![self.captureVideoPreviewLayer containsPoint:convertedLocation])
        {
            allTouchesAreOnTheCaptureVideoPreviewLayer = NO;
            break;
        }
    }
    
    if (allTouchesAreOnTheCaptureVideoPreviewLayer)
    {
        CGFloat videoMaxZoomFactor = self.videoInput.device.activeFormat.videoMaxZoomFactor;
        CGFloat maxScaleAndCropFactor = videoMaxZoomFactor<DEFAULT_VIDEO_ZOOM_FACTOR?videoMaxZoomFactor:DEFAULT_VIDEO_ZOOM_FACTOR;
        CGFloat currentScale = self.beginGestureScale * recognizer.scale;
        if ((currentScale > 1.0f) && (currentScale < maxScaleAndCropFactor))
        {
            self.effectiveScale = self.beginGestureScale * recognizer.scale;
            if ((self.effectiveScale < videoMaxZoomFactor) && (self.effectiveScale > 1.0f))
            {
                [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
                    [captureDevice rampToVideoZoomFactor:self.effectiveScale withRate:10.0f];
                }];
            }
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
    {
        self.beginGestureScale = self.effectiveScale;
    }
    
    return YES;
}

#pragma mark - 重力感应相关

/**
 *  开始监听屏幕方向
 */
- (void)startUpdateAccelerometer
{
    if ([self.motionManager isAccelerometerAvailable] == YES)
    {
        //回调会一直调用,建议获取到就调用下面的停止方法，需要再重新开始，当然如果需求是实时不间断的话可以等离开页面之后再stop
        [self.motionManager setAccelerometerUpdateInterval:1.0];
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
         {
             double x = accelerometerData.acceleration.x;
             double y = accelerometerData.acceleration.y;
             if ((fabs(y) + 0.1f) >= fabs(x))
             {
                 //                 NSLog(@"y:%lf", y);
                 if (y >= 0.1f)
                 {
                     // Down
                     NSLog(@"Down");
                     self->_shootingOrientation = UIDeviceOrientationPortraitUpsideDown;
                     if (currentRecType == 1) {
                         if (!self->_isShooting) {
                             self.recordVideoLeftTimeView.hidden = YES;
                             self.recordVideoRightTimeView.hidden = YES;
                             self.recordVideoTopTimeView.hidden = NO;
                             self.recordVideoTopTimeLab.text = @"00:00:00";
                         }
                     }
                 }
                 else
                 {
                     // Portrait
                     NSLog(@"Portrait");
                     self->_shootingOrientation = UIDeviceOrientationPortrait;
                     if (currentRecType == 1) {
                         if (!self->_isShooting) {
                             self.recordVideoLeftTimeView.hidden = YES;
                             self.recordVideoRightTimeView.hidden = YES;
                             self.recordVideoTopTimeView.hidden = NO;
                             self.recordVideoTopTimeLab.text = @"00:00:00";
                         }
                     }
                 }
             }
             else
             {
                 //                 NSLog(@"x:%lf", x);
                 if (x >= 0.1f)
                 {
                     // Right
                     NSLog(@"Right");
                     self->_shootingOrientation = UIDeviceOrientationLandscapeRight;
                     if (currentRecType == 1) {
                         if (!self->_isShooting) {
                             self.recordVideoLeftTimeView.hidden = NO;
                             self.recordVideoRightTimeView.hidden = YES;
                             self.recordVideoTopTimeView.hidden = YES;
                             self.recordVideoLeftTimeLab.text = @"00:00:00";
                         }
                     }
                 }
                 else if (x <= 0.1f)
                 {
                     // Left
                     NSLog(@"Left");
                     self->_shootingOrientation = UIDeviceOrientationLandscapeLeft;
                     if (currentRecType == 1) {
                         if (!self->_isShooting) {
                             self.recordVideoLeftTimeView.hidden = YES;
                             self.recordVideoRightTimeView.hidden = NO;
                             self.recordVideoTopTimeView.hidden = YES;
                             self.recordVideoRightTimeLab.text = @"00:00:00";
                         }
                     }
                 }
                 else
                 {
                     // Portrait
                     NSLog(@"Portrait");
                     self->_shootingOrientation = UIDeviceOrientationPortrait;
                     if (currentRecType == 1) {
                         if (!self->_isShooting) {
                             self.recordVideoLeftTimeView.hidden = YES;
                             self.recordVideoRightTimeView.hidden = YES;
                             self.recordVideoTopTimeView.hidden = NO;
                             self.recordVideoTopTimeLab.text = @"00:00:00";
                         }
                     }
                 }
             }
         }];
    }
}

/**
 *  停止监听屏幕方向
 */
- (void)stopUpdateAccelerometer
{
    if ([self.motionManager isAccelerometerActive] == YES)
    {
        [self.motionManager stopAccelerometerUpdates];
        _motionManager = nil;
    }
}

#pragma mark - 判断是否有权限

/**
 *  请求权限
 */
- (void)requestAuthorizationForVideo
{
    __weak __typeof__(self) weakSelf = self;
    
    // 请求相机权限
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus != AVAuthorizationStatusAuthorized)
    {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        if (appName == nil)
        {
            appName = @"APP";
        }
        NSString *message = [NSString stringWithFormat:@"允许%@访问你的相机？", appName];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                [[UIApplication sharedApplication] openURL:url];
            }
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alertController addAction:okAction];
        [alertController addAction:setAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    // 请求麦克风权限
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioAuthStatus != AVAuthorizationStatusAuthorized)
    {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        if (appName == nil)
        {
            appName = @"APP";
        }
        NSString *message = [NSString stringWithFormat:@"允许%@访问你的麦克风？", appName];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url])
            {
                [[UIApplication sharedApplication] openURL:url];
            }
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alertController addAction:okAction];
        [alertController addAction:setAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    
}

- (void)requestAuthorizationForPhotoLibrary
{
    __weak __typeof__(self) weakSelf = self;
    
    // 请求照片权限
    [XFPhotoLibraryManager requestALAssetsLibraryAuthorizationWithCompletion:^(Boolean isAuth) {
        
        if (!isAuth)
        {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            
            NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            if (appName == nil)
            {
                appName = @"APP";
            }
            NSString *message = [NSString stringWithFormat:@"允许%@访问你的相册？", appName];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:message preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
            
            UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url])
                {
                    [[UIApplication sharedApplication] openURL:url];
                }
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:setAction];
            
            [weakSelf presentViewController:alertController animated:YES completion:nil];
            
        }
    }];
}

#pragma mark 视频压缩
/**
 *  @author lincf, 16-06-15 13:06:26
 *
 *  视频压缩并缓存压缩后视频 (将视频格式变为mp4)
 *
 *  @param inputURL   压缩视频路径
 *  @param presetName 压缩预设名称 nil则默认为AVAssetExportPresetMediumQuality
 *  @param completion 回调压缩后视频路径，可以复制或剪切
 */
- (void)convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                              outputURL:(NSURL*)outputURL
                        completeHandler:(void (^)(NSString *path,BOOL isSuccess))completion {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCompleted:{
                NSLog(@"AVAssetExportSessionStatusCompleted");
                CGFloat videoSize = [self getFileSize:[outputURL path]];
                NSLog(@"压缩处理后的视频时长：%@",[NSString stringWithFormat:@"%f s", [self getVideoLength:outputURL]]);
                NSLog(@"压缩处理后的视频大小：%@", [NSString stringWithFormat:@"%.2f MB", videoSize]);
                // 导出完成后再赋值
                NSString *_videoPath = [outputURL path];
                if (completion) {
                    completion(_videoPath,YES);
                }
            }
                break;
            case AVAssetExportSessionStatusFailed:{
                NSLog(@"AVAssetExportSessionStatusFailed");
                if (completion) {
                    completion(@"",NO);
                }
            }
                break;
        }
    }];
}

// 获取视频文件的时长。
- (CGFloat)getVideoLength:(NSURL *)URL {
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:URL];
    CMTime time = [avUrl duration];
    int second = ceil(time.value / time.timescale);
    return second;
}

// 获取文件的大小，返回的是单位是MB。
- (CGFloat)getFileSize:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        // 获取文件的属性
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024/1024;
    } else {
        NSLog(@"没有找到相关文件");
    }
    return filesize;
}

#pragma mark - private
- (void)showProgressHUDText:(NSString *)text isTop:(BOOL)isTop needProcess:(BOOL)needProcess
{
    [self hideProgressHUD];
    
    if (!_progressHUD) {
        _progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        [_progressHUD setBackgroundColor:[UIColor clearColor]];
        _progressHUD.frame = [UIScreen mainScreen].bounds;
        
        _HUDContainer = [[UIView alloc] init];
        _HUDContainer.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width - 120) / 2, ([[UIScreen mainScreen] bounds].size.height - 90) / 2, 120, 90);
        _HUDContainer.layer.cornerRadius = 8;
        _HUDContainer.clipsToBounds = YES;
        _HUDContainer.backgroundColor = [UIColor darkGrayColor];
        _HUDContainer.alpha = 0.7;
        
        _HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        
        _HUDLabel = [[UILabel alloc] init];
        _HUDLabel.frame = CGRectMake(0,40, 120, 50);
        _HUDLabel.textAlignment = NSTextAlignmentCenter;
        _HUDLabel.font = [UIFont systemFontOfSize:15];
        _HUDLabel.textColor = [UIColor whiteColor];
        
        [_HUDContainer addSubview:_HUDLabel];
        [_HUDContainer addSubview:_HUDIndicatorView];
        [_progressHUD addSubview:_HUDContainer];
    }
    
    _HUDLabel.text = text;
    
    [_HUDIndicatorView startAnimating];
    UIView *view = isTop ? [[UIApplication sharedApplication] keyWindow] : self.view;
    [view addSubview:_progressHUD];
}

- (void)showProgressHUDText:(NSString *)text
{
    [self showProgressHUDText:text isTop:NO needProcess:NO];
}

- (void)showProgressHUD
{
    [self showProgressHUDText:@"视频转码压缩中" isTop:NO needProcess:NO];
}

- (void)hideProgressHUD {
    if (_progressHUD) {
        [_HUDIndicatorView stopAnimating];
        [_progressHUD removeFromSuperview];
    }
}

- (void)showProgressVideoHUD
{
    [self showProgressHUDText:nil isTop:NO needProcess:YES];
}

#pragma mark 按钮操作
- (IBAction)videoRecBtn:(id)sender {
    currentRecType = 1;
    [self.takeButton setBackgroundImage:[NSBundle lf_MediaPickerUploadImage:@"btn_red_normal"] forState:UIControlStateNormal];
    [self.videoRecBtn setTitleColor:[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1] forState:UIControlStateNormal];
    [self.cameraBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if (self->_shootingOrientation == UIDeviceOrientationPortrait || self->_shootingOrientation == UIDeviceOrientationPortraitUpsideDown) {
        self.recordVideoLeftTimeView.hidden = YES;
        self.recordVideoRightTimeView.hidden = YES;
        self.recordVideoTopTimeView.hidden = NO;
        self.recordVideoTopTimeLab.text = @"00:00:00";
        self.recordVideoLeftTimeLab.text = @"00:00:00";
        self.recordVideoRightTimeLab.text = @"00:00:00";
    }
    if (self->_shootingOrientation == UIDeviceOrientationLandscapeLeft) {
        self.recordVideoLeftTimeView.hidden = YES;
        self.recordVideoRightTimeView.hidden = NO;
        self.recordVideoTopTimeView.hidden = YES;
        self.recordVideoTopTimeLab.text = @"00:00:00";
        self.recordVideoLeftTimeLab.text = @"00:00:00";
        self.recordVideoRightTimeLab.text = @"00:00:00";
    }
    if (self->_shootingOrientation == UIDeviceOrientationLandscapeRight) {
        self.recordVideoLeftTimeView.hidden = NO;
        self.recordVideoRightTimeView.hidden = YES;
        self.recordVideoTopTimeView.hidden = YES;
        self.recordVideoTopTimeLab.text = @"00:00:00";
        self.recordVideoLeftTimeLab.text = @"00:00:00";
        self.recordVideoRightTimeLab.text = @"00:00:00";
    }
}

- (IBAction)cameraBtn:(id)sender {
    if (_isShooting) {
        __weak __typeof__(self) weakSelf = self;
        NSString *message = [NSString stringWithFormat:@"您正在录制视频，请先停止录制"];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:okAction];
        [weakSelf presentViewController:alertController animated:YES completion:nil];
        return;
    }
    currentRecType = 0;
    [self.takeButton setBackgroundImage:[NSBundle lf_MediaPickerUploadImage:@"btn_camera_write"] forState:UIControlStateNormal];
    [self.videoRecBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cameraBtn setTitleColor:[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1] forState:UIControlStateNormal];
    
    self.recordVideoLeftTimeView.hidden = YES;
    self.recordVideoRightTimeView.hidden = YES;
    self.recordVideoTopTimeView.hidden = YES;
    self.recordVideoTopTimeLab.text = @"00:00:00";
    self.recordVideoLeftTimeLab.text = @"00:00:00";
    self.recordVideoRightTimeLab.text = @"00:00:00";
}

- (IBAction)takeButton:(id)sender {
    if (currentRecType == 0) { //拍照
        [self takePhotos:nil];
    }else if (currentRecType == 1){//视频
        if (_isShooting) {
            [self stopVideoRecorder];
        }else{
            [self startVideoRecorder];
        }
    }
}

//- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
//    return UIInterfaceOrientationMaskPortrait;
//}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    //    return [self.viewControllers.lastObject supportedInterfaceOrientations];
    return UIInterfaceOrientationMaskPortrait;
    
}

//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    //    return [self.viewControllers.lastObject preferredInterfaceOrientationForPresentation];
//    return UIInterfaceOrientationMaskPortrait;
//}

@end
