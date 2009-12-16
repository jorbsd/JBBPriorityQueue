//
//  JBBPriorityQueue.h
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

// The idea for this class is shamelessly stolen from Mike Ash.
// His class ChemicalBurnOrderedQueue is the inspiration.
// The difference here is that we expect compare either with
// compare: or with an Objective-C Block.

// In the future it is possible this framework will be x86_64 only,
// for the time being it is also i386.

typedef NSComparisonResult (^JBBComparisonBlock)(id lhs, id rhs);

enum JBBHeapType {
  JBBMinimumHeap = 1,
  JBBMaximumHeap,
};

// There used to be a protocol here, instead we must check for
// compare: existing at all and check its return type now.
// This implies some runtime magic, so we force the class to be
// stored (or a base class at minimum) to be provided.

// Unfortunately to make life easier we still need dummy protocols.

@protocol JBBComparisonProtocol <NSObject>
- (NSComparisonResult)compare:(id)rhs;
@end

@protocol JBBBoxedComparisonProtocol <NSObject>
- (NSNumber *)compare:(id)rhs;
@end

// Scenarios:
//  * initWithBlock: -- use a provided Block to do the sorting (you can then make your sort min or max)
//  * initWithClass: -- use the Class to see if compare: is boxed
//  * initWithClass:heapType: -- use the Class to see if compare: is boxed, and say whether it should be a min heap or a max heap

@interface JBBPriorityQueue : NSObject {
  __strong CFBinaryHeapRef mObjs;
  NSMutableArray *mObjsArray;
  BOOL mHeapified;
  BOOL mBoxed;
  JBBComparisonBlock mComparisonBlock;
  CFBinaryHeapCallBacks mCallBacks;
}

// synthesized properties

@property (readonly, assign) BOOL mBoxed;
@property (readonly, retain) JBBComparisonBlock mComparisonBlock;

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

