//
//  LFVideoClipToolbar.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFVideoClipToolbarDelegate;

@interface LFVideoClipToolbar : UIView

/** 代理 */
@property (nonatomic, weak) id<LFVideoClipToolbarDelegate> delegate;

//编辑视图导航栏
@property (nonatomic, strong) UIColor *editNaviBgColor;
@property (nonatomic, strong) UIColor *editOKButtonTitleColorNormal;
@property (nonatomic, strong) UIColor *editCancelButtonTitleColorNormal;
//编辑视图底部工具栏
//@property (nonatomic, strong) UIColor *editToolbarBgColor;
//@property (nonatomic, strong) UIColor *editToolbarTitleColorNormal;
//@property (nonatomic, strong) UIColor *editToolbarTitleColorDisabled;

//刷新视图控件颜色
-(void) refreshViewColor ;

@end

@protocol LFVideoClipToolbarDelegate <NSObject>

/** 取消 */
- (void)lf_videoClipToolbarDidCancel:(LFVideoClipToolbar *)clipToolbar;
/** 完成 */
- (void)lf_videoClipToolbarDidFinish:(LFVideoClipToolbar *)clipToolbar;
@end
