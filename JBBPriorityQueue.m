//
//  JBBPriorityQueue.mm
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

#import "JBBPriorityQueue.h"
#import "NSObject+AssociatedObjects.h"

// Block CallBacks

CFComparisonResult JBBBlockCompare(id lhs, id rhs) {
  JBBComparisonBlock localBlock = [[lhs associatedValueForKey:@"JBBSortDelegate"] mComparisonBlock];

  return localBlock(lhs, rhs);
}

CFComparisonResult JBBBlockCallBack(const void *lhs, const void *rhs, void *info) {
  return JBBBlockCompare((id)lhs, (id)rhs);
}

// Regular CallBacks

CFComparisonResult JBBMinimumBoxedCompare(id <JBBBoxedComparisonProtocol> lhs, id <JBBBoxedComparisonProtocol> rhs) {
  return [[lhs compare:rhs] intValue];
}

CFComparisonResult JBBMinimumCompare(id <JBBComparisonProtocol> lhs, id <JBBComparisonProtocol> rhs) {
  return [lhs compare:rhs];
}

CFComparisonResult JBBMinimumCallBack(const void *lhs, const void *rhs, void *info) {
  if ([[(id)lhs associatedValueForKey:@"JBBSortDelegate"] mBoxed]) {
    return JBBMinimumBoxedCompare((id)lhs, (id)rhs);
  } else {
    return JBBMinimumCompare((id)lhs, (id)rhs);
  }
}

CFComparisonResult JBBMaximumCallBack(const void *lhs, const void *rhs, void *info) {
  return JBBMinimumCallBack(lhs, rhs, info) * -1;
}

@interface JBBPriorityQueue ()
// synthesized properties

@property (assign) __strong CFBinaryHeapRef mObjs;
@property (retain) NSMutableArray *mObjsArray;
@property (assign) BOOL mHeapified;
@property (assign) BOOL mBoxed;
@property (retain) JBBComparisonBlock mComparisonBlock;
@property (assign) CFBinaryHeapCallBacks mCallBacks;

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock class:(Class)classToStore heapType:(enum JBBHeapType)heapType;
- (void)buildHeap;
@end

@implementation JBBPriorityQueue
@synthesize mObjs;
@synthesize mObjsArray;
@synthesize mHeapified;
@synthesize mBoxed;
@synthesize mComparisonBlock;
@synthesize mCallBacks;

- (id)init {
  NSAssert(NO, @"Use of a more specific initializer is required for JBBPriorityQueue.");
}

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock {
  return [self initWithBlock:comparisonBlock class:nil heapType:JBBMinimumHeap];
}

- (id)initWithClass:(Class)classToStore {
  return [self initWithClass:classToStore heapType:JBBMinimumHeap];
}

- (id)initWithClass:(Class)classToStore heapType:(enum JBBHeapType)heapType {
  return [self initWithBlock:nil class:classToStore heapType:heapType];
}

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock class:(Class)classToStore heapType:(enum JBBHeapType)heapType {
  self = [super init];

  if (self) {
    self.mHeapified = NO;
    self.mBoxed = NO;
    self.mComparisonBlock = nil;

    // we can abuse kCFStringBinaryHeapCallBacks here
    self.mCallBacks = kCFStringBinaryHeapCallBacks;
    self.pCallBacks->compare = NULL;

    if (comparisonBlock) {
      self.mComparisonBlock = comparisonBlock;
      self.pCallBacks->compare = JBBBlockCallBack;
    } else {
      NSAssert([classToStore instancesRespondToSelector:@selector(compare:)], @"JBBPriorityQueue requires nodes to respond to compare:");

      const char *boxedReturnType = "@";

      if (strcmp(boxedReturnType, [[classToStore instanceMethodSignatureForSelector:@selector(compare:)] methodReturnType]) == 0) {
        self.mBoxed = YES;
      }

      self.pCallBacks->compare = (heapType == JBBMinimumHeap) ? JBBMinimumCallBack : JBBMaximumCallBack;
    }

    self.mObjs = (CFBinaryHeapRef)CFMakeCollectable(CFBinaryHeapCreate(NULL, 0, self.pCallBacks, NULL));
    self.mObjsArray = [NSMutableArray array];
  }

  return self;
}

- (void)dealloc {
  if (self.mObjs) {
    CFRelease(self.mObjs);
    self.mObjs = NULL;
  }

  self.mObjsArray = nil;
  self.mComparisonBlock = nil;

  [super dealloc];
}

- (void)buildHeap {
  if (self.mHeapified) {
    return;
  }

  [self.mObjsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
    [obj associateValue:self withKey:@"JBBSortDelegate"];
    CFBinaryHeapAddValue(self.mObjs, obj);
  }];

  [self.mObjsArray removeAllObjects];

  self.mHeapified = YES;
}

- (void)push:(id)obj {
  if (self.mHeapified) {
    [obj associateValue:self withKey:@"JBBSortDelegate"];
    CFBinaryHeapAddValue(self.mObjs, obj);
  } else {
    [self.mObjsArray addObject:obj];
  }
}

- (void)pushObjects:(NSArray *)objs {
  self.mHeapified = NO;

  [self.mObjsArray addObjectsFromArray:objs];
}

- (id)pop {
  [self buildHeap];

  // There is a bug in CFBinaryHeapGetMinimumIfPresent().
  // FIXME: rdar://problem/7444195

  id returnVal = [(id)CFBinaryHeapGetMinimum(self.mObjs) retain];
  CFBinaryHeapRemoveMinimumValue(self.mObjs);
  return [returnVal autorelease];

//  id returnVal = nil;
//
//  if (!CFBinaryHeapGetMinimumIfPresent(self.mObjs, (const void **)&returnVal)) {
//    return nil;
//  }
//
//  [returnVal retain];
//  CFBinaryHeapRemoveMinimumValue(self.mObjs);
//  return [returnVal autorelease];
}

- (NSString *)description {
  [self buildHeap];

  // This is technically not working now, there is a bug in CFBinaryHeap, the description is incorrect
  // on Snow Leopard.
  // FIXME: rdar://problem/7219189

  return [NSString stringWithFormat:@"JBBPriorityQueue = %@", [NSMakeCollectable(CFCopyDescription(self.mObjs)) autorelease]];
}

- (CFIndex)count {
  return CFBinaryHeapGetCount(self.mObjs) + [self.mObjsArray count];
}

- (BOOL)isEmpty {
  return (CFBinaryHeapGetCount(self.mObjs) == 0) && ([self.mObjsArray count] == 0);
}

- (CFBinaryHeapCallBacks *)pCallBacks {
  return &mCallBacks;
}
@end

