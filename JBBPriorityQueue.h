//
//  JBBPriorityQueue.h
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

typedef int (^JBBComparisonBlock)(id lhs, id rhs);

enum JBBHeapType {
  JBBMinimumHeap = 1,
  JBBMaximumHeap,
};

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
- (id)initWithClass:(Class)classToStore heapType:(enum JBBHeapType)heapType;
- (void)push:(id)obj;
- (void)pushObjects:(NSArray *)objs;
- (id)pop;
@end

