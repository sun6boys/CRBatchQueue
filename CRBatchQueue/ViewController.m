//
//  ViewController.m
//  CRBatchQueue
//
//  Created by user on 17/4/19.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import "ViewController.h"
#import "CRBatchQueue.h"
#import <libkern/OSAtomic.h>
#import "CRSemaphore.h"

@interface ViewController ()

@property (nonatomic, strong) CRBatchQueue *concurrentQueue;
@property (nonatomic, strong) CRBatchQueue *serialQueue;
@end

@implementation ViewController
{
    uint32_t atomicFlags;
    dispatch_semaphore_t semaphore;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _concurrentQueue = [[CRBatchQueue alloc] initWithType:CRBatchQueueTypeConcurrent];

    _serialQueue = [[CRBatchQueue alloc] initWithType:CRBatchQueueTypeSerial];
    
    
    uint32_t maskFlag = 25;
    uint32_t returnFlag = OSAtomicOr32Barrier(maskFlag, &atomicFlags);
    
    NSLog(@"returnFlag = %d, atomicFlags = %d",returnFlag,atomicFlags);
    
}


- (IBAction)concurrentTestClick:(id)sender
{
    CRBatchTask *task1 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task1];
    }];
    CRBatchTask *task2 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task2];
    }];
    
    CRBatchTask *task3 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task3];
    }];
    
    CRBatchTask *task4 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task4];
    }];
    
    [_concurrentQueue appendTasksFromArray:@[task1,task2,task3,task4]];
    [_concurrentQueue asyncExecuteTasksWithCompletionBlock:^{
       NSLog(@"任务执行完毕"); 
    }];
}


- (IBAction)serialTestClick:(id)sender
{
    CRBatchTask *task1 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task1];
    }];
    CRBatchTask *task2 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task2];
    }];
    
    CRBatchTask *task3 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task3];
    }];
    
    CRBatchTask *task4 = [[CRBatchTask alloc] initWithExecuteBlock:^{
        [self task4];
    }];
    
    
    [_serialQueue appendTask:task1];
    [_serialQueue appendTask:task2];
    [_serialQueue appendTask:task3];
    [_serialQueue appendTask:task4];
    
    [_serialQueue asyncExecuteTasksWithCompletionBlock:^{
        NSLog(@"任务执行完毕");
    }];
}

- (IBAction)semaphoreTest:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"%@",[self name]);
    });
}


- (void)task1
{
    NSLog(@"任务1执行");
}

- (void)task2
{
    sleep(2);
    NSLog(@"任务2执行");
}

- (void)task3
{
    sleep(1);
    NSLog(@"任务3执行");
}

- (void)task4
{
    NSLog(@"任务4执行");
}



- (NSString *)name
{
    CRSemaphore *semaphoreTes5 = [CRSemaphore semaphore];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [semaphoreTes5 signalFailure];
    });
    BOOL isSuccess = [semaphoreTes5 wait:5];
    
    NSLog(@"%d",isSuccess);
    
    return @"testName";
}
@end
