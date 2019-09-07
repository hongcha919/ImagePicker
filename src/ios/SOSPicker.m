//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import "SOSPicker.h"

#import "LFImagePickerController.h"
#import "AudioRecordVC.h"
#import "XFCameraController.h"
#import "UIImage+LF_Format.h"
#import "LFAssetManager.h"
#import "LFAssetManager+CreateMedia.h"
#import "NSString+LFMECoreText.h"
#import "PublicParamsKey.h"
//#import <MediaPickerUpload/MediaPickerUpload.h>


#define CDV_PHOTO_PREFIX @"cdv_photo_"

typedef enum : NSUInteger {
    FILE_URI = 0,
    BASE64_STRING = 1
} SOSPickerOutputType;

@interface SOSPicker () <LFImagePickerControllerDelegate>
@end

@implementation SOSPicker

@synthesize callbackId;

- (void) hasReadPermission:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) requestReadPermission:(CDVInvokedUrlCommand *)command {
    // [PHPhotoLibrary requestAuthorization:]
    // this method works only when it is a first time, see
    // https://developer.apple.com/library/ios/documentation/Photos/Reference/PHPhotoLibrary_Class/

    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        NSLog(@"Access has been granted.");
    } else if (status == PHAuthorizationStatusDenied) {
        NSLog(@"Access has been denied. Change your setting > this app > Photo enable");
    } else if (status == PHAuthorizationStatusNotDetermined) {
        // Access has not been determined. requestAuthorization: is available
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
    } else if (status == PHAuthorizationStatusRestricted) {
        NSLog(@"Access has been restricted. Change your setting > Privacy > Photo enable");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getPictures:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    if (!options || options.count == 0) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数不能为空！"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    //处理保存上传公共参数
    [self dealPublicUploadParams:options];
    
    //输出格式：0.文件绝对路径 1.BASE64_STRING
    self.outputType = [[options objectForKey:@"outputType"] integerValue];
    //最多选择个数
    self.maximumImagesCount = [[options objectForKey:@"maximumImagesCount"] integerValue];
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];
    //图片裁剪形状(1圆形;2正方形;3矩形)
    self.cutType = [[options objectForKey:@"cutType"] integerValue];
    NSInteger cutWidth = [[options objectForKey:@"cutWidth"] integerValue];
    NSInteger cutHeigth = [[options objectForKey:@"cutHeigth"] integerValue];
    
    self.callbackId = command.callbackId;
    [self launchImagePicker:LFPickingMediaTypePhoto maximumImagesCount:self.maximumImagesCount maximumVideosCount:1 cutType:self.cutType cutWidth:cutWidth cutHeigth:cutHeigth options:options];
}

- (void) getAudio:(CDVInvokedUrlCommand *)command {
    
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    if (!options || options.count == 0) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数不能为空！"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    self.callbackId = command.callbackId;
    
    //处理保存上传公共参数
    [self dealPublicUploadParams:options];
    
    AudioRecordVC *audioVC = [[AudioRecordVC alloc] init];
    if (options[@"duration"] && [options[@"duration"] intValue] >0) {
        audioVC.maxRecTime = [options[@"duration"] intValue];
    }else{
        audioVC.maxRecTime = 60;
    }
    audioVC.isGetCloudRes = YES;
    audioVC.backButtonClickBlock = ^{

    };
    audioVC.doneButtonClickBlock = ^(NSMutableArray * _Nonnull resultArray) {
        NSLog(@"resultArray....%@", resultArray);
        CDVPluginResult* result  = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"medias":resultArray}];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    };
    self.callbackId = command.callbackId;
    [self.viewController presentViewController:audioVC animated:YES completion:^{
        
    }];
}

- (void) getVideos:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    if (!options || options.count == 0) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数不能为空！"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    //处理保存上传公共参数
    [self dealPublicUploadParams:options];
    
    NSInteger maxVideoCount = 1;
    if (options[@"maximumVideosCount"] && [options[@"maximumVideosCount"] integerValue] > 0) {
        maxVideoCount =  [options[@"maximumVideosCount"] integerValue];
    }
    
    self.callbackId = command.callbackId;
    [self launchImagePicker:LFPickingMediaTypeVideo maximumImagesCount:1 maximumVideosCount:maxVideoCount cutType:self.cutType cutWidth:0 cutHeigth:0 options:options];
}

/**
 拍照摄像

 @param command <#command description#>
 @param type <#type description#>
 */
