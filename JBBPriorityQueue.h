//
//  JBBPriorityQueue.h
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//
//  BSD License, Use at your own risk
//

typedef NSComparisonResult (^JBBComparisonBlock)(id lhs, id rhs);

@protocol JBBComparisonProtocol <NSObject>
- (NSComparisonResult)compare:(id)rhs;
@end

@protocol JBBBoxedComparisonProtocol <NSObject>
- (NSNumber *)compare:(id)rhs;
@end

@interface JBBPriorityQueue : NSObject
// non-synthesized properties

@property (readonly) CFIndex count;
@property (readonly) BOOL isEmpty;

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock;
- (id)initWithClass:(Class)classToStore;
- (id)initWithClass:(Class)classToStore ordering:(NSComparisonResult)ordering;

// ruby style interface
- (void)push:(id)obj;
- (void)pushObjects:(NSArray *)objs;
- (id)pop;
- (id)peek;

// objective-c style interface
- (void)addObject:(id)obj;
- (void)addObjects:(NSArray *)objs;
- (id)removeFirstObject;
- (id)firstObject;

- (BOOL)isEqualToQueue:(JBBPriorityQueue *)otherQueue;
@end

