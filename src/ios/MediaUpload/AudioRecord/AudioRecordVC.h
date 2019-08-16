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
