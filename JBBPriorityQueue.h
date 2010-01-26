//
//  JBBPriorityQueue.h
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

typedef int (^JBBComparisonBlock)(id lhs, id rhs);

@protocol JBBComparisonProtocol <NSObject>
- (NSComparisonResult)compare:(id)rhs;
@end

@protocol JBBBoxedComparisonProtocol <NSObject>
- (NSNumber *)compare:(id)rhs;
@end

@interface JBBPriorityQueue : NSObject
// synthesized properties

@property (readonly, assign) BOOL mBoxed;
@property (readonly, copy) JBBComparisonBlock mComparisonBlock;

// non-synthesized properties

@property (readonly) CFIndex count;
@property (readonly) BOOL isEmpty;
@property (readonly) CFBinaryHeapCallBacks *pCallBacks;

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
@end

