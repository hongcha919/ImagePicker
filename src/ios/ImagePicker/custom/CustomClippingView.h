//
//  CustomClippingView.h
//  ImagePicker
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#import "LFScrollView.h"

#import "LFEditingProtocol.h"

@protocol CustomClippingViewDelegate;

@interface CustomClippingView : LFScrollView <LFEditingProtocol>

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, weak) id<CustomClippingViewDelegate> clippingDelegate;
/** 首次缩放后需要记录最小缩放值 */
@property (nonatomic, readonly) CGFloat first_minimumZoomScale;

/** 是否重置中 */
@property (nonatomic, readonly) BOOL isReseting;
/** 是否旋转中 */
@property (nonatomic, readonly) BOOL isRotating;
/** 是否缩放中 */
//@property (nonatomic, readonly) BOOL isZooming;
/** 是否可还原 */
@property (nonatomic, readonly) BOOL canReset;

/** 可编辑范围 */
@property (nonatomic, assign) CGRect editRect;
/** 剪切范围 */
@property (nonatomic, assign) CGRect cropRect;

@property (nonatomic, assign) float customMinZoomScale;
@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形

/** 缩小到指定坐标 */
- (void)zoomOutToRect:(CGRect)toRect;
/** 放大到指定坐标(必须大于当前坐标) */
- (void)zoomInToRect:(CGRect)toRect;
/** 旋转 */
- (void)rotateClockwise:(BOOL)clockwise;
/** 还原 */
- (void)reset;
/** 取消 */
- (void)cancel;
/* 设置初始缩放比例*/
- (void)setInitZoomScale:(CGFloat)scale;
- (NSDictionary *)getPhotoEditData:(BOOL)always;

@end

@protocol CustomClippingViewDelegate <NSObject>

/** 同步缩放视图（调用zoomOutToRect才会触发） */
- (void (^)(CGRect))lf_clippingViewWillBeginZooming:(CustomClippingView *)clippingView;
- (void)lf_clippingViewDidZoom:(CustomClippingView *)clippingView;
- (void)lf_clippingViewDidEndZooming:(CustomClippingView *)clippingView;

/** 移动视图 */
- (void)lf_clippingViewWillBeginDragging:(CustomClippingView *)clippingView;
- (void)lf_clippingViewDidEndDecelerating:(CustomClippingView *)clippingView;


@end

