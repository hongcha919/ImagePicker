//
//  LFVideoEditingController.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoEditingController.h"
#import "LFMediaEditingHeader.h"
#import "UIView+LFMEFrame.h"
#import "UIImage+LFMECommon.h"
#import "LFMediaEditingType.h"
#import "LFMECancelBlock.h"

#import "LFVideoEditingView.h"
#import "LFEditToolbar.h"
#import "LFStickerBar.h"
#import "LFTextBar.h"
#import "LFVideoClipToolbar.h"
#import "LFAudioTrackBar.h"
#import "JRFilterBar.h"
#import "FilterSuiteUtils.h"
#import "AVAsset+LFMECommon.h"

@interface LFVideoEditingController () <LFEditToolbarDelegate, LFStickerBarDelegate, LFTextBarDelegate, JRFilterBarDelegate, JRFilterBarDataSource, LFAudioTrackBarDelegate, LFVideoClipToolbarDelegate, LFPhotoEditDelegate, UIGestureRecognizerDelegate>
{
    /** 编辑模式 */
    LFVideoEditingView *_EditingView;
    
    UIView *_edit_naviBar;
    /** 底部栏菜单 */
    LFEditToolbar *_edit_toolBar;
    
    /** 贴图菜单 */
    LFStickerBar *_edit_sticker_toolBar;
    /** 滤镜菜单 */
    JRFilterBar *_edit_filter_toolBar;
    /** 剪切菜单 */
    LFVideoClipToolbar *_edit_clipping_toolBar;
    
    /*还原按钮*/
    UIButton *_restoreButton;
    
    /** 单击手势 */
    UITapGestureRecognizer *singleTapRecognizer;
}

/** 隐藏控件 */
@property (nonatomic, assign) BOOL isHideNaviBar;
/** 初始化以选择的功能类型，已经初始化过的将被去掉类型，最终类型为0 */
@property (nonatomic, assign) LFVideoEditOperationType initSelectedOperationType;

@property (nonatomic, copy) lf_me_dispatch_cancelable_block_t delayCancelBlock;

/** 滤镜缩略图 */
@property (nonatomic, strong) UIImage *filterSmallImage;

@end

@implementation LFVideoEditingController

- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation
{
    self = [super initWithOrientation:orientation];
    if (self) {
        _operationType = LFVideoEditOperationType_All;
        _minClippingDuration = 1.f;
    }
    return self;
}

- (void)setVideoURL:(NSURL *)url placeholderImage:(UIImage *)image;
{
    _asset = [AVURLAsset assetWithURL:url];
    _placeholderImage = image;
    [self setVideoAsset:_asset placeholderImage:image];
}

- (void)setVideoAsset:(AVAsset *)asset placeholderImage:(UIImage *)image
{
    _asset = asset;
    _placeholderImage = image;
    [_EditingView setVideoAsset:asset placeholderImage:image];
    /** default audio urls */
    if (!_videoEdit && self.defaultAudioUrls.count) {
        NSMutableArray *m_audioUrls = [_EditingView.audioUrls mutableCopy];
        for (NSURL *url in self.defaultAudioUrls) {
            if ([url isKindOfClass:[NSURL class]]) {
                LFAudioItem *item = [LFAudioItem new];
                item.title = [url.lastPathComponent stringByDeletingPathExtension];;
                item.url = url;
                [m_audioUrls addObject:item];
            }
        }
        _EditingView.audioUrls = m_audioUrls;
    }
}

- (void)setMinClippingDuration:(double)minClippingDuration
{
    if (minClippingDuration > 0.999) {
        _minClippingDuration = minClippingDuration;
        _EditingView.minClippingDuration = minClippingDuration;
    }
}

- (void)setDefaultOperationType:(LFVideoEditOperationType)defaultOperationType
{
    _defaultOperationType = defaultOperationType;
    _initSelectedOperationType = defaultOperationType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configEditingView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    [self configDefaultOperation];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        _edit_naviBar.height = kCustomTopbarHeight_iOS11;
    } else {
        _edit_naviBar.height = kCustomTopbarHeight;
    }
}

