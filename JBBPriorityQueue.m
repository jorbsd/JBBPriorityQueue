//
//  JBBPriorityQueue.mm
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

#import "JBBPriorityQueue.h"

id JBBCFBinaryHeapGetAndRemoveMinimum(CFBinaryHeapRef heap) {
  id returnVal = [(id)CFBinaryHeapGetMinimum(heap) retain];
  CFBinaryHeapRemoveMinimumValue(heap);
  return [returnVal autorelease];
}

id JBBCFBinaryHeapGetAndRemoveMinimumIfPresent(CFBinaryHeapRef heap) {
  id returnVal = nil;
  
  if (!CFBinaryHeapGetMinimumIfPresent(heap, (const void **)&returnVal)) {
    return nil;
  }
  
  [returnVal retain];
  CFBinaryHeapRemoveMinimumValue(heap);
  return [returnVal autorelease];
}

CFComparisonResult JBBMinimumCompareCallBack(const void *lhs, const void *rhs, void *info) {  
  return [[(id <JBBPQNodeProtocol>)lhs compareToNode:(id <JBBPQNodeProtocol>)rhs] intValue];
}

CFComparisonResult JBBMaximumCompareCallBack(const void *lhs, const void *rhs, void *info) {
  return [[(id <JBBPQNodeProtocol>)lhs compareToNode:(id <JBBPQNodeProtocol>)rhs] intValue] * -1;
}

@interface JBBPriorityQueue ()
- (void)buildHeap;
@end

@implementation JBBPriorityQueue
- (id)init {
  return [self initWithHeapType:JBBMinimumHeap];
};

- (id)initWithHeapType:(enum JBBHeapType)heapType {
  self = [super init];
  
  if (!self) {
    return nil;
  }
  
  mHeapified = NO;
  
  /*
   * we are always storing NSObject* or a subclass of it, so we can (ab)use
   * the CFString callbacks and just change the compare callback to suit
   * our needs
   */
  CFBinaryHeapCallBacks binaryHeapCallBacks = kCFStringBinaryHeapCallBacks;
  binaryHeapCallBacks.compare = (heapType == JBBMinimumHeap) ? JBBMinimumCompareCallBack : JBBMaximumCompareCallBack;
  
  mObjs = (CFBinaryHeapRef)CFMakeCollectable(CFBinaryHeapCreate(NULL, 0, &binaryHeapCallBacks, NULL));
  mObjsArray = [[NSMutableArray array] retain];
  
  return self;
}

- (void)dealloc {
  if (mObjs) {
    CFRelease(mObjs);
    mObjs = NULL;
  }
  
  [mObjsArray release];
  mObjsArray = nil;
  
  [super dealloc];
}

- (void)buildHeap {
  if (mHeapified) {
    return;
  }
  
  [mObjsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
    CFBinaryHeapAddValue(mObjs, obj);
  }];
  
  [mObjsArray removeAllObjects];
  
  mHeapified = YES;
}

- (void)push:(id)obj {
  if (mHeapified) {
    CFBinaryHeapAddValue(mObjs, obj);
  } else {
    [mObjsArray addObject:obj];
  }
}

- (void)pushObjects:(NSArray *)objs {
  mHeapified = NO;
  
  [mObjsArray addObjectsFromArray:objs];
}

- (id)pop {
  [self buildHeap];
  
  return JBBCFBinaryHeapGetAndRemoveMinimum(mObjs);
//  return JBBCFBinaryHeapGetAndRemoveMinimumIfPresent(mObjs);
}

- (NSString *)description {
  [self buildHeap];
  
  return [NSString stringWithFormat:@"JBBPriorityQueue = %@", [NSMakeCollectable(CFCopyDescription(mObjs)) autorelease]];
}

- (CFIndex)count {
  return CFBinaryHeapGetCount(mObjs) + [mObjsArray count];
}

- (BOOL)isEmpty {
  return (CFBinaryHeapGetCount(mObjs) == 0) && ([mObjsArray count] == 0);
}
@end

