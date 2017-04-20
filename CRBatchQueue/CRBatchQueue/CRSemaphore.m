//
//  CRSemaphore.m
//  CRBatchQueue
//
//  Created by user on 17/4/20.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import "CRSemaphore.h"
#import <libkern/OSAtomic.h>

static const uint32_t receipt_unknown = 0 << 0;
static const uint32_t receipt_failure = 1 << 0;
static const uint32_t receipt_success = 1 << 1;

@implementation CRSemaphore
{
    dispatch_semaphore_t semaphore;
    uint32_t atomicFlags;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        semaphore = dispatch_semaphore_create(0);
        atomicFlags = receipt_unknown;
    }
    return self;
}

+ (CRSemaphore *)semaphore
{
    return [[CRSemaphore alloc] init];
}

- (void)signalSuccess
{
    uint32_t mask = receipt_success;
    OSAtomicOr32Barrier(mask, &self->atomicFlags);
    
    dispatch_semaphore_signal(self->semaphore);
}

- (void)signalFailure
{
    uint32_t mask = receipt_failure;
    OSAtomicOr32Barrier(mask, &self->atomicFlags);
    
    
    dispatch_semaphore_signal(self->semaphore);
}

- (BOOL)wait:(NSTimeInterval)timeoutSeconds
{
    NSTimeInterval time;
    if(isless(timeoutSeconds, 0.0))
        time = DISPATCH_TIME_FOREVER;
    else
        time = dispatch_time(DISPATCH_TIME_NOW, timeoutSeconds * NSEC_PER_SEC);
    
    long result = dispatch_semaphore_wait(self->semaphore, time);
    if(result == 0)
        return self->atomicFlags == receipt_success ? YES : NO;
    
    return NO;
}

- (void)reset
{
    atomicFlags = receipt_unknown;
    semaphore = dispatch_semaphore_create(0);
}

@end