- (void)dealloc
{
    /** 恢复原来的音频 */
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建视图
- (void)configEditingView
{
    CGRect editRect = self.view.bounds;
    
    if (@available(iOS 11.0, *)) {
        editRect.origin.x += self.navigationController.view.safeAreaInsets.left;
        editRect.origin.y += self.navigationController.view.safeAreaInsets.top;
        editRect.size.width -= (self.navigationController.view.safeAreaInsets.left+self.navigationController.view.safeAreaInsets.right);
        editRect.size.height -= (self.navigationController.view.safeAreaInsets.top+self.navigationController.view.safeAreaInsets.bottom);
    }
    
    _EditingView = [[LFVideoEditingView alloc] initWithFrame:editRect];
    _EditingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _EditingView.editDelegate = self;
    _EditingView.minClippingDuration = self.minClippingDuration;
//    _EditingView.clippingDelegate = self;
    if (_videoEdit) {
        _EditingView.photoEditData = _videoEdit.editData;
        [self setVideoAsset:_videoEdit.editAsset placeholderImage:_videoEdit.editPreviewImage];
    } else {
        [self setVideoAsset:_asset placeholderImage:_placeholderImage];
    }
    
    /** 单击的 Recognizer */
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    singleTapRecognizer.delegate = self;
    /** 给view添加一个手势监测 */
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    [self.view addSubview:_EditingView];
}

- (void)configCustomNaviBar
{
    CGFloat margin = 5, topbarHeight = 0;
    if (@available(iOS 11.0, *)) {
        topbarHeight = kCustomTopbarHeight_iOS11;
    } else {
        topbarHeight = kCustomTopbarHeight;
    }
    CGFloat naviHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    _edit_naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, topbarHeight)];
    _edit_naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _edit_naviBar.backgroundColor = self.editNaviBgColor? self.editNaviBgColor: [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    UIView *naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, topbarHeight-naviHeight, _edit_naviBar.frame.size.width, naviHeight)];
    naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [_edit_naviBar addSubview:naviBar];
    
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat editCancelWidth = [[NSBundle LFME_localizedStringForKey:@"_LFME_cancelButtonTitle"] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *_edit_cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, editCancelWidth, naviHeight)];
    _edit_cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_edit_cancelButton setTitle:[NSBundle LFME_localizedStringForKey:@"_LFME_cancelButtonTitle"] forState:UIControlStateNormal];
    _edit_cancelButton.titleLabel.font = font;
    [_edit_cancelButton setTitleColor:self.cancelButtonTitleColorNormal forState:UIControlStateNormal];
    [_edit_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [naviBar addSubview:_edit_cancelButton];
    
    CGFloat editOkWidth = [[NSBundle LFME_localizedStringForKey:@"_LFME_oKButtonTitle"] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    
    UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - editOkWidth-margin, 0, editOkWidth, naviHeight)];
    _edit_finishButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_edit_finishButton setTitle:[NSBundle LFME_localizedStringForKey:@"_LFME_oKButtonTitle"] forState:UIControlStateNormal];
    _edit_finishButton.titleLabel.font = font;
    [_edit_finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_edit_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [naviBar addSubview:_edit_finishButton];
    
    [self.view addSubview:_edit_naviBar];
}

- (void)configBottomToolBar
{
    LFEditToolbarType toolbarType = 0;
    if (self.operationType&LFVideoEditOperationType_draw) {
        toolbarType |= LFEditToolbarType_draw;
    }
    if (self.operationType&LFVideoEditOperationType_sticker) {
        toolbarType |= LFEditToolbarType_sticker;
    }
    if (self.operationType&LFVideoEditOperationType_text) {
        toolbarType |= LFEditToolbarType_text;
    }
    if (self.operationType&LFVideoEditOperationType_audio) {
        toolbarType |= LFEditToolbarType_audio;
    }
    if (@available(iOS 9.0, *)) {
        if (self.operationType&LFVideoEditOperationType_filter) {
            toolbarType |= LFEditToolbarType_filter;
        }
    }
    if (self.operationType&LFVideoEditOperationType_rate) {
        toolbarType |= LFEditToolbarType_rate;
    }
    if (self.operationType&LFVideoEditOperationType_clip) {
        toolbarType |= LFEditToolbarType_clip;
    }
    
    _edit_toolBar = [[LFEditToolbar alloc] initWithType:toolbarType];
    _edit_toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _edit_toolBar.delegate = self;
    [_edit_toolBar setDrawSliderColorAtIndex:1]; /** 红色 */
    /** 绘画颜色一致 */
    [_EditingView setDrawColor:[_edit_toolBar drawSliderCurrentColor]];
    [self.view addSubview:_edit_toolBar];
}

