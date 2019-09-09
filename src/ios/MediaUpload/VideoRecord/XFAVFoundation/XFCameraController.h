//
//  QXCameraController.h
//
//
//  Created by xf-ling on 2017/6/1.
//  Copyright © 2017年 LXF. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark 本地图片回调
/**
 *  拍照完成后的Block回调
 *
 *  @param image 拍照后返回的image
 */
typedef void(^TakePhotosCompletionBlock)(UIImage *image, NSError *error);

/**
 *  拍摄完成后的Block回调
 *
 *  @param videoUrl 拍摄后返回的小视频地址
 *  @param videoTimeLength 小视频时长
 *  @param thumbnailImage 小视频缩略图
 */
typedef void(^ShootCompletionBlock)(NSURL *videoUrl, CGFloat videoTimeLength, UIImage *thumbnailImage, NSError *error);

#pragma mark 获取云图片回调
/**
 *  拍照完成后的Block回调
 *
 *  @param image 拍照后返回的image
 */
typedef void(^TakePhotosCloudCompletionBlock)(NSMutableArray *resultArray);

/**
 *  拍摄完成后的Block回调
 *
 *  @param videoUrl 拍摄后返回的小视频地址
 *  @param videoTimeLength 小视频时长
 *  @param thumbnailImage 小视频缩略图
 */
typedef void(^ShootCloudCompletionBlock)(NSMutableArray *resultArray);

@interface XFCameraController : UIViewController

/**
 *  拍照完成后的Block回调
 */
@property (copy, nonatomic) TakePhotosCompletionBlock takePhotosCompletionBlock;

/**
 *  拍摄完成后的Block回调
 */
@property (copy, nonatomic) ShootCompletionBlock shootCompletionBlock;

/**
 *  拍照完成后的云端图片Block回调
 */
@property (copy, nonatomic) TakePhotosCloudCompletionBlock takePhotosCloudCompletionBlock;

/**
 *  拍摄完成后的云端视频Block回调
 */
@property (copy, nonatomic) ShootCloudCompletionBlock shootCloudCompletionBlock;

/**
 *  自定义APP相册名字，如果为空则默认为APP的名字
 */
@property (strong, nonatomic) NSString *assetCollectionName;

/**
 *  视频文件保存文件夹，如果没有定义，默认在document/video文件夹下面
 */
@property (strong, nonatomic) NSString *videoFilePath;

/**
 最长录制时间,未传输默认最大录制10s
 */
@property (nonatomic, assign) int maxRecTime;

/**
 是否获取云端数据路径
 */
@property (nonatomic, assign) BOOL isGetCloudRes;
@property (nonatomic, assign) float aspectWHRatio;
@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形；其他 网格形状
@property (nonatomic, assign) float customMinZoomScale;
/** 是否允许编辑 默认NO */
@property (nonatomic, assign) BOOL allowEditing;

/** 拍摄类型 0：支持拍照和摄像 1：只拍照 2：只摄像 */
@property (nonatomic, assign) int shootType;

/*
 //选择上传出错后具体的容错提示场景 
 
 0:默认不给容错提示，只将错误信息根据接口返回，容错提示放到引用插件侧处理
 1:容错提示在插件侧提示，提示场景如下： 1）音频、视频、图片上传一张时失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮 2）选择多张图片、多个视频失败，      全部失败：提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮。      部分失败：提示用户“上传N个失败，M个成功”，提示框中上传N张图片、返回重传按钮。
 
 2:容错提示在插件侧提示，提示场景如下：
 1）音频、视频、图片上传一张时失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮
 2）选择多张图片、多个视频失败，不管是全部失败还是部分失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮。
 
 */
@property (nonatomic, assign) int errorAlertType;

//编辑视图导航栏
@property (nonatomic, strong) UIColor *editNaviBgColor;
@property (nonatomic, strong) UIColor *editOKButtonTitleColorNormal;
@property (nonatomic, strong) UIColor *editCancelButtonTitleColorNormal;
//编辑视图底部工具栏
@property (nonatomic, strong) UIColor *editToolbarBgColor;
@property (nonatomic, strong) UIColor *editToolbarTitleColorNormal;
@property (nonatomic, strong) UIColor *editToolbarTitleColorDisabled;

+ (instancetype)defaultCameraController;

@end