- (void) shootPhoto_Video:(CDVInvokedUrlCommand *)command{
    self.callbackId = command.callbackId;
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    if (!options || options.count == 0) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数不能为空！"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    //处理保存上传公共参数
    [self dealPublicUploadParams:options];
    
    //输出格式：0.文件绝对路径 1.BASE64_STRING
    self.outputType = [[options objectForKey:@"outputType"] integerValue];
    //最多选择个数
    self.maximumImagesCount = [[options objectForKey:@"maximumImagesCount"] integerValue];
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];
    //图片裁剪形状(1圆形;2正方形;3矩形)
    self.cutType = [[options objectForKey:@"cutType"] integerValue];
    NSInteger cutWidth = [[options objectForKey:@"cutWidth"] integerValue];
    NSInteger cutHeigth = [[options objectForKey:@"cutHeigth"] integerValue];
    
    
    
    XFCameraController *cameraController = [XFCameraController defaultCameraController];
    if (options[@"duration"] && [options[@"duration"] doubleValue] >0) {
        cameraController.maxRecTime = [options[@"duration"] doubleValue];
    }else{
        cameraController.maxRecTime = 60;
    }
    cameraController.isGetCloudRes = YES;
    if (options[@"customMinZoomScale"] && [options[@"customMinZoomScale"] doubleValue] >0) {
        cameraController.customMinZoomScale = [options[@"customMinZoomScale"] floatValue];
    }else{
        cameraController.customMinZoomScale = 1;
    }
    cameraController.cutType = self.cutType;
    if ((cutWidth<=0 || cutHeigth<=0) || self.cutType>1) {
        cameraController.aspectWHRatio = 0;
    } else {
        cameraController.aspectWHRatio = cutWidth*1.0/cutHeigth*1.0;
    }
    
    //配置拍摄类型
    int type = [options[@"type"] intValue];
    if (type == 5) {
        cameraController.shootType = 1;
    }else if (type == 6) {
        cameraController.shootType = 2;
    }else{
        cameraController.shootType = 0;
    }
    
    cameraController.editNaviBgColor = [self colorWithHexString:[options objectForKey:@"editNaviBgColor"]];
    cameraController.editOKButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editOKButtonTitleColorNormal"]];
    cameraController.editCancelButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editCancelButtonTitleColorNormal"]];
    cameraController.editToolbarBgColor = [self colorWithHexString:[options objectForKey:@"editToolbarBgColor"]];
    cameraController.editToolbarTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorNormal"]];
    cameraController.editToolbarTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorDisabled"]];
    
//    __weak XFCameraController *weakCameraController = cameraController;
    //获取云端图片资源回调
    cameraController.shootCloudCompletionBlock = ^(NSMutableArray *resultArray) {
        NSLog(@"resultArray....%@", resultArray);
        CDVPluginResult* result  = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"medias":resultArray}];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    };
    cameraController.takePhotosCloudCompletionBlock = ^(NSMutableArray *resultArray) {
        NSLog(@"resultArray....%@", resultArray);
        CDVPluginResult* result  = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"medias":resultArray}];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    };
    //获取本地图片资源回调
    cameraController.takePhotosCompletionBlock = ^(UIImage *image, NSError *error) {
        NSLog(@"takePhotosCompletionBlock");
    };
    cameraController.shootCompletionBlock = ^(NSURL *videoUrl, CGFloat videoTimeLength, UIImage *thumbnailImage, NSError *error) {
        NSLog(@"shootCompletionBlock");
    };
    [self.viewController presentViewController:cameraController animated:YES completion:nil];
}

/**
 上传文件
 
 @param command 交互对象
 */
- (void) upload:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    if (!options || options.count == 0) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数不能为空！"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    int type = [options[@"type"] intValue];
    if (type == 1) { //录制音频
        [self getAudio:command];
    }else if (type == 2) { //录制视频及拍照
        [self shootPhoto_Video:command];
    }else if (type == 4) { //选择视频上传
        [self getVideos:command];
    }else if (type == 5) { //只拍照
        [self shootPhoto_Video:command];
    }else if (type == 6) { //只拍摄视频
        [self shootPhoto_Video:command];
    }else { //选择图片上传
        [self getPictures:command];
    }
    
}

#pragma mark 私有方法

/**
 根据参数处理上传公共参数

 @param options 参数
 */
