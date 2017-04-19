//
//  CRAsyncTask.h
//  CRBatchQueue
//
//  Created by user on 17/4/19.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRAsyncTask : NSObject

//写着玩，其实没什么卵用，不如直接用NSBlockOperation 还可以cancel
+ (CRAsyncTask *)asyncTaskWithTaskBlock:(dispatch_block_t)taskBlock;

- (void)start;

- (void)safeStart;

@end