- (void)configDefaultOperation
{
    if (self.initSelectedOperationType > 0) {
        
        __weak __typeof__(self) weakSelf = self;
        BOOL (^containOperation)(LFVideoEditOperationType type) = ^(LFVideoEditOperationType type){
            if (weakSelf.operationType&type && weakSelf.initSelectedOperationType&type) {
                weakSelf.initSelectedOperationType ^= type;
                return YES;
            }
            return NO;
        };
        
        if (containOperation(LFVideoEditOperationType_clip)) {
            [_EditingView setIsClipping:YES animated:NO];
            [self changeClipMenu:YES animated:NO];
//            [_EditingView resetClipping:YES];
        } else {
            if (containOperation(LFVideoEditOperationType_draw)) {
                [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_draw];
            } else if (containOperation(LFVideoEditOperationType_sticker)) {
                [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_sticker];
            } else if (containOperation(LFVideoEditOperationType_text)) {
                [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_text];
            } else if (containOperation(LFVideoEditOperationType_audio)) {
                [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_audio];
            } else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
                if (containOperation(LFVideoEditOperationType_filter)) {
                    if (@available(iOS 9.0, *)) {
                        [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_filter];
                    }
                }
#pragma clang diagnostic pop
                else if (containOperation(LFVideoEditOperationType_rate)) {
                    [_edit_toolBar selectMainMenuIndex:LFEditToolbarType_rate];
                }
            self.initSelectedOperationType = 0;
        }
    }
}

#pragma mark - 顶部栏(action)
- (void)singlePressed
{
    [self singlePressedWithAnimated:YES];
}
- (void)singlePressedWithAnimated:(BOOL)animated
{
    if (!(_EditingView.isDrawing || _EditingView.isSplashing)) {
        _isHideNaviBar = !_isHideNaviBar;
        [self changedBarStateWithAnimated:animated];
    }
}
- (void)cancelButtonClick
{
    [_EditingView pauseVideo];
    if ([self.delegate respondsToSelector:@selector(lf_VideoEditingController:didCancelPhotoEdit:)]) {
        [self.delegate lf_VideoEditingController:self didCancelPhotoEdit:self.videoEdit];
    }
}

- (void)finishButtonClick
{
    if (self.maxClippingDuration < (int)[_EditingView getEditVideoDuration]) {
        [[[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"裁剪的视频时长仍大于限制时长" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return;
    }
    [self showProgressVideoHUD];
    /** 取消贴图激活 */
    [_EditingView stickerDeactivated];
    /** 处理编辑图片 */
    __block LFVideoEdit *videoEdit = nil;
    NSDictionary *data = [_EditingView photoEditData];
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(weakSelf) strongSelf = weakSelf;
                [strongSelf->_EditingView exportAsynchronouslyWithTrimVideo:^(NSURL *trimURL, NSError *error) {
                    videoEdit = [[LFVideoEdit alloc] initWithEditAsset:weakSelf.asset editFinalURL:trimURL data:data];
                    if (error) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        [[[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:[NSBundle LFME_localizedStringForKey:@"_LFME_alertViewCancelTitle"] otherButtonTitles:nil] show];
#pragma clang diagnostic pop
                    }
                    if ([weakSelf.delegate respondsToSelector:@selector(lf_VideoEditingController:didFinishPhotoEdit:)]) {
                        [weakSelf.delegate lf_VideoEditingController:weakSelf didFinishPhotoEdit:videoEdit];
                    }
                    [weakSelf hideProgressHUD];
                } progress:^(float progress) {
                    [weakSelf setProgress:progress];
                }];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([weakSelf.delegate respondsToSelector:@selector(lf_VideoEditingController:didFinishPhotoEdit:)]) {
                    [weakSelf.delegate lf_VideoEditingController:weakSelf didFinishPhotoEdit:videoEdit];
                }
                [weakSelf hideProgressHUD];
            });
        }
    });
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:_EditingView]) {
        return YES;
    }
    return NO;
}

#pragma mark - LFEditToolbarDelegate 底部栏(action)