-(void)dealPublicUploadParams:(NSDictionary *)options {
    if (!options) {
        return;
    }
    /*    获取公共参数    */
    //服务端地址(测服，线上服地址以后可能会改)
    NSString *serverUrl = [NSString getSafeStrWithStr:options[@"serverUrl"] showNull:@"http://api.121wty.com/test/jserver"];
    [[NSUserDefaults standardUserDefaults] setObject:serverUrl forKey:serverUrlKey_plugin];
    //腾讯云存储桶地址
    NSString *region = [NSString getSafeStrWithStr:options[@"region"] showNull:@"ap-guangzhou"];
    [[NSUserDefaults standardUserDefaults] setObject:region forKey:regionKey_plugin];
    //腾讯云上传appid
    NSString *appId = [NSString getSafeStrWithStr:options[@"appid"] showNull:@""];
    [[NSUserDefaults standardUserDefaults] setObject:appId forKey:appIdKey_plugin];
    //用户标识
    NSString *ticket = [NSString getSafeStrWithStr:options[@"ticket"] showNull:@""];
    [[NSUserDefaults standardUserDefaults] setObject:ticket forKey:ticketKey_plugin];
    //test 测试 release 线上
    NSString *environment = [NSString getSafeStrWithStr:options[@"environment"] showNull:@"test"];
    [[NSUserDefaults standardUserDefaults] setObject:environment forKey:environmentKey_plugin];
    //机构id
    if (options[@"orgId"] && [options[@"orgId"] intValue] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[options[@"orgId"] intValue]] forKey:orgIdKey_plugin];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:orgIdKey_plugin];
    }
}

