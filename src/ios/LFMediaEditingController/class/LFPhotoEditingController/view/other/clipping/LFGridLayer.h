//
//  LFGridLayer.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFGridLayer : CAShapeLayer

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;

//@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) NSArray<NSNumber *> *lineDashPatternAry;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *gridColor;
@property (nonatomic, assign) NSInteger cutType;//0 圆形；1矩形

@end
