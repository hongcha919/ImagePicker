//
//  LFPreviewBarCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

//#define LF_MEDIAEDIT 1

@class LFAsset;
@interface LFPreviewBarCell : UICollectionViewCell

+ (NSString *)identifier;

@property (nonatomic, strong) LFAsset *asset;
@property (nonatomic, assign) BOOL isSelectedAsset;

@end