/** 一级菜单点击事件 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar mainDidSelectAtIndex:(NSUInteger)index
{
    /** 取消贴图激活 */
    [_EditingView stickerDeactivated];
    
    switch (index) {
        case LFEditToolbarType_draw:
        {
            /** 关闭涂抹 */
            _EditingView.splashEnable = NO;
            /** 打开绘画 */
            _EditingView.drawEnable = !_EditingView.drawEnable;
        }
            break;
        case LFEditToolbarType_sticker:
        {
            [self singlePressed];
            [self changeStickerMenu:YES animated:YES];
        }
            break;
        case LFEditToolbarType_text:
        {
            [self showTextBarController:nil];
        }
            break;
        case LFEditToolbarType_splash:
        {
            /** 关闭绘画 */
            _EditingView.drawEnable = NO;
            /** 打开涂抹 */
            _EditingView.splashEnable = !_EditingView.splashEnable;
        }
            break;
        case LFEditToolbarType_audio:
        {
            /** 音轨编辑UI */
            [self showAudioTrackBar];
        }
            break;
        case LFEditToolbarType_filter:
        {
            [self singlePressed];
            [self changeFilterMenu:YES animated:YES];
        }
            break;
        case LFEditToolbarType_clip:
        {
            [_EditingView setIsClipping:YES animated:YES];
            [self changeClipMenu:YES];
        }
            break;
        case LFEditToolbarType_rate:
        {
            editToolbar.rate = _EditingView.rate;
        }
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-撤销 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidRevokeAtIndex:(NSUInteger)index
{
    switch (index) {
        case LFEditToolbarType_draw:
        {
            [_EditingView drawUndo];
        }
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            [_EditingView splashUndo];
        }
            break;
        case LFEditToolbarType_audio:
            break;
        case LFEditToolbarType_clip:
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-按钮 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidSelectAtIndex:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case LFEditToolbarType_draw:
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            _EditingView.splashState = indexPath.row == 1;
        }
            break;
        case LFEditToolbarType_audio:
            break;
        case LFEditToolbarType_clip:
            break;
        default:
            break;
    }
}
/** 撤销允许权限获取 */
- (BOOL)lf_editToolbar:(LFEditToolbar *)editToolbar canRevokeAtIndex:(NSUInteger)index
{
    BOOL canUndo = NO;
    switch (index) {
        case LFEditToolbarType_draw:
        {
            canUndo = [_EditingView drawCanUndo];
        }
            break;
        case LFEditToolbarType_sticker:
            break;
        case LFEditToolbarType_text:
            break;
        case LFEditToolbarType_splash:
        {
            canUndo = [_EditingView splashCanUndo];
        }
            break;
        case LFEditToolbarType_audio:
            break;
        case LFEditToolbarType_clip:
            break;
        default:
            break;
    }
    
    return canUndo;
}
/** 二级菜单滑动事件-绘画 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar drawColorDidChange:(UIColor *)color
{
    [_EditingView setDrawColor:color];
}
/** 二级菜单滑动事件-速率 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar rateDidChange:(float)value
{
    _EditingView.rate = value;
}

#pragma mark - LFStickerBarDelegate
- (void)lf_stickerBar:(LFStickerBar *)lf_stickerBar didSelectImage:(UIImage *)image
{
    if (image) {
        LFStickerItem *item = [LFStickerItem new];
        item.image = image;
        [_EditingView createSticker:item];
    }
    [self singlePressed];
}

#pragma mark - LFTextBarDelegate
/** 完成回调 */
- (void)lf_textBarController:(LFTextBar *)textBar didFinishText:(LFText *)text
{
    if (text) {
        LFStickerItem *item = [LFStickerItem new];
        item.text = text;
        /** 判断是否更改文字 */
        if (textBar.showText) {
            [_EditingView changeSelectSticker:item];
        } else {
            [_EditingView createSticker:item];
        }
    } else {
        if (textBar.showText) { /** 文本被清除，删除贴图 */
            [_EditingView removeSelectStickerView];
        }
    }
    [self lf_textBarControllerDidCancel:textBar];
}
/** 取消回调 */
- (void)lf_textBarControllerDidCancel:(LFTextBar *)textBar
{
    /** 显示顶部栏 */
    _isHideNaviBar = NO;
    [self changedBarState];
    /** 更改文字情况才重新激活贴图 */
    if (textBar.showText) {
        [_EditingView activeSelectStickerView];
    }
    [textBar resignFirstResponder];
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        textBar.y = self.view.height;
    } completion:^(BOOL finished) {
        [textBar removeFromSuperview];
    }];
}

