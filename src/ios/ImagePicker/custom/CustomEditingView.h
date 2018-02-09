//
//  CustomEditingView.h
//  ImagePicker
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFScrollView.h"
#import "LFEditingProtocol.h"

@protocol CustomEditingViewDelegate;

@interface CustomEditingView : LFScrollView <LFEditingProtocol>

@property (nonatomic, strong) UIImage *image;

/** 代理 */
@property (nonatomic, weak) id<CustomEditingViewDelegate> clippingDelegate;

/** 最小尺寸 CGSizeMake(80, 80) */
@property (nonatomic, assign) CGSize clippingMinSize;
/** 最大尺寸 CGRectInset(self.frame , 20, 50) */
@property (nonatomic, assign) CGRect clippingMaxRect;

/** 开关编辑模式 */
@property (nonatomic, assign) BOOL isClipping;
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated;

/** 取消剪裁 */
- (void)cancelClipping:(BOOL)animated;
/** 还原 isClipping=YES 的情况有效 */
- (void)reset;
- (BOOL)canReset;
/** 旋转 isClipping=YES 的情况有效 */
- (void)rotate;

/** 长宽比例 */
@property (nonatomic, assign) float aspectWHRatio;

@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形
//- (void)setAspectWHRatio:(float)aspectRatio;

/** 创建编辑图片 */
- (UIImage *)createEditImage;

@end


@protocol CustomEditingViewDelegate <NSObject>
/** 剪裁发生变化后 */
- (void)lf_EditingViewDidEndZooming:(CustomEditingView *)EditingView;
/** 剪裁目标移动后 */
- (void)lf_EditingViewEndDecelerating:(CustomEditingView *)EditingView;
@end

