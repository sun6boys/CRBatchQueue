//
//  CRAsyncTask.m
//  CRBatchQueue
//
//  Created by user on 17/4/19.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import "CRAsyncTask.h"

static dispatch_queue_t GlobalAsyncTaskConcurrentQueue(){
    static dispatch_queue_t globalAsyncTaskConcurrentQueue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        globalAsyncTaskConcurrentQueue = dispatch_queue_create("com.CRAsyncTask.taskConcurrent", DISPATCH_QUEUE_CONCURRENT);
    });
    return globalAsyncTaskConcurrentQueue;
}


@interface CRAsyncTask()

@property (nonatomic, copy) dispatch_block_t taskBlock;
@end

@implementation CRAsyncTask

- (instancetype)initWithTaskBlock:(dispatch_block_t)block
{
    self = [super init];
    _taskBlock = block;
    return self;
}

+ (CRAsyncTask *)asyncTaskWithTaskBlock:(dispatch_block_t)taskBlock
{
    return [[self alloc] initWithTaskBlock:taskBlock];
}

- (void)start
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(GlobalAsyncTaskConcurrentQueue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        
        strongSelf.taskBlock ? strongSelf.taskBlock() : nil;
    });
}

- (void)safeStart
{
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(GlobalAsyncTaskConcurrentQueue(), ^{
        __strong typeof(self) strongSelf = weakSelf;
        if(strongSelf == nil) return;
        
        strongSelf.taskBlock ? strongSelf.taskBlock() : nil;
    });
}

@end