#pragma mark - LFAudioTrackBarDelegate
/** 完成回调 */
- (void)lf_audioTrackBar:(LFAudioTrackBar *)audioTrackBar didFinishAudioUrls:(NSArray <LFAudioItem *> *)audioUrls
{
    _EditingView.audioUrls = audioUrls;
    [self lf_audioTrackBarDidCancel:audioTrackBar];
}
/** 取消回调 */
- (void)lf_audioTrackBarDidCancel:(LFAudioTrackBar *)audioTrackBar
{
    [_EditingView playVideo];
    /** 显示顶部栏 */
    _isHideNaviBar = NO;
    [self changedBarState];
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        audioTrackBar.y = self.view.height;
    } completion:^(BOOL finished) {
        [audioTrackBar removeFromSuperview];
        
        self->singleTapRecognizer.enabled = YES;
    }];
}

#pragma mark - LFVideoClipToolbarDelegate
/** 取消 */
- (void)lf_videoClipToolbarDidCancel:(LFVideoClipToolbar *)clipToolbar
{
    [self cancelButtonClick];
    
//    if (self.initSelectedOperationType == 0 && self.operationType == LFVideoEditOperationType_clip && self.defaultOperationType == LFVideoEditOperationType_clip) { /** 证明initSelectedOperationType已消耗完毕，defaultOperationType是有值的。只有LFVideoEditOperationType_clip的情况，无需返回，直接完成整个编辑 */
//        [self cancelButtonClick];
//    } else {
//        [_EditingView cancelClipping:YES];
//        [self changeClipMenu:NO];
//        [self configDefaultOperation];
//    }
}
/** 完成 */
- (void)lf_videoClipToolbarDidFinish:(LFVideoClipToolbar *)clipToolbar
{
    [self finishButtonClick];
    
//    if (self.initSelectedOperationType == 0 && self.operationType == LFVideoEditOperationType_clip && self.defaultOperationType == LFVideoEditOperationType_clip) { /** 证明initSelectedOperationType已消耗完毕，defaultOperationType是有值的。只有LFVideoEditOperationType_clip的情况，无需返回，直接完成整个编辑 */
//        [self finishButtonClick];
//    } else {
//        [_EditingView setIsClipping:NO animated:YES];
//        [self changeClipMenu:NO];
//        [self configDefaultOperation];
//    }
}

#pragma mark - LFPhotoEditDelegate
#pragma mark - LFPhotoEditDrawDelegate
/** 开始绘画 */
- (void)lf_photoEditDrawBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束绘画 */
- (void)lf_photoEditDrawEnded
{
    /** 撤销生效 */
    if (_EditingView.drawCanUndo) [_edit_toolBar setRevokeAtIndex:LFEditToolbarType_draw];
    
    __weak __typeof__(self) weakSelf = self;
    lf_me_dispatch_cancel(self.delayCancelBlock);
    self.delayCancelBlock = lf_dispatch_block_t(1.f, ^{
        weakSelf.isHideNaviBar = NO;
        [weakSelf changedBarState];
    });
}

#pragma mark - LFPhotoEditStickerDelegate
/** 点击贴图 isActive=YES 选中的情况下点击 */
- (void)lf_photoEditStickerDidSelectViewIsActive:(BOOL)isActive
{
    _isHideNaviBar = NO;
    [self changedBarState];
    if (isActive) { /** 选中的情况下点击 */
        LFStickerItem *item = [_EditingView getSelectSticker];
        if (item.text) {
            [self showTextBarController:item.text];
        }
    }
}

#pragma mark - LFPhotoEditSplashDelegate
/** 开始模糊 */
- (void)lf_photoEditSplashBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束模糊 */
- (void)lf_photoEditSplashEnded
{
    /** 撤销生效 */
    if (_EditingView.splashCanUndo) [_edit_toolBar setRevokeAtIndex:LFEditToolbarType_splash];
    
    __weak __typeof__(self) weakSelf = self;
    lf_me_dispatch_cancel(self.delayCancelBlock);
    self.delayCancelBlock = lf_dispatch_block_t(1.f, ^{
        weakSelf.isHideNaviBar = NO;
        [weakSelf changedBarState];
    });
}

