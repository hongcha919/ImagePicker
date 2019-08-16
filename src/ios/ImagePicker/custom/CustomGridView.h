//
//  CustomGridView.h
//  ImagePicker
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomGridViewDelegate;
@interface CustomGridView : UIView

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated;
- (CGRect)getResetRect:(CGRect)frame;
- (BOOL)gridRectChange;
- (void)setAspectWHRatio:(float)aspectWHRatio rect:(CGRect)rect;

/** 最小尺寸 CGSizeMake(80, 80); */
@property (nonatomic, assign) CGSize controlMinSize;
/** 最大尺寸 CGRectInset(self.bounds, 50, 50) */
@property (nonatomic, assign) CGRect controlMaxRect;
/** 原图尺寸 */
@property (nonatomic, assign) CGSize controlSize;

/** 显示遮罩层（触发拖动条件必须设置为YES）default is YES */
@property (nonatomic, assign) BOOL showMaskLayer;

/** 设置固定比例 */
@property (nonatomic, assign) float aspectWHRatio;

@property (nonatomic, weak) id<CustomGridViewDelegate> delegate;
@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形

@end

@protocol CustomGridViewDelegate <NSObject>

- (void)lf_gridViewDidBeginResizing:(CustomGridView *)gridView;
- (void)lf_gridViewDidResizing:(CustomGridView *)gridView;
- (void)lf_gridViewDidEndResizing:(CustomGridView *)gridView;

/** 调整长宽比例 */
- (void)lf_gridViewDidAspectRatio:(CustomGridView *)gridView;
@end

