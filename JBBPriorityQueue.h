//
//  JBBPriorityQueue.h
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

// The idea for this class is shamelessly stolen from Mike Ash.
// His class ChemicalBurnOrderedQueue is the inspiration.
// The difference here is that we expect the priority values
// to be classes and they should be sorted using "compareToNode:".

// This difference will allow this PriorityQueue to be used
// in both Cocoa and MacRuby easily. This class is currently
// only available to Garbage Collected code.

// In the future it is possible this framework will be x86_64 only,
// for the time being it is also i386.

enum JBBHeapType {
  JBBMinimumHeap = 1,
  JBBMaximumHeap,
};

@protocol JBBPQNodeProtocol <NSObject>
@required
- (NSNumber *)compareToNode:(id)rhs;
@end

@interface JBBPriorityQueue : NSObject {
  __strong CFBinaryHeapRef mObjs;
  NSMutableArray *mObjsArray;
  BOOL mHeapified;
}

@property (readonly) CFIndex count;

- (id)initWithHeapType:(enum JBBHeapType)heapType;
- (void)push:(id)obj;
- (void)pushObjects:(NSArray *)objs;
- (id)pop;
- (BOOL)isEmpty;
@end

