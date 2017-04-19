//
//  CRBatchQueue.h
//  CRBatchQueue
//
//  Created by user on 17/4/19.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CRBatchTask : NSObject

- (instancetype)initWithExecuteBlock:(dispatch_block_t)block;

- (void)execute;

@end


typedef NS_ENUM(NSInteger,CRBatchExecuteTaskType){
    CRBatchQueueTypeSerial,         //execute at background thread on serial queue
    CRBatchQueueTypeConcurrent,     //execute at background thread on concurrent queue
};

@interface CRBatchQueue : NSObject

- (instancetype)initWithType:(CRBatchExecuteTaskType)type;
+ (instancetype)batchQueueWithType:(CRBatchExecuteTaskType)type;

- (void)appendTask:(CRBatchTask *)task;
- (void)appendTasksFromArray:(NSArray<CRBatchTask *> *)tasks;

- (void)asyncExecuteTasksWithCompletionBlock:(dispatch_block_t)completionBlock;

@end
