//
//  CustomClipToolbar.h
//  ImagePicker
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomClipToolbarDelegate;

@interface CustomClipToolbar : UIView

/** 代理 */
@property (nonatomic, weak) id<CustomClipToolbarDelegate> delegate;

/** 开启重置按钮 default NO  */
@property (nonatomic, assign) BOOL enableReset;

@property (nonatomic, readonly) CGRect clickViewRect;

@end

@protocol CustomClipToolbarDelegate <NSObject>

/** 重置 */
- (void)lf_clipToolbarDidReset:(CustomClipToolbar *)clipToolbar;
/** 旋转 */
- (void)lf_clipToolbarDidRotate:(CustomClipToolbar *)clipToolbar;

@optional
/** 取消 */
- (void)lf_clipToolbarDidCancel:(CustomClipToolbar *)clipToolbar;
/** 完成 */
- (void)lf_clipToolbarDidFinish:(CustomClipToolbar *)clipToolbar;
/** 长宽比例 */
- (void)lf_clipToolbarDidAspectRatio:(CustomClipToolbar *)clipToolbar;

@end



