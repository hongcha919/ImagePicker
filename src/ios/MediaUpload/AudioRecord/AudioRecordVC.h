//
//  AudioRecordVC.h
//  HelloCordova
//
//  Created by haoqi on 2019/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioRecordVC : UIViewController

/**
 最长录制时间
 */
@property (nonatomic, assign) int maxRecTime;
/**
 是否获取云端数据路径
 */
@property (nonatomic, assign) BOOL isGetCloudRes;

/*
 //选择上传出错后具体的容错提示场景 
 
 0:默认不给容错提示，只将错误信息根据接口返回，容错提示放到引用插件侧处理
 1:容错提示在插件侧提示，提示场景如下： 1）音频、视频、图片上传一张时失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮 2）选择多张图片、多个视频失败，      全部失败：提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮。      部分失败：提示用户“上传N个失败，M个成功”，提示框中上传N张图片、返回重传按钮。
 
 2:容错提示在插件侧提示，提示场景如下：
 1）音频、视频、图片上传一张时失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮
 2）选择多张图片、多个视频失败，不管是全部失败还是部分失败，提示用户“上传失败，请返回重新上传”，提示框中取消、返回重传按钮。
 
 */
@property (nonatomic, assign) int errorAlertType;


/// Return the new selected photos / 返回最新的选中图片数组
@property (nonatomic, copy) void (^backButtonClickBlock)(void);

/**
 完成回调
 1：isGetCloudRes NO时，数组中为本地音频路径字符串
 2：isGetCloudRes YES时，数组中为云端音频媒体对象
 */
@property (nonatomic, copy) void (^doneButtonClickBlock)(NSMutableArray *resultArray);

@end

NS_ASSUME_NONNULL_END
