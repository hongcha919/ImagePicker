//
//  SOSPicker.h
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import <Cordova/CDVPlugin.h>


@interface SOSPicker : CDVPlugin < UINavigationControllerDelegate, UIScrollViewDelegate>

@property (copy)   NSString* callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command;
- (void) hasReadPermission:(CDVInvokedUrlCommand *)command;
- (void) requestReadPermission:(CDVInvokedUrlCommand *)command;

- (void) getAudio:(CDVInvokedUrlCommand *)command;
- (void) getVideos:(CDVInvokedUrlCommand *)command;
- (void) shootPhoto_Video:(CDVInvokedUrlCommand *)command;

/**
 上传文件

 @param command 交互对象
 */
- (void) upload:(CDVInvokedUrlCommand *)command;

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize;

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger quality;
//输出格式：0.文件绝对路径 1.BASE64_STRING
@property (nonatomic, assign) NSInteger outputType;
//最多选择个数
@property (nonatomic, assign) NSInteger maximumImagesCount;
//图片裁剪形状(1圆形;2正方形;3矩形)
@property (nonatomic, assign) NSInteger cutType; 

@end
