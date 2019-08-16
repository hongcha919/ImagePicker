//
//  LFVideoClipToolbar.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoClipToolbar.h"
#import "LFMediaEditingHeader.h"
#import "LFImagePickerHeader.h"

@interface LFVideoClipToolbar ()
{
    UIButton *_leftButton;
    UIButton *_rightButton;
}

@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;

@end

@implementation LFVideoClipToolbar

- (instancetype)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.oKButtonTitleColorNormal = [UIColor colorWithRed:(26/255.0) green:(178/255.0) blue:(10/255.0) alpha:1.0];
    
    CGFloat rgb = 34 / 255.0;
    self.backgroundColor = self.editNaviBgColor?self.editNaviBgColor :[UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    CGSize size = CGSizeMake(44, 44);
    CGFloat margin = 10.f;
    
    /** 左 */
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = (CGRect){{0,self.frame.size.height-44}, size};
    [leftButton setImage:bundleImageNamed(@"navigationbar_back_arrow") forState:UIControlStateNormal];
    [leftButton setImage:bundleImageNamed(@"navigationbar_back_arrow") forState:UIControlStateHighlighted];
    [leftButton setImage:bundleImageNamed(@"navigationbar_back_arrow") forState:UIControlStateSelected];
    [leftButton addTarget:self action:@selector(clippingCancel:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:leftButton];
    _leftButton = leftButton;
    
    /** 右 */
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = (CGRect){{CGRectGetWidth(self.frame)-size.width-margin,self.frame.size.height-44}, size};
    rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [rightButton setTitle:@"确定" forState:UIControlStateNormal];
    [rightButton setTitleColor:self.editOKButtonTitleColorNormal?self.editOKButtonTitleColorNormal:[UIColor whiteColor] forState:UIControlStateNormal];
//    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn.png") forState:UIControlStateNormal];
//    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateHighlighted];
//    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(clippingOk:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rightButton];
    _rightButton = rightButton;
}

//刷新视图控件颜色
-(void) refreshViewColor {
    [_rightButton setTitleColor:self.editOKButtonTitleColorNormal?self.editOKButtonTitleColorNormal:[UIColor whiteColor] forState:UIControlStateNormal];
    CGFloat rgb = 34 / 255.0;
    self.backgroundColor = self.editNaviBgColor?self.editNaviBgColor :[UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
}

#pragma mark - action
- (void)clippingCancel:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(lf_videoClipToolbarDidCancel:)]) {
        [self.delegate lf_videoClipToolbarDidCancel:self];
    }
}

- (void)clippingOk:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(lf_videoClipToolbarDidFinish:)]) {
        [self.delegate lf_videoClipToolbarDidFinish:self];
    }
}

@end