#pragma mark - private
- (void)changedBarState
{
    [self changedBarStateWithAnimated:YES];
}
- (void)changedBarStateWithAnimated:(BOOL)animated
{
    lf_me_dispatch_cancel(self.delayCancelBlock);
    /** 隐藏贴图菜单 */
    [self changeStickerMenu:NO animated:animated];
    /** 隐藏滤镜菜单 */
    [self changeFilterMenu:NO animated:animated];
    
    if (animated) {
        [UIView animateWithDuration:.25f animations:^{
            CGFloat alpha = self->_isHideNaviBar ? 0.f : 1.f;
            self->_edit_naviBar.alpha = alpha;
            self->_edit_toolBar.alpha = alpha;
        }];
    } else {
        CGFloat alpha = _isHideNaviBar ? 0.f : 1.f;
        _edit_naviBar.alpha = alpha;
        _edit_toolBar.alpha = alpha;
    }
}

- (void)changeClipMenu:(BOOL)isChanged
{
    [self changeClipMenu:isChanged animated:YES];
}

- (void)changeClipMenu:(BOOL)isChanged animated:(BOOL)animated
{
    if (isChanged) {
        /** 关闭所有编辑 */
        [_EditingView photoEditEnable:NO];
        /** 切换菜单 */
        [self.view addSubview:self.edit_clipping_toolBar];
        
        [self.view addSubview:self.restoreButton];
        
        if (animated) {
            [UIView animateWithDuration:0.25f animations:^{
                self->_edit_clipping_toolBar.alpha = 1.f;
                self->_restoreButton.alpha = 1.f;
            }];
        } else {
            _edit_clipping_toolBar.alpha = 1.f;
            self->_restoreButton.alpha = 1.f;
        }
        singleTapRecognizer.enabled = NO;
        [self singlePressedWithAnimated:animated];
    } else {
        if (_edit_clipping_toolBar.superview == nil) return;
        
        /** 开启编辑 */
        [_EditingView photoEditEnable:YES];
        
        singleTapRecognizer.enabled = YES;
        if (animated) {
            [UIView animateWithDuration:.25f animations:^{
                self->_edit_clipping_toolBar.alpha = 0.f;
                self->_restoreButton.alpha = 0.f;
            } completion:^(BOOL finished) {
                [self->_edit_clipping_toolBar removeFromSuperview];
                [self->_restoreButton removeFromSuperview];
            }];
        } else {
            [_edit_clipping_toolBar removeFromSuperview];
            [self->_restoreButton removeFromSuperview];
        }
        
        [self singlePressedWithAnimated:animated];
    }
}

- (void)changeStickerMenu:(BOOL)isChanged animated:(BOOL)animated
{
    if (isChanged) {
        [self.view addSubview:self.edit_sticker_toolBar];
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height-frame.size.height;
        if (animated) {
            [UIView animateWithDuration:.25f animations:^{
                self->_edit_sticker_toolBar.frame = frame;
            }];
        } else {
            _edit_sticker_toolBar.frame = frame;
        }
    } else {
        if (_edit_sticker_toolBar.superview == nil) return;
        
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height;
        if (animated) {
            [UIView animateWithDuration:.25f animations:^{
                self->_edit_sticker_toolBar.frame = frame;
            } completion:^(BOOL finished) {
                [self->_edit_sticker_toolBar removeFromSuperview];
                self->_edit_sticker_toolBar = nil;
            }];
        } else {
            [_edit_sticker_toolBar removeFromSuperview];
            _edit_sticker_toolBar = nil;
        }
    }
}

- (void)showTextBarController:(LFText *)text
{
    LFTextBar *textBar = [[LFTextBar alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, self.view.height) layout:^(LFTextBar *textBar) {
        textBar.oKButtonTitleColorNormal = self.oKButtonTitleColorNormal;
        textBar.cancelButtonTitleColorNormal = self.cancelButtonTitleColorNormal;
        textBar.oKButtonTitle = [NSBundle LFME_localizedStringForKey:@"_LFME_oKButtonTitle"];
        textBar.cancelButtonTitle = [NSBundle LFME_localizedStringForKey:@"_LFME_cancelButtonTitle"];
        textBar.customTopbarHeight = self->_edit_naviBar.height;
        textBar.naviHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    }];
    textBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textBar.showText = text;
    textBar.delegate = self;
    
    [self.view addSubview:textBar];
    
    [textBar becomeFirstResponder];
    [UIView animateWithDuration:0.25f animations:^{
        textBar.y = 0;
    } completion:^(BOOL finished) {
        /** 隐藏顶部栏 */
        self->_isHideNaviBar = YES;
        [self changedBarState];
    }];
}

