//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import "SOSPicker.h"


#import "LFImagePickerController.h"

#import "UIImage+LF_Format.h"
#import "LFAssetManager.h"
#import "LFAssetManager+CreateMedia.h"

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
    
    self.outputType = [[options objectForKey:@"outputType"] integerValue];
    
    self.maximumImagesCount = [[options objectForKey:@"maximumImagesCount"] integerValue];
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];

    self.cutType = [[options objectForKey:@"cutType"] integerValue];
    NSInteger cutWidth = [[options objectForKey:@"cutWidth"] integerValue];
    NSInteger cutHeigth = [[options objectForKey:@"cutHeigth"] integerValue];

    self.callbackId = command.callbackId;
    [self launchImagePicker:false maximumImagesCount:self.maximumImagesCount cutType:self.cutType cutWidth:cutWidth cutHeigth:cutHeigth options:options];
}

- (void)launchImagePicker:(bool)allow_video maximumImagesCount:(NSInteger)maximumImagesCount cutType:(NSInteger)cutType cutWidth:(NSInteger)cutWidth cutHeigth:(NSInteger)cutHeigth options:(NSDictionary *)options
{
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowTakePicture = NO;
    //    imagePicker.sortAscendingByCreateDate = NO;
    //    imagePicker.allowEditing = NO;
    imagePicker.supportAutorotate = NO; /** 适配横屏 */
    //    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
    //    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingGif = NO; /** 支持GIF */
    imagePicker.allowPickingLivePhoto = NO; /** 支持Live Photo */
    //    imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
    //    imagePicker.defaultAlbumName = @"123"; /** 指定默认显示相册 */
    //    imagePicker.displayImageFilename = YES; /** 显示文件名称 */
    imagePicker.allowPickingVideo = NO;
    imagePicker.customMinZoomScale = [[options objectForKey:@"customMinZoomScale"] floatValue];

    imagePicker.maxImagesCount = maximumImagesCount;
    imagePicker.cutType = cutType;
    if ((cutWidth==0 || cutHeigth==0) || cutType>1) {
        imagePicker.aspectWHRatio = 0;
    } else {
        imagePicker.aspectWHRatio = cutWidth*1.0/cutHeigth*1.0;
    }
    if (imagePicker.maxImagesCount==1 && imagePicker.cutType<=1) {
        imagePicker.allowPickingOriginalPhoto = NO;
    }
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    
    imagePicker.oKButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"oKButtonTitleColorNormal"]];
    imagePicker.oKButtonTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"oKButtonTitleColorDisabled"]];
    imagePicker.naviBgColor = [self colorWithHexString:[options objectForKey:@"naviBgColor"]];
    imagePicker.naviTitleColor = [self colorWithHexString:[options objectForKey:@"naviTitleColor"]];
    imagePicker.barItemTextColor = [self colorWithHexString:[options objectForKey:@"barItemTextColor"]];
    
    imagePicker.previewNaviBgColor = [self colorWithHexString:[options objectForKey:@"previewNaviBgColor"]];
    
    imagePicker.toolbarBgColor = [self colorWithHexString:[options objectForKey:@"toolbarBgColor"]];
    imagePicker.toolbarTitleColorNormal = [self colorWithHexString:[options objectForKey:@"toolbarTitleColorNormal"]];
    imagePicker.toolbarTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"toolbarTitleColorDisabled"]];
    
    imagePicker.editNaviBgColor = [self colorWithHexString:[options objectForKey:@"editNaviBgColor"]];
    imagePicker.editOKButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editOKButtonTitleColorNormal"]];
    imagePicker.editCancelButtonTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editCancelButtonTitleColorNormal"]];
    imagePicker.editToolbarBgColor = [self colorWithHexString:[options objectForKey:@"editToolbarBgColor"]];
    imagePicker.editToolbarTitleColorNormal = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorNormal"]];
    imagePicker.editToolbarTitleColorDisabled = [self colorWithHexString:[options objectForKey:@"editToolbarTitleColorDisabled"]];

    /// 自定义文字
    imagePicker.doneBtnTitleStr = @"确认";
    //    imagePicker.editNaviBgColor = [UIColor greenColor];
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

#pragma mark - GMImagePickerControllerDelegate
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
        LFResultObject *result = results[i];
        if ([result isKindOfClass:[LFResultImage class]]) {
            do {
                filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, j++, @"jpg"];
            } while ([fileMgr fileExistsAtPath:filePath]);
            
            LFResultImage *resultImage = (LFResultImage *)result;
            
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
                        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
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
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
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
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:result_all];
    }
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (void)lf_imagePickerControllerDidCancel:(LFImagePickerController *)picker
{
    
}


@end
