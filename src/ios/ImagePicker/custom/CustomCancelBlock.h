//
//  CustomCancelBlock.h
//  ImagePicker
//
//  Created by haoqi on 05/02/2018.
//  Copyright © 2018 haoqi. All rights reserved.
//

#ifndef CustomCancelBlock_h
#define CustomCancelBlock_h

typedef void(^custom_dispatch_cancelable_block_t)(BOOL cancel);

custom_dispatch_cancelable_block_t custom_dispatch_block_t(NSTimeInterval delay, void(^block)(void))
{
    __block custom_dispatch_cancelable_block_t cancelBlock = nil;
    custom_dispatch_cancelable_block_t delayBlcok = ^(BOOL cancel){
        if (!cancel) {
            if ([NSThread isMainThread]) {
                block();
            } else {
                dispatch_async(dispatch_get_main_queue(), block);
            }
        }
        cancelBlock = nil;
    };
    cancelBlock = delayBlcok;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (cancelBlock) {
            cancelBlock(NO);
        }
    });
    return delayBlcok;
}

void custom_dispatch_cancel(custom_dispatch_cancelable_block_t block)
{
    if (block) {
        block(YES);
    }
}

#endif /* CustomCancelBlock_h */


