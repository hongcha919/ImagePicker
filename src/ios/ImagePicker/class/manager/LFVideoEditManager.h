//
//  LFVideoEditManager.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFVideoEdit, LFAsset, LFResultVideo;
@interface LFVideoEditManager : NSObject

+ (instancetype)manager NS_SWIFT_NAME(default());
+ (void)free;

/** 设置编辑对象 */
- (void)setVideoEdit:(LFVideoEdit *)obj forAsset:(LFAsset *)asset;
/** 获取编辑对象 */
- (LFVideoEdit *)videoEditForAsset:(LFAsset *)asset;

/**
 通过asset解析视频
 
 @param asset LFAsset
 @param completion 回调
 */
- (void)getVideoWithAsset:(LFAsset *)asset
               completion:(void (^)(LFResultVideo *resultVideo))completion;

@end

