//
//  CustomUploadCell.m
//  HelloCordova
//
//  Created by haoqi on 2019/7/24.
//

#import "CustomUploadCell.h"
#import <AVFoundation/AVFoundation.h>
#import "NSBundle+LFImagePicker.h"

@interface CustomUploadCell ()
{
    NSString *_mediaId;
}

@property (nonatomic, weak) UIView *bgView;

@property (nonatomic, weak) UIImageView *leftImageView;
@property (nonatomic, weak) UILabel *titleLab;
@property (nonatomic, weak) UILabel *uploadProgressLab;
@property (nonatomic, weak) UIImageView *uploadSucImgView;
@property (nonatomic, weak) UIProgressView *progressView;
@end

@implementation CustomUploadCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/**
 设置cell值显示
 
 @param result 图片资源信息
 {
 url
 name
 type:1 图片 2 音频
 image
 }
 @param cosMsg cos签名信息
 {
 bucket://存储桶
 region：//存储区域
 authorization：//签名
 keys:
 }
 */
-(void)setCellMsgWithResultImage:(NSDictionary *)result cosMsg:(NSDictionary*)cosMsg {
    //给背景视图添加阴影
    [self addShadowToView:self.bgView withColor:[UIColor lightGrayColor]];
    self.progressView.progress = 0.0;
    
    self.uploadProgressLab.text = @"0%";
    self.uploadSucImgView.hidden = YES;
    self.leftImageView.image = [NSBundle lf_MediaPickerUploadImage:@"ic_muc_flie_type_i"];
    self.titleLab.text = @"图片文件上传中";
    self.sendStatus = 0;
    
    NSString *pathStr = [NSString getSafeStrWithStr:result[@"url"] showNull:@""];
    NSString *bucket = [NSString getSafeStrWithStr:cosMsg[@"bucket"] showNull:@""];
    NSArray *keys = [NSArray arrayWithArray:cosMsg[@"keys"]];
    
    self.leftImageView.image = [UIImage imageWithContentsOfFile:pathStr];
    
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    NSURL* url = [NSURL fileURLWithPath:pathStr] /*对象的URL*/;
    if (keys.count > self.tag) {
        put.object = keys[self.tag];
    }
    put.bucket = bucket;
    put.body =  url;
    
    __weak __typeof__(self) weakSelf = self;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = (float)totalBytesSent/(float)totalBytesExpectedToSend;
            weakSelf.uploadProgressLab.text = [NSString stringWithFormat:@"%.f%%",self.progressView.progress*100];
            weakSelf.uploadProgressLab.hidden = NO;
            weakSelf.uploadSucImgView.hidden = YES;
            weakSelf.sendStatus = 1;
        });
    }];
    [put setFinishBlock:^(id outputObject, NSError* error) {
        //可以从 outputObject 中获取 response 中 etag 或者自定义头部等信息（更多头部信息可以通过打印 outputObject 查看）
        NSLog(@"outputObject....%@", outputObject);
        QCloudUploadObjectResult *result = outputObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error==nil) {
                weakSelf.sendStatus = 2;
                weakSelf.uploadProgressLab.text = @"";
                weakSelf.uploadProgressLab.hidden = YES;
                weakSelf.uploadSucImgView.hidden = NO;
                
                weakSelf.titleLab.text = @"图片文件上传完成";
                
                if (weakSelf.photo_AudioCompletionBlock) {
                    weakSelf.photo_AudioCompletionBlock(result, self.tag, @"");
                }
                
            }else{
                NSLog(@"uploadError 信息[%@]", error.localizedDescription);
                weakSelf.titleLab.text = @"图片文件上传失败";
                weakSelf.sendStatus = 3;
                if (weakSelf.photo_AudioCompletionBlock) {
                    weakSelf.photo_AudioCompletionBlock(nil, self.tag, error.localizedDescription);
                }
            }
        });
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
}

/**
 设置cell值显示
 
 @param result 音频资源信息
 @param cosMsg cos签名信息
 {
 bucket://存储桶
 region：//存储区域
 authorization：//签名
 keys:
 }
 */