#pragma mark - 音轨菜单
- (void)showAudioTrackBar
{
    LFAudioTrackBar *audioTrackBar = [[LFAudioTrackBar alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, self.view.height) layout:^(LFAudioTrackBar *audioTrackBar) {
        audioTrackBar.oKButtonTitleColorNormal = self.oKButtonTitleColorNormal;
        audioTrackBar.cancelButtonTitleColorNormal = self.cancelButtonTitleColorNormal;
        audioTrackBar.oKButtonTitle = [NSBundle LFME_localizedStringForKey:@"_LFME_oKButtonTitle"];
        audioTrackBar.cancelButtonTitle = [NSBundle LFME_localizedStringForKey:@"_LFME_cancelButtonTitle"];
        audioTrackBar.customTopbarHeight = self->_edit_naviBar.height;
        audioTrackBar.naviHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
        if (@available(iOS 11.0, *)) {
            audioTrackBar.customToolbarHeight = 44.f+self.navigationController.view.safeAreaInsets.bottom;
        } else {
            audioTrackBar.customToolbarHeight = 44.f;
        }
    }];
    
    audioTrackBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    audioTrackBar.delegate = self;
    audioTrackBar.audioUrls = _EditingView.audioUrls;
    
    [self.view addSubview:audioTrackBar];
    
    [UIView animateWithDuration:0.25f animations:^{
        audioTrackBar.y = 0;
    } completion:^(BOOL finished) {
        /** 隐藏顶部栏 */
        self->_isHideNaviBar = YES;
        [self changedBarState];
        self->singleTapRecognizer.enabled = NO;
        [self->_EditingView resetVideoDisplay];
    }];
}

- (void)changeFilterMenu:(BOOL)isChanged animated:(BOOL)animated
{
    if (isChanged) {
        [self.view addSubview:self.edit_filter_toolBar];
        CGRect frame = self.edit_filter_toolBar.frame;
        frame.origin.y = self.view.height-frame.size.height;
        if (animated) {
            [UIView animateWithDuration:.25f animations:^{
                self->_edit_filter_toolBar.frame = frame;
            }];
        } else {
            _edit_filter_toolBar.frame = frame;
        }
    } else {
        if (_edit_filter_toolBar.superview == nil) return;
        
        CGRect frame = self.edit_filter_toolBar.frame;
        frame.origin.y = self.view.height;
        if (animated) {
            [UIView animateWithDuration:.25f animations:^{
                self->_edit_filter_toolBar.frame = frame;
            } completion:^(BOOL finished) {
                [self->_edit_filter_toolBar removeFromSuperview];
                self->_edit_filter_toolBar = nil;
            }];
        } else {
            [_edit_filter_toolBar removeFromSuperview];
            _edit_filter_toolBar = nil;
        }
    }
}

/**
 还原

 @param btn 按钮
 */
-(void)restoreButton:(UIButton *)btn {
    [_EditingView resetClipping:YES];
}

