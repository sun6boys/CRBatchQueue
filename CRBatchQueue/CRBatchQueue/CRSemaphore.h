//
//  CRSemaphore.h
//  CRBatchQueue
//
//  Created by user on 17/4/20.
//  Copyright © 2017年 Charon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRSemaphore : NSObject

+ (CRSemaphore *)semaphore;

- (void)signalSuccess;

- (void)signalFailure;

- (BOOL)wait:(NSTimeInterval)timeoutSeconds;

- (void)reset;

@end