-(void)setCellMsgWithResultAudio:(LFResultVideo *)result cosMsg:(NSDictionary*)cosMsg {
    //给背景视图添加阴影
    [self addShadowToView:self.bgView withColor:[UIColor lightGrayColor]];
    self.progressView.progress = 0.0;
    
    self.uploadProgressLab.text = @"0%";
    self.uploadSucImgView.hidden = YES;
    self.leftImageView.image = [NSBundle lf_MediaPickerUploadImage:@"ic_muc_flie_type_y"];
    self.titleLab.text = @"语音文件上传中";
    self.sendStatus = 0;
    
    LFResultVideo *resultAudio = (LFResultVideo *)result;
    NSString *pathStr = resultAudio.url.path;
    
    NSString *bucket = [NSString getSafeStrWithStr:cosMsg[@"bucket"] showNull:@""];
    NSArray *keys = [NSArray arrayWithArray:cosMsg[@"keys"]];
    
    QCloudCOSXMLUploadObjectRequest* put = [QCloudCOSXMLUploadObjectRequest new];
    NSURL* url = [NSURL fileURLWithPath:pathStr] /*对象的URL*/;
    
    if (keys.count > self.tag) {
        put.object = keys[self.tag];
    }
    put.bucket = bucket;
    put.body =  url;
    
    __weak __typeof__(self) weakSelf = self;
    [put setSendProcessBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"upload %lld totalSend %lld aim %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = (float)totalBytesSent/(float)totalBytesExpectedToSend;
            weakSelf.uploadProgressLab.text = [NSString stringWithFormat:@"%.f%%",self.progressView.progress*100];
            weakSelf.uploadProgressLab.hidden = NO;
            weakSelf.uploadSucImgView.hidden = YES;
            weakSelf.sendStatus = 1;
        });
        
    }];
    [put setFinishBlock:^(id outputObject, NSError* error) {
        //可以从 outputObject 中获取 response 中 etag 或者自定义头部等信息（更多头部信息可以通过打印 outputObject 查看）
        QCloudUploadObjectResult *result = outputObject;
        NSLog(@"outputObject....%@", outputObject);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error==nil) {
                weakSelf.sendStatus = 2;
                weakSelf.uploadProgressLab.text = @"";
                weakSelf.uploadProgressLab.hidden = YES;
                weakSelf.uploadSucImgView.hidden = NO;
                
                weakSelf.titleLab.text = @"音频文件上传完成";
                if (weakSelf.photo_AudioCompletionBlock) {
                    weakSelf.photo_AudioCompletionBlock(result, self.tag, @"");
                }
            }else{
                NSLog(@"uploadError 信息[%@]", error.localizedDescription);
                weakSelf.titleLab.text = @"音频文件上传失败";
                weakSelf.sendStatus = 3;
                if (weakSelf.photo_AudioCompletionBlock) {
                    weakSelf.photo_AudioCompletionBlock(nil, self.tag, error.localizedDescription);
                }
            }
        });
    }];
    [[QCloudCOSTransferMangerService defaultCOSTransferManager] UploadObject:put];
}

/**
 设置cell值显示
 
 @param result 视频资源信息
 @param videoSign 上传视频签名
 @param type 类型 0：图片 1：语音 2：视频
 */