- (void)launchImagePicker:(LFPickingMediaType)mediaType maximumImagesCount:(NSInteger)maximumImagesCount maximumVideosCount:(NSInteger)maximumVideosCount cutType:(NSInteger)cutType cutWidth:(NSInteger)cutWidth cutHeigth:(NSInteger)cutHeigth options:(NSDictionary *)options
{
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowTakePicture = NO;
//    imagePicker.autoSavePhotoAlbum = YES;
    //    imagePicker.sortAscendingByCreateDate = NO;
    //    imagePicker.allowEditing = NO;
    imagePicker.supportAutorotate = NO; /** 适配横屏 */
    //    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
    //    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingType = mediaType;//LFPickingMediaTypeALL; /** 支持GIF */
//    imagePicker.allowPickingLivePhoto = NO; /** 支持Live Photo */
        imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
    //    imagePicker.defaultAlbumName = @"123"; /** 指定默认显示相册 */
    //    imagePicker.displayImageFilename = YES; /** 显示文件名称 */
//    imagePicker.allowPickingVideo = YES;
    if (options[@"customMinZoomScale"] && [options[@"customMinZoomScale"] doubleValue] >0) {
        imagePicker.customMinZoomScale = [options[@"customMinZoomScale"] floatValue];
    }else{
        imagePicker.customMinZoomScale = 1;
    }
    imagePicker.isGetCloudPath = YES;
    
    imagePicker.maxImagesCount = maximumImagesCount;
    if (imagePicker.allowPickingType == LFPickingMediaTypeVideo) {
        imagePicker.autoSavePhotoAlbum = YES;
        imagePicker.maxVideosCount = maximumVideosCount;
        if (options[@"duration"] && [options[@"duration"] doubleValue] >0) {
            imagePicker.maxVideoDuration = [options[@"duration"] doubleValue];
        }else{
            imagePicker.maxVideoDuration = 60;
        }
    }else{
        if (cutType>1) {
            imagePicker.autoSavePhotoAlbum = YES;
        }else{
            imagePicker.autoSavePhotoAlbum = NO;
        }
        imagePicker.isSelectOriginalPhoto = YES;
    }
    imagePicker.cutType = cutType;
    if ((cutWidth<=0 || cutHeigth<=0) || cutType>1) {
        imagePicker.aspectWHRatio = 0;
    } else {
        imagePicker.aspectWHRatio = cutWidth*1.0/cutHeigth*1.0;
    }
    if (imagePicker.maxImagesCount==1 /*&& imagePicker.cutType<=1*/) {
        imagePicker.allowPickingOriginalPhoto = NO;
    }
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    
//    //底部按钮背景色
//    imagePicker.oKButtonTitleColorNormal = [self colorWithHexString:@"4e8cee"];
//    imagePicker.oKButtonTitleColorDisabled = [self colorWithHexString:@"4e8cee"];
//    //导航栏背景色
//    imagePicker.naviBgColor = [self colorWithHexString:@"4e8cee"];
//    imagePicker.naviTitleColor = [UIColor whiteColor];
//    imagePicker.barItemTextColor = [UIColor whiteColor];
//    //预览视图导航栏
//    imagePicker.previewNaviBgColor = [self colorWithHexString:@"4e8cee"];
//    //底部toolbar
//    imagePicker.toolbarBgColor = [self colorWithHexString:@"4e8cee"];
//    imagePicker.toolbarTitleColorNormal = [UIColor whiteColor];
//    imagePicker.toolbarTitleColorDisabled = [UIColor whiteColor];
//    //编辑视图导航栏
//    imagePicker.editNaviBgColor = [self colorWithHexString:@"4e8cee"];
//    imagePicker.editOKButtonTitleColorNormal = [UIColor whiteColor];
//    imagePicker.editCancelButtonTitleColorNormal = [UIColor whiteColor];
//    //编辑视图底部工具栏
//    imagePicker.editToolbarBgColor = [self colorWithHexString:@"4e8cee"];
//    imagePicker.editToolbarTitleColorNormal = [UIColor whiteColor];
//    imagePicker.editToolbarTitleColorDisabled = [UIColor whiteColor];
    
    //底部按钮背景色
    imagePicker.oKButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"oKButtonTitleColorNormal"]];
    imagePicker.oKButtonTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"oKButtonTitleColorDisabled"]];
    //导航栏背景色
    imagePicker.naviBgColor = [self colorWithHexString:[options objectForKey:@"naviBgColor"]];
    imagePicker.naviTitleColor = [self colorWithHexString:[options objectForKey:@"naviTitleColor"]];
    imagePicker.barItemTextColor = [self colorWithHexString:[options objectForKey:@"barItemTextColor"]];
    //预览视图导航栏
    imagePicker.previewNaviBgColor = [self colorWithHexString:[options objectForKey:@"previewNaviBgColor"]];
    //底部toolbar
    imagePicker.toolbarBgColor = [self colorWithHexString:[options objectForKey:@"toolbarBgColor"]];
    imagePicker.toolbarTitleColorNormal = [self colorWithHexString:[options objectForKey:@"toolbarTitleColorNormal"]];
    imagePicker.toolbarTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"toolbarTitleColorDisabled"]];
    //编辑视图导航栏
    imagePicker.editNaviBgColor = [self colorWithHexString:[options objectForKey:@"editNaviBgColor"]];
    imagePicker.editOKButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editOKButtonTitleColorNormal"]];
    imagePicker.editCancelButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editCancelButtonTitleColorNormal"]];
    //编辑视图底部工具栏
    imagePicker.editToolbarBgColor = [self colorWithHexString:[options objectForKey:@"editToolbarBgColor"]];
    imagePicker.editToolbarTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorNormal"]];
    imagePicker.editToolbarTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorDisabled"]];
    
    /// 自定义文字
    imagePicker.doneBtnTitleStr = @"发送";
    [self.viewController showViewController:imagePicker sender:nil];
}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize cutType:(NSInteger)cutType
{
    UIImage* newImage = nil;
    if (frameSize.width<0.0001 && frameSize.height<0.0001) {
        newImage = anImage;
    } else {
        UIImage* sourceImage = anImage;
        CGSize imageSize = sourceImage.size;
        CGFloat width = imageSize.width;
        CGFloat height = imageSize.height;
        CGFloat targetWidth = frameSize.width;
        CGFloat targetHeight = frameSize.height;
        CGFloat scaleFactor = 0.0;
        CGSize scaledSize = frameSize;
        
        if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
            CGFloat widthFactor = targetWidth / width;
            CGFloat heightFactor = targetHeight / height;
            
            // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
            if (widthFactor == 0.0) {
                scaleFactor = heightFactor;
            } else if (heightFactor == 0.0) {
                scaleFactor = widthFactor;
            } else if (widthFactor > heightFactor) {
                scaleFactor = heightFactor; // scale to fit height
            } else {
                scaleFactor = widthFactor; // scale to fit width
            }
            scaledSize = CGSizeMake(floor(width * scaleFactor), floor(height * scaleFactor));
        }
        
        UIGraphicsBeginImageContext(scaledSize); // this will resize
        [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        if (newImage == nil) {
            NSLog(@"could not scale image");
        }
        
        // pop the context to get back to the default
        UIGraphicsEndImageContext();
    }
    return [self imageByScalingNotCroppingForSize:newImage cutType:cutType];
}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)sourceImage cutType:(NSInteger)cutType
{
    if (cutType==0) {
        UIGraphicsBeginImageContext(sourceImage.size);
        //bezierPathWithOvalInRect方法后面传的Rect,可以看作(x,y,width,height),前两个参数是裁剪的中心点,后面两个决定裁剪的区域是圆形还是椭圆.
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height)];
        //把路径设置为裁剪区域(超出裁剪区域以外的内容会自动裁剪掉)
        [path addClip];
        //把图片绘制到上下文当中
        [sourceImage drawAtPoint:CGPointZero];
        //从上下文当中生成一张新的图片
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        //结束上下文
        UIGraphicsEndImageContext();
        //返回新的图片
        return newImage;
    }
    return sourceImage;
}

