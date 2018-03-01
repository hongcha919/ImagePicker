//
//  CustomPhotoEditingController.m
//  LFImagePickerController
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#import "CustomPhotoEditingController.h"

#import "LFMediaEditingHeader.h"
#import "UIView+LFMEFrame.h"
#import "LFMediaEditingType.h"

#import "CustomEditingView.h"
#import "LFEditToolbar.h"
#import "LFStickerBar.h"
#import "LFTextBar.h"
#import "CustomClipToolbar.h"

@interface CustomPhotoEditingController () <CustomClipToolbarDelegate, LFPhotoEditDelegate, CustomEditingViewDelegate,  UIGestureRecognizerDelegate>
{
    /** 编辑模式 */
    CustomEditingView *_EditingView;
    
    UIView *_edit_naviBar;
    
    /** 剪切菜单 */
    CustomClipToolbar *_edit_clipping_toolBar;
}

@end

@implementation CustomPhotoEditingController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isHiddenNavBar = YES;
        self.isHiddenStatusBar = YES;
        
        self.cutType = 3;
        self.aspectWHRatio = 0;
    }
    return self;
}

- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation
{
    self = [super initWithOrientation:orientation];
    if (self) {
        _operationType = LFPhotoEditOperationType_All;
    }
    return self;
}

- (void)setEditImage:(UIImage *)editImage
{
    _editImage = editImage;
    /** GIF图片仅支持编辑第一帧 */
    if (editImage.images.count) {
        editImage = editImage.images.firstObject;
    }
    _EditingView.image = editImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self configScrollView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    
//    [_edit_clipping_toolBar hiddenResetButton:(self.cutType<=1)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (_edit_naviBar) {
        if (@available(iOS 11.0, *)) {
            _edit_naviBar.height = kCustomTopbarHeight_iOS11;
        } else {
            _edit_naviBar.height = kCustomTopbarHeight;
        }
    }
}

- (void)dealloc{
    [self hideProgressHUD];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建视图
- (void)configScrollView
{
    _EditingView = [[CustomEditingView alloc] initWithFrame:self.view.bounds];
    _EditingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _EditingView.editDelegate = self;
    _EditingView.clippingDelegate = self;
    _EditingView.cutType = self.cutType;
    _EditingView.customMinZoomScale = self.customMinZoomScale;
    
    if (_photoEdit) {
        [self setEditImage:_photoEdit.editImage];
        _EditingView.photoEditData = _photoEdit.editData;
    } else {
        [self setEditImage:_editImage];
    }
    
    [self.view addSubview:_EditingView];
}

- (void)configCustomNaviBar
{
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat margin = 0, topbarHeight = 0;
    CGFloat naviHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    if (self.isHiddenNavBar) {
        if (@available(iOS 11.0, *)) {
            topbarHeight = kCustomTopbarHeight_iOS11;
        } else {
            topbarHeight = kCustomTopbarHeight;
        }
        
        _edit_naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, topbarHeight)];
        _edit_naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _edit_naviBar.backgroundColor = self.editNaviBgColor;
        
        UIView *naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, topbarHeight-naviHeight, _edit_naviBar.frame.size.width, naviHeight)];
        naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [_edit_naviBar addSubview:naviBar];
        
        CGFloat editCancelWidth = [self.cancelButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
        UIButton *_edit_cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, editCancelWidth, naviHeight)];
        _edit_cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_edit_cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
        _edit_cancelButton.titleLabel.font = font;
        [_edit_cancelButton setTitleColor:self.cancelButtonTitleColorNormal forState:UIControlStateNormal];
        [_edit_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [naviBar addSubview:_edit_cancelButton];
        
        CGFloat editOkWidth = [self.oKButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
        
        UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - editOkWidth-margin, 0, editOkWidth, naviHeight)];
        _edit_finishButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_edit_finishButton setTitle:self.oKButtonTitle forState:UIControlStateNormal];
        _edit_finishButton.titleLabel.font = font;
        [_edit_finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
        [_edit_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [naviBar addSubview:_edit_finishButton];
        
        [self.view addSubview:_edit_naviBar];
    } else {
        CGFloat editOkWidth = [self.oKButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 40;
        
        UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, editOkWidth, naviHeight)];
        _edit_finishButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

        [_edit_finishButton setTitle:self.oKButtonTitle forState:UIControlStateNormal];
        _edit_finishButton.titleLabel.font = font;
        [_edit_finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
        [_edit_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_edit_finishButton];
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (void)configBottomToolBar
{
    [_EditingView setIsClipping:YES animated:YES whRatio:self.aspectWHRatio];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_EditingView setAspectWHRatio:self.aspectWHRatio];
        
        /** 关闭所有编辑 */
        [_EditingView photoEditEnable:NO];
        /** 切换菜单 */
        self.edit_clipping_toolBar.alpha = 1.f;
        [self.view addSubview:self.edit_clipping_toolBar];
        _edit_clipping_toolBar.enableReset = [self enableReset];
    });
