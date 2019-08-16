//
//  CustomPhotoEditingController.h
//  LFImagePickerController
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEditingController.h"

@protocol CustomPhotoEditingControllerDelegate;

@interface CustomPhotoEditingController : LFBaseEditingController

/** 是否隐藏导航栏 默认NO */
@property (nonatomic, assign) BOOL isHiddenNavBar;

/** 设置编辑图片->重新初始化（图片方向必须为正方向） */
@property (nonatomic, strong) UIImage *editImage;
/** 设置编辑对象->重新编辑 */
@property (nonatomic, strong) LFPhotoEdit *photoEdit;

/** 设置操作类型 default is LFPhotoEditOperationType_All */
@property (nonatomic, assign) LFPhotoEditOperationType operationType;

/** 自定义贴图资源 */
@property (nonatomic, strong) NSString *stickerPath;

/** 代理 */
@property (nonatomic, weak) id<CustomPhotoEditingControllerDelegate> delegate;

@property (nonatomic, assign) float aspectWHRatio;
@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形；其他 网格形状
@property (nonatomic, assign) float customMinZoomScale;
/** 是否允许编辑 默认NO */
@property (nonatomic, assign) BOOL allowEditing;

@end

@protocol CustomPhotoEditingControllerDelegate <NSObject>

- (void)lf_PhotoEditingController:(CustomPhotoEditingController *)photoEditingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit;
- (void)lf_PhotoEditingController:(CustomPhotoEditingController *)photoEditingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit;

@end