#pragma mark - 还原按钮（懒加载）
- (UIButton *)restoreButton {
    if (_restoreButton == nil) {
        _restoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat y = self.view.height - 55;
        if (LF_IS_IPHONE_X) {
            y = self.view.height - 75;
        }
        _restoreButton.frame = CGRectMake(15, y, 40, 40);
        _restoreButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_restoreButton setTitle:@"还原" forState:UIControlStateNormal];
        [_restoreButton setTitleColor:self.editToolbarTitleColorNormal?self.editToolbarTitleColorNormal:[UIColor whiteColor] forState:UIControlStateNormal];
        [_restoreButton addTarget:self action:@selector(restoreButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _restoreButton;
}

#pragma mark - 贴图菜单（懒加载）
- (LFStickerBar *)edit_sticker_toolBar
{
    if (_edit_sticker_toolBar == nil) {
        CGFloat row = 2;
        CGFloat w=self.view.width, h=lf_stickerSize*row+lf_stickerMargin*(row+1);
        if (@available(iOS 11.0, *)) {
            h += self.navigationController.view.safeAreaInsets.bottom;
        }
        _edit_sticker_toolBar = [[LFStickerBar alloc] initWithFrame:CGRectMake(0, self.view.height, w, h) resourcePath:self.stickerPath];
        _edit_sticker_toolBar.delegate = self;
    }
    return _edit_sticker_toolBar;
}

#pragma mark - 剪切底部栏（懒加载）
- (UIView *)edit_clipping_toolBar
{
    if (_edit_clipping_toolBar == nil) {
        CGFloat h = 44.f;
        if (@available(iOS 11.0, *)) {
            h += self.navigationController.view.safeAreaInsets.bottom;
        }
        if (LF_IS_IPHONE_X) {
            h = 84;
        }
        _edit_clipping_toolBar = [[LFVideoClipToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, h)];
        _edit_clipping_toolBar.alpha = 0.f;
//        _edit_clipping_toolBar.editNaviBgColor = self.editNaviBgColor;
//        _edit_clipping_toolBar.editOKButtonTitleColorNormal = self.editOKButtonTitleColorNormal;
//        _edit_clipping_toolBar.editCancelButtonTitleColorNormal = self.editCancelButtonTitleColorNormal;
        _edit_clipping_toolBar.delegate = self;
        
        [_edit_clipping_toolBar refreshViewColor];
    }
    return _edit_clipping_toolBar;
}

#pragma mark - 滤镜菜单（懒加载）
- (JRFilterBar *)edit_filter_toolBar
{
    if (_edit_filter_toolBar == nil) {
        CGFloat w=self.view.width, h=100.f;
        if (@available(iOS 11.0, *)) {
            h += self.navigationController.view.safeAreaInsets.bottom;
        }
        _edit_filter_toolBar = [[JRFilterBar alloc] initWithFrame:CGRectMake(0, self.view.height, w, h) defalutEffectType:[_EditingView getFilterType] dataSource:@[
                                                                                                                                                                    @(LFFilterNameType_None),
                                                                                                                                                                    @(LFFilterNameType_LinearCurve),
                                                                                                                                                                    @(LFFilterNameType_Chrome),
                                                                                                                                                                    @(LFFilterNameType_Fade),
                                                                                                                                                                    @(LFFilterNameType_Instant),
                                                                                                                                                                    @(LFFilterNameType_Mono),
                                                                                                                                                                    @(LFFilterNameType_Noir),
                                                                                                                                                                    @(LFFilterNameType_Process),
                                                                                                                                                                    @(LFFilterNameType_Tonal),
                                                                                                                                                                    @(LFFilterNameType_Transfer),
                                                                                                                                                                    @(LFFilterNameType_CurveLinear),
                                                                                                                                                                    @(LFFilterNameType_Invert),
                                                                                                                                                                    @(LFFilterNameType_Monochrome),                                                                                    ]];
        CGFloat rgb = 34 / 255.0;
        _edit_filter_toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.85];
        _edit_filter_toolBar.defaultColor = self.cancelButtonTitleColorNormal;
        _edit_filter_toolBar.selectColor = self.oKButtonTitleColorNormal;
        _edit_filter_toolBar.delegate = self;
        _edit_filter_toolBar.dataSource = self;
        
        
    }
    return _edit_filter_toolBar;
}

#pragma mark - JRFilterBarDelegate
- (void)jr_filterBar:(JRFilterBar *)jr_filterBar didSelectImage:(UIImage *)image effectType:(NSInteger)effectType
{
    [_EditingView changeFilterType:effectType];
}

#pragma mark - JRFilterBarDataSource
- (UIImage *)jr_async_filterBarImageForEffectType:(NSInteger)type
{
    if (_filterSmallImage == nil) {
        CGSize videoSize = [self.asset videoNaturalSize];
        CGSize size = CGSizeZero;
        size.width = MIN(JR_FilterBar_MAX_WIDTH*[UIScreen mainScreen].scale, videoSize.width);
        size.height = ((int)(videoSize.height*size.width/videoSize.width))*1.f;
        self.filterSmallImage = [self.asset lf_firstImageWithSize:size error:nil];
    }
    return lf_filterImageWithType(self.filterSmallImage, type);
}

- (NSString *)jr_filterBarNameForEffectType:(NSInteger)type
{
    NSString *defaultName = lf_descWithType(type);
    if (defaultName) {
        NSString *languageName = [@"_LFME_filter_" stringByAppendingString:defaultName];
        return [NSBundle LFME_localizedStringForKey:languageName];
    }
    return @"";
}

@end
