//
//  CRBatchQueue.m
//  CRBatchQueue
//
//  Created by user on 17/4/19.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import "CRBatchQueue.h"

static dispatch_queue_t GlobalBatchSerialQueue(){
    static dispatch_queue_t globalSerialQueue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        globalSerialQueue = dispatch_queue_create("com.CRBatchQueue.ExcuteTaskSerial", DISPATCH_QUEUE_SERIAL);
    });
    return globalSerialQueue;
}

static dispatch_queue_t GlobalBatchConcurrentQueue(){
    static dispatch_queue_t globalBatchConcurrentQueue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        globalBatchConcurrentQueue = dispatch_queue_create("com.CRBatchQueue.ExcuteTaskConcurrent", DISPATCH_QUEUE_CONCURRENT);
    });
    return globalBatchConcurrentQueue;
}

@interface CRBatchTask()

@property (nonatomic, copy) dispatch_block_t executeBlock;
@property (nonatomic, copy) dispatch_block_t executeFinishBlock;
@end

@implementation CRBatchTask
- (instancetype)initWithExecuteBlock:(dispatch_block_t)block
{
    if(block == nil) return nil;
    
    self = [super init];
    _executeBlock = block;
    return self;
}

- (void)execute
{
    self.executeBlock ? self.executeBlock() : nil;
    self.executeFinishBlock ? self.executeFinishBlock() : nil;
}

@end


@interface CRBatchQueue()

@property (nonatomic, assign) CRBatchExecuteTaskType type;
@property (nonatomic, strong) NSMutableArray<CRBatchTask *> *tasks;
@property (atomic, assign) BOOL isExecuting;
@property (nonatomic, strong) NSOperationQueue *currentQueue;
@end

@implementation CRBatchQueue
{
    dispatch_semaphore_t _lock;
}

- (instancetype)initWithType:(CRBatchExecuteTaskType)type
{
    self = [super init];
    _type = type;
    _tasks = [[NSMutableArray alloc] init];
    _lock = dispatch_semaphore_create(1);
    return self;
}

+ (instancetype)batchQueueWithType:(CRBatchExecuteTaskType)type
{
    return [[self alloc] initWithType:type];
}

- (void)appendTask:(CRBatchTask *)task
{
    NSAssert(task != nil, @"task can't be nil");
    NSAssert(self.isExecuting == NO, @"BatchQueue has executing task");
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.tasks addObject:task];
    dispatch_semaphore_signal(_lock);
}

- (void)appendTasksFromArray:(NSArray<CRBatchTask *> *)tasks
{
    NSAssert(self.isExecuting == NO, @"BatchQueue has executing task");
    
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [self.tasks addObjectsFromArray:tasks];
    dispatch_semaphore_signal(_lock);
}

- (void)asyncExecuteTasksWithCompletionBlock:(dispatch_block_t)completionBlock
{
    NSAssert(self.isExecuting == NO, @"BatchQueue has executing task");
    NSAssert(self.tasks > 0, @"tasks is empty");
    
    self.currentQueue = [NSOperationQueue currentQueue];
    
    if (self.type == CRBatchQueueTypeSerial) {
        [self _executeTasksAtGlobalSerialQueueWithCompletionBlock:completionBlock];
    }else if (self.type == CRBatchQueueTypeConcurrent){
        [self _executeTasksAtGlobalCocurrentQueueWithCompletionBlock:completionBlock];
    }
}

- (void)_executeTasksAtGlobalSerialQueueWithCompletionBlock:(dispatch_block_t)completionBlock
{
    self.isExecuting = YES;
    [self.tasks enumerateObjectsUsingBlock:^(CRBatchTask *  _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(GlobalBatchSerialQueue(), ^{
            [task execute];
        });
    }];
    
    dispatch_async(GlobalBatchSerialQueue(), ^{
        [self _sendCompletion:completionBlock];
    });
}

- (void)_executeTasksAtGlobalCocurrentQueueWithCompletionBlock:(dispatch_block_t)completionBlock
{
    dispatch_group_t group = nil;
    
    if(completionBlock && self.tasks.count > 0){
        group = dispatch_group_create();
        [self.tasks enumerateObjectsUsingBlock:^(CRBatchTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dispatch_group_enter(group);
        }];
    }
    dispatch_block_t taskCompletionBlock = ^{
        dispatch_group_leave(group);
    };
    
    self.isExecuting = YES;
    [self.tasks makeObjectsPerformSelector:@selector(setExecuteFinishBlock:) withObject:taskCompletionBlock];
    [self.tasks enumerateObjectsUsingBlock:^(CRBatchTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
       dispatch_async(GlobalBatchConcurrentQueue(), ^{
           [task execute];
       });
    }];
    
    if (group) {
        dispatch_group_notify(group, GlobalBatchConcurrentQueue(), ^{
            [self _sendCompletion:completionBlock];
        });
    }
}

- (void)_sendCompletion:(dispatch_block_t)completionBlock
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:completionBlock];
    [self.currentQueue addOperation:operation];
    [self.tasks removeAllObjects];
    self.isExecuting = NO;
}

@end

