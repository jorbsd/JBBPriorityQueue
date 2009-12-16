//
//  JBBPriorityQueue.mm
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//

#import "JBBPriorityQueue.h"
#import "NSObject+AssociatedObjects.h"

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

CFComparisonResult JBBBlockCallBack(const void *lhs, const void *rhs, void *info) {
  return [(JBBPriorityQueue *)[(id)lhs associatedValueForKey:@"JBBSortDelegate"] mComparisonBlock]((id)lhs, (id)rhs);
}

CFComparisonResult JBBMinimumCallBack(const void *lhs, const void *rhs, void *info) {
  if ([(JBBPriorityQueue *)[(id)lhs associatedValueForKey:@"JBBSortDelegate"] mBoxed]) {
    return [[(id <JBBBoxedComparisonProtocol>)lhs compare:(id <JBBBoxedComparisonProtocol>)rhs] intValue];
  } else {
    return [(id <JBBComparisonProtocol>)lhs compare:(id <JBBComparisonProtocol>)rhs];
  }
}

CFComparisonResult JBBMaximumCallBack(const void *lhs, const void *rhs, void *info) {
  if ([(JBBPriorityQueue *)[(id)lhs associatedValueForKey:@"JBBSortDelegate"] mBoxed]) {
    return [[(id <JBBBoxedComparisonProtocol>)lhs compare:(id <JBBBoxedComparisonProtocol>)rhs] intValue] * -1;
  } else {
    return [(id <JBBComparisonProtocol>)lhs compare:(id <JBBComparisonProtocol>)rhs] * -1;
  }
}

@interface JBBPriorityQueue ()
// synthesized properties

@property (assign) __strong CFBinaryHeapRef mObjs;
@property (retain) NSMutableArray *mObjsArray;
@property (assign) BOOL mHeapified;
@property (assign) BOOL mBoxed;
@property (retain) JBBComparisonBlock mComparisonBlock;
@property (assign) CFBinaryHeapCallBacks mCallBacks;

- (void)initDefaults;
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

- (void)initDefaults {
  self.mHeapified = NO;
  self.mBoxed = NO;
  self.mComparisonBlock = nil;

  // we can abuse kCFStringBinaryHeapCallBacks here
  self.mCallBacks = kCFStringBinaryHeapCallBacks;
  self.pCallBacks->compare = NULL;

  self.mObjs = NULL;
  self.mObjsArray = nil;
}

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock {
  self = [super init];

  if (!self) {
    return nil;
  }

  [self initDefaults];

  self.mComparisonBlock = comparisonBlock;
  self.pCallBacks->compare = JBBBlockCallBack;
}

- (id)initWithClass:(Class)classToStore {
  return [self initWithClass:classToStore heapType:JBBMinimumHeap];
}

- (id)initWithClass:(Class)classToStore heapType:(enum JBBHeapType)heapType {
  self = [super init];

  if (!self) {
    return nil;
  }

  NSAssert([classToStore instancesRespondToSelector:@selector(compare:)], @"JBBPriorityQueue requires nodes to respond to compare:");

  [self initDefaults];

  const char *boxedReturnType = "@";

  if (strcmp(boxedReturnType, [[classToStore instanceMethodSignatureForSelector:@selector(compare:)] methodReturnType]) == 0) {
    self.mBoxed = YES;
  }

  self.pCallBacks->compare = (heapType == JBBMinimumHeap) ? JBBMinimumCallBack : JBBMaximumCallBack;

  self.mObjs = (CFBinaryHeapRef)CFMakeCollectable(CFBinaryHeapCreate(NULL, 0, self.pCallBacks, NULL));
  self.mObjsArray = [NSMutableArray array];

  return self;
}

- (void)dealloc {
  if (mObjs) {
    CFRelease(mObjs);
    self.mObjs = NULL;
  }

  self.mObjsArray = nil;
  self.mComparisonBlock = nil;

  [super dealloc];
}

- (void)buildHeap {
  if (mHeapified) {
    return;
  }

  [mObjsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
    [obj associateValue:self withKey:@"JBBSortDelegate"];
    CFBinaryHeapAddValue(mObjs, obj);
  }];

  [mObjsArray removeAllObjects];

  self.mHeapified = YES;
}

- (void)push:(id)obj {
  if (mHeapified) {
    [obj associateValue:self withKey:@"JBBSortDelegate"];
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

  // Right now just use JBBCFBinaryHeapGetAndRemoveMinimum(), there is a bug
  // in CFBinaryHeapGetMinimumIfPresent().
  // FIXME: rdar://problem/7444195

  return JBBCFBinaryHeapGetAndRemoveMinimum(mObjs);
//  return JBBCFBinaryHeapGetAndRemoveMinimumIfPresent(mObjs);
}

- (NSString *)description {
  [self buildHeap];

  // This is technically not working now, there is a bug in CFBinaryHeap, the description is incorrect
  // on Snow Leopard.
  // FIXME: rdar://problem/7219189

  return [NSString stringWithFormat:@"JBBPriorityQueue = %@", [NSMakeCollectable(CFCopyDescription(mObjs)) autorelease]];
}

- (CFIndex)count {
  return CFBinaryHeapGetCount(mObjs) + [mObjsArray count];
}

- (BOOL)isEmpty {
  return (CFBinaryHeapGetCount(mObjs) == 0) && ([mObjsArray count] == 0);
}

- (CFBinaryHeapCallBacks *)pCallBacks {
  return &mCallBacks;
}
@end

