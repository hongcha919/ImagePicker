//
//  CustomUploadVC.h
//  HelloCordova
//
//  Created by haoqi on 2019/7/24.
//

#import <UIKit/UIKit.h>

//typedef NS_ENUM(NSInteger, UploadFileType) {
//    
//};

NS_ASSUME_NONNULL_BEGIN

@interface CustomUploadVC : UIViewController

/// Return the new selected photos / 返回最新的选中图片数组
@property (nonatomic, copy) void (^backButtonClickBlock)(void);
@property (nonatomic, copy) void (^doneButtonClickBlock)(NSMutableArray *resultArray);

@property (nonatomic, assign) BOOL isAudio; //是否是音频上传，不传默认不是
@property (nonatomic, strong) NSMutableArray *uploadArray;

@end

NS_ASSUME_NONNULL_END