//    [self lf_clipToolbarDidReset:_edit_clipping_toolBar];
}

#pragma mark - 顶部栏(action)
- (void)cancelButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_PhotoEditingController:didCancelPhotoEdit:)]) {
        [self.delegate lf_PhotoEditingController:self didCancelPhotoEdit:self.photoEdit];
    }
}

- (void)finishButtonClick
{
    [self showProgressHUD];
    /** 取消贴图激活 */
    [_EditingView stickerDeactivated];
    
    /** 处理编辑图片 */
    __block LFPhotoEdit *photoEdit = nil;
    NSDictionary *data = [_EditingView photoEditData];
    UIImage *image = nil;
    if (self.cutType<2 || data) {
        image = [_EditingView createEditImage];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (data) {
            photoEdit = [[LFPhotoEdit alloc] initWithEditImage:self.editImage previewImage:image data:data];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(lf_PhotoEditingController:didFinishPhotoEdit:)]) {
                [self.delegate lf_PhotoEditingController:self didFinishPhotoEdit:photoEdit];
            }
            [self hideProgressHUD];
        });
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

#pragma mark - 剪切底部栏（懒加载）
- (UIView *)edit_clipping_toolBar
{
    if (_edit_clipping_toolBar == nil) {
        CGFloat h = 44.f;
        if (@available(iOS 11.0, *)) {
            h += self.view.safeAreaInsets.bottom;
        }
        _edit_clipping_toolBar = [[CustomClipToolbar alloc] initWithFrame:CGRectMake(0, self.view.height - h, self.view.width, h)];
        _edit_clipping_toolBar.backgroundColor = self.editToolbarBgColor;
        [_edit_clipping_toolBar.resetButton setTitleColor:self.editToolbarTitleColorNormal forState:UIControlStateNormal];
        [_edit_clipping_toolBar.resetButton setTitleColor:self.editToolbarTitleColorNormal forState:UIControlStateHighlighted];
        [_edit_clipping_toolBar.resetButton setTitleColor:self.editToolbarTitleColorNormal forState:UIControlStateSelected];
        [_edit_clipping_toolBar.resetButton setTitleColor:self.editToolbarTitleColorDisabled forState:UIControlStateDisabled];

        _edit_clipping_toolBar.delegate = self;
    }
    return _edit_clipping_toolBar;
}

#pragma mark - CustomClipToolbarDelegate
/** 重置 */
- (void)lf_clipToolbarDidReset:(CustomClipToolbar *)clipToolbar
{
    [_EditingView reset];
    _edit_clipping_toolBar.enableReset = [self enableReset];
    [_EditingView setAspectWHRatio:self.aspectWHRatio];
}
/** 旋转 */
- (void)lf_clipToolbarDidRotate:(CustomClipToolbar *)clipToolbar
{
    [_EditingView rotate];
    _edit_clipping_toolBar.enableReset = [self enableReset];
}

#pragma mark - CustomEditingViewDelegate
/** 剪裁发生变化后 */
- (void)lf_EditingViewDidEndZooming:(CustomEditingView *)EditingView
{
    _edit_clipping_toolBar.enableReset = [self enableReset];
}
/** 剪裁目标移动后 */
- (void)lf_EditingViewEndDecelerating:(CustomEditingView *)EditingView
{
    _edit_clipping_toolBar.enableReset = [self enableReset];
}

- (BOOL)enableReset
{
    return _EditingView.canReset;
    return self.cutType>1 && _EditingView.canReset;
}

@end

