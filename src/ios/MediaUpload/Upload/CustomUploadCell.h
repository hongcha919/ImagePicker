//
//  CustomUploadCell.h
//  HelloCordova
//
//  Created by haoqi on 2019/7/24.
//

#import <UIKit/UIKit.h>
#import "TXUGCPublish.h"
#import "TXUGCPublishOptCenter.h"
#import "TCHttpUtil.h"
#import "TXUGCPublishListener.h"
#import "LFResultObject_property.h"
#import "NSString+LFMECoreText.h"
#import "PublicParamsKey.h"
#import <QCloudCore/QCloudCore.h>
#import <QCloudCOSXML/QCloudCOSXML.h>

//手机是否是iPhoneX
#define C_IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define C_KIphoneXNoneHeight (IS_IPHONE_X?20:0)

//状态栏，导航栏，工具栏高度
#define C_StateBarHeight [UIApplication sharedApplication].statusBarFrame.size.height//(IS_IPHONE_X==YES)?44.0f: 20.0f
#define C_NavBarHeight ((C_IS_IPHONE_X)?88.0f: 64.0f)
#define C_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define C_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

NS_ASSUME_NONNULL_BEGIN

typedef void(^UploadVideoCompletionBlock)(TXPublishResult * __nullable result, NSString *mediaId, NSInteger index, NSString *errorStr);
typedef void(^UploadPhoto_AudioCompletionBlock)(QCloudUploadObjectResult * __nullable result, NSInteger index, NSString *errorStr);

@interface CustomUploadCell : UITableViewCell <TXVideoPublishListener>
{
    TXUGCPublish     *_videoPublish;
}

//发送状态 0：未发送 1：发送中 2：发送成功 3：发送失败
@property (nonatomic, assign) int sendStatus;

/**
 *  上传视频后的Block回调
 */
@property (copy, nonatomic) UploadVideoCompletionBlock videoCompletionBlock;

/**
 *  上传图片、音频后的Block回调
 */
@property (copy, nonatomic) UploadPhoto_AudioCompletionBlock photo_AudioCompletionBlock;

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
 }
 */
-(void)setCellMsgWithResultImage:(NSDictionary *)result cosMsg:(NSDictionary*)cosMsg;

/**
 设置cell值显示
 
 @param result 音频资源信息
 @param cosMsg cos签名信息
 {
 bucket://存储桶
 region：//存储区域
 authorization：//签名
 }
 */
-(void)setCellMsgWithResultAudio:(LFResultVideo *)result cosMsg:(NSDictionary*)cosMsg;

/**
 设置cell值显示
 
 @param result 视频资源信息
 @param videoSign 上传视频签名
 @param type 类型 0：图片 1：语音 2：视频
 */
-(void)setCellMsgWithResultVideo:(LFResultVideo *)result;

/**
 cell高度

 @return 高度
 */
+ (CGFloat)cellHeight;

/**
 根据状态显示cell视图

 @param status 上传状态 0：未发送 1：发送中 2：发送成功 3：发送失败
 @param fileType 文件类型 0：图片 1：音频 2：视频
 */
-(void)setCellShowViewWithStatus:(NSInteger)status fileType:(NSInteger)fileType;

@end

NS_ASSUME_NONNULL_END
