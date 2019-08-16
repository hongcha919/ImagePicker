//
//  UIView+LFFrame.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

//手机是否是iPhoneX
#define LF_IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define LF_StateBarHeight [UIApplication sharedApplication].statusBarFrame.size.height//(IS_IPHONE_X==YES)?44.0f: 20.0f
#define LF_NavBarHeight ((LF_IS_IPHONE_X)?88.0f: 64.0f)
#define LF_TabbarHeight ((LF_IS_IPHONE_X)?83.0f: 49.0f)

@interface UIView (LFMEFrame)

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint origin;

@end