-(void)setCellMsgWithResultVideo:(LFResultVideo *)result {
    //给背景视图添加阴影
    [self addShadowToView:self.bgView withColor:[UIColor lightGrayColor]];
    self.progressView.progress = 0.0;
    
    if (_videoPublish == nil) {
        _videoPublish = [[TXUGCPublish alloc] initWithUserID:@"independence_ios"];
        // [_videoPublish setAppId:1234567];
        _videoPublish.delegate = self;
    }
    
    
    self.titleLab.text = @"视频文件上传中";
    self.uploadProgressLab.text = @"0%";
    self.uploadSucImgView.hidden = YES;
    self.sendStatus = 0;
    LFResultVideo *resultVideo = (LFResultVideo *)result;
    
    self.leftImageView.image = [NSBundle lf_MediaPickerUploadImage:@"ic_muc_flie_type_v"];
    // 获取视频的第一帧图片
    if (resultVideo.coverImage) {
        self.leftImageView.image = resultVideo.coverImage;
    }else{
        self.leftImageView.image = [self thumbnailImageRequestWithVideoUrl:resultVideo.url andTime:0.01f];
    }
    
    NSNumber *orgId = [[NSUserDefaults standardUserDefaults] objectForKey:orgIdKey_plugin];
    [TCHttpUtil asyncSendHttpRequest:@"videoSign" httpServerAddr:[[NSUserDefaults standardUserDefaults] objectForKey:serverUrlKey_plugin] HTTPMethod:@"POST" param:@{@"orgId":orgId} handler:^(int result, NSDictionary *resultDict) {
        if (result == 0 && resultDict){
            NSString *videoSign = [NSString getSafeStrWithStr:resultDict[@"sign"] showNull:@""];
            self->_mediaId = [NSString getSafeStrWithStr:resultDict[@"mediaId"] showNull:@""];
            
            TXPublishParam *publishParam = [[TXPublishParam alloc] init];
            publishParam.signature  = videoSign;
            publishParam.coverPath = nil;
            publishParam.videoPath  = resultVideo.url.path;
            
            [self->_videoPublish publishVideo:publishParam];
            
        } else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频上传签名获取失败"
                                                                message:[NSString stringWithFormat:@"错误码：%d",result]
                                                               delegate:self
                                                      cancelButtonTitle:@"知道了"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}

+ (CGFloat)cellHeight
{
    return 95.f;
}

#pragma mark - TXVideoPublishListener
- (void)onPublishProgress:(NSInteger)uploadBytes totalBytes:(NSInteger)totalBytes {
    self.progressView.progress = (float)uploadBytes/totalBytes;
    self.uploadProgressLab.text = [NSString stringWithFormat:@"%.f%%",self.progressView.progress*100];
    self.uploadProgressLab.hidden = NO;
    self.uploadSucImgView.hidden = YES;
    self.sendStatus = 1;
    NSLog(@"onPublishProgress [%ld/%ld]", uploadBytes, totalBytes);
}

- (void)onPublishComplete:(TXPublishResult*)result {
    NSString *string = [NSString stringWithFormat:@"上传完成，错误码[%d]，信息[%@]", result.retCode, result.retCode == 0? result.videoURL: result.descMsg];
//    [self showErrorMessage:string];
    NSLog(@"uploadError [%@]", string);
    if (result.retCode == 0) {
        self.sendStatus = 2;
        self.uploadProgressLab.text = @"";
        self.uploadProgressLab.hidden = YES;
        self.uploadSucImgView.hidden = NO;
        
        self.titleLab.text = @"视频文件上传完成";
        
        if (self.videoCompletionBlock) {
            self.videoCompletionBlock(result, _mediaId, self.tag, @"");
        }
    }else{
        NSLog(@"uploadError 信息[%@]", result.descMsg);
        self.titleLab.text = @"视频文件上传失败";
        self.sendStatus = 3;
        if (self.videoCompletionBlock) {
            self.videoCompletionBlock(nil, _mediaId, self.tag, result.descMsg);
        }
    }
    NSLog(@"onPublishComplete [%d/%@]", result.retCode, result.retCode == 0? result.videoURL: result.descMsg);
}


#pragma mark - 懒加载

- (UIView *)bgView {
    if (_bgView == nil) {
        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [UIColor whiteColor];
        bgView.layer.cornerRadius = 8;
//        bgView.layer.masksToBounds = YES;
        bgView.frame = CGRectMake(10, 10, C_SCREEN_WIDTH-20, 80);
        [self.contentView addSubview:bgView];
        _bgView = bgView;
    }
    return _bgView;
}

- (UIImageView *)leftImageView {
    if (_leftImageView == nil) {
        UIImageView *leftImageView = [[UIImageView alloc] init];
        leftImageView.contentMode = UIViewContentModeScaleAspectFit;
        leftImageView.clipsToBounds = YES;
        leftImageView.frame = CGRectMake(15, 10, 60, 60);
        [self.bgView addSubview:leftImageView];
        _leftImageView = leftImageView;
    }
    return _leftImageView;
}

- (UILabel *)titleLab {
    if (_titleLab == nil) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        titleLabel.frame = CGRectMake(CGRectGetMaxX(self.leftImageView.frame)+20, CGRectGetHeight(self.bgView.frame)/2-20, CGRectGetWidth(self.bgView.frame) - CGRectGetMaxX(self.leftImageView.frame)-20 -15-45, 20);
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.bgView addSubview:titleLabel];
        _titleLab = titleLabel;
    }
    return _titleLab;
}

- (UILabel *)uploadProgressLab {
    if (_uploadProgressLab == nil) {
        UILabel *uploadProgressLab = [[UILabel alloc] init];
        uploadProgressLab.font = [UIFont boldSystemFontOfSize:14];
        uploadProgressLab.frame = CGRectMake(CGRectGetMaxX(self.titleLab.frame)+5, CGRectGetHeight(self.bgView.frame)/2-20, 40, 20);
        uploadProgressLab.textColor = [UIColor lightGrayColor];
        uploadProgressLab.textAlignment = NSTextAlignmentRight;
        [self.bgView addSubview:uploadProgressLab];
        _uploadProgressLab = uploadProgressLab;
    }
    return _uploadProgressLab;
}