- (NSData *)imageWithCompressImage:(UIImage *)image {
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    float value = data.length/1024;
    float maxSize = 2*1024;
    if (value>maxSize) {
        for (int i=9; i>0; --i) {
            float compressionQuality = i/10.0;
            NSData *data1 = UIImageJPEGRepresentation(image, compressionQuality);
            value = data1.length/1024;
            if (value<maxSize) {
                data = data1;
                break;
            }
        }
    }
    
    return data;
}

- (UIColor *)colorWithHexString:(NSString *)color
{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"] || [cString hasPrefix:@"0x"])
    {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    //a
    NSString *aString = @"255";
    if ([cString length] >= 8)
    {
        range.location = 6;
        aString = [cString substringWithRange:range];
    }
    
    // Scan values
    unsigned int r, g, b, a;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:aString] scanHexInt:&a];

    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:((float)a / 255.0f)];
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User finished picking assets");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"UIImagePickerController: User pressed cancel button");
}

#pragma mark - LFImagePickerControllerDelegate
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingResult:(NSArray <LFResultObject /* <LFResultImage/LFResultVideo> */*> *)results isOriginal:(BOOL)isOriginal;
{
    NSMutableArray * result_all = [[NSMutableArray alloc] init];
    CGSize targetSize = CGSizeMake(0, 0);
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    
    NSError* err = nil;
    NSString* filePath;
    CDVPluginResult* result = nil;
    
    NSInteger j = 0;
    for (NSInteger i = 0; i < results.count; i++) {
        LFResultObject *resultObj = results[i];
        if ([resultObj isKindOfClass:[LFResultImage class]]) {
            do {
                filePath = [NSString stringWithFormat:@"%@/%@%03ld.%@", docsPath, CDV_PHOTO_PREFIX, (long)j++, @"jpg"];
            } while ([fileMgr fileExistsAtPath:filePath]);
            
            LFResultImage *resultImage = (LFResultImage *)resultObj;
            
            NSData* data = nil;
            if (isOriginal || self.width < 0.0001 || self.height < 0.0001) {
                UIImage* image = [self imageByScalingNotCroppingForSize:resultImage.originalImage cutType:self.cutType];
                
                // no scaling required
                if (self.outputType == BASE64_STRING){
                    [result_all addObject:[[self imageWithCompressImage:image] base64EncodedStringWithOptions:0]];
                } else {
                    // resample first
                    data = [self imageWithCompressImage:image];
                    if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsDictionary:@{@"status":[NSNumber numberWithInt:1],@"data":@{},@"msg":[err localizedDescription]}];
                        break;
                    } else {
                        [result_all addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
                    }
                }
            } else {
                UIImage* image = resultImage.originalImage;
                // scale
                UIImage* scaledImage = [self imageByScalingNotCroppingForSize:image toSize:targetSize cutType:self.cutType];
                data = [self imageWithCompressImage:scaledImage];
                
                if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsDictionary:@{@"status":[NSNumber numberWithInt:1],@"data":@{},@"msg":[err localizedDescription]}];
                    break;
                } else {
                    if(self.outputType == BASE64_STRING){
                        [result_all addObject:[data base64EncodedStringWithOptions:0]];
                    } else {
                        [result_all addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
                    }
                }
            }
        }
    }
    
    if (result == nil) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"status":[NSNumber numberWithInt:1],@"data":result_all,@"msg":@""}];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

/**
 如果从云端获取路径，执行此回调
 
 @param picker 选择器
 @param results 回调对象
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingCloudResult:(NSArray*)results {
    NSLog(@"resultArray....%@", results);
    CDVPluginResult* result  = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"medias":results}];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (void)lf_imagePickerControllerDidCancel:(LFImagePickerController *)picker
{
    
}


@end