- (UIImageView *)uploadSucImgView {
    if (_uploadSucImgView == nil) {
        UIImageView *uploadSucImgView = [[UIImageView alloc] init];
        uploadSucImgView.contentMode = UIViewContentModeScaleAspectFit;
        uploadSucImgView.clipsToBounds = YES;
        uploadSucImgView.frame = CGRectMake(CGRectGetMaxX(self.titleLab.frame)+25, CGRectGetHeight(self.bgView.frame)/2-20, 20, 20);
        uploadSucImgView.image = [NSBundle lf_MediaPickerUploadImage:@"uploadok"];
        [self.bgView addSubview:uploadSucImgView];
        _uploadSucImgView = uploadSucImgView;
    }
    return _uploadSucImgView;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        //进度视图
        //实例化一个进度条，有两种样式，一种是UIProgressViewStyleBar一种是UIProgressViewStyleDefault，然并卵-->>几乎无区别
        UIProgressView *progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
        //设置的高度对进度条的高度没影响，整个高度=进度条的高度，进度条也是个圆角矩形
        progressView.frame=CGRectMake(CGRectGetMaxX(self.leftImageView.frame)+20, CGRectGetHeight(self.bgView.frame)/2+10, CGRectGetWidth(self.bgView.frame) - CGRectGetMaxX(self.leftImageView.frame)-20 -15, 10);
        //设置进度条颜色
        progressView.trackTintColor=[UIColor colorWithRed:220.f/255.f green:221.f/255.f blue:222.f/255.f alpha:1];
        //设置进度条上进度的颜色
        progressView.progressTintColor=[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1];
        //设置进度条的背景图片
//        progressView.trackImage = [UIImage imageNamed:@"中间灰色周围黑色"];
        //设置进度条上进度的背景图片
        //    progressBarView.progressImage = [NSBundle lf_MediaPickerUploadImage:@"pic_yinlang_blue"];
        //由于pro的高度不变 使用放大的原理让其改变
//        progressView.transform = CGAffineTransformMakeScale(1.0f, 10.0f);
        //自己设置的一个值 和进度条作比较 其实为了实现动画进度
        progressView.progress= 0.0;
        [self.bgView addSubview:progressView];
        _progressView = progressView;
    }
    return _progressView;
}

/*给视图添加阴影效果*/
- (void)addShadowToView:(UIView *)theView withColor:(UIColor *)theColor {
    // 阴影颜色
    theView.layer.shadowColor = theColor.CGColor;
    // 阴影偏移，默认(0, -3)
    theView.layer.shadowOffset = CGSizeMake(0,0);
    // 阴影透明度，默认0
    theView.layer.shadowOpacity = 0.8;
    // 阴影半径，默认3
    theView.layer.shadowRadius = 8;
    
}

/**
 根据状态显示cell视图
 
 @param status 上传状态 0：未发送 1：发送中 2：发送成功 3：发送失败
 @param fileType 文件类型 0：图片 1：音频 2：视频
 */
-(void)setCellShowViewWithStatus:(NSInteger)status fileType:(NSInteger)fileType {
    NSString *titleStr = @"";
    if (fileType == 0) {
        titleStr = @"图片文件上传";
    }else if (fileType == 1) {
        titleStr = @"音频文件上传";
    }else if (fileType == 2) {
        titleStr = @"视频文件上传";
    }
    
    if (status == 0) {
        self.progressView.progress = 0.0;
        self.uploadProgressLab.text = @"0%";
        self.uploadProgressLab.hidden = NO;
        self.uploadSucImgView.hidden = YES;
        self.titleLab.text = [titleStr stringByAppendingString:@"中"];
    }else if (status == 1) {
        self.uploadProgressLab.hidden = NO;
        self.uploadSucImgView.hidden = YES;
        self.titleLab.text = [titleStr stringByAppendingString:@"中"];
    }else if (status == 2) {
        self.progressView.progress = 1;
        self.uploadProgressLab.text = @"100%";
        self.uploadProgressLab.hidden = YES;
        self.uploadSucImgView.hidden = NO;
        self.titleLab.text = [titleStr stringByAppendingString:@"完成"];
    }else if (status == 3) {
        self.progressView.progress = 0.0;
        self.uploadProgressLab.text = @"0%";
        self.uploadProgressLab.hidden = NO;
        self.uploadSucImgView.hidden = YES;
        self.titleLab.text = [titleStr stringByAppendingString:@"失败"];
    }
}

#pragma mark 获取视频第一帧图片
/**
 *  截取指定时间的视频缩略图
 *
 *  @param timeBySecond 时间点，单位：s
 */
- (UIImage *)thumbnailImageRequestWithVideoUrl:(NSURL *)videoUrl andTime:(CGFloat)timeBySecond
{
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
    
    return image;
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

@end
