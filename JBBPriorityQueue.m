//
//  JBBPriorityQueue.mm
//  JBBPriorityQueue
//
//  Created by Jordan Breeding on 09/08/09.
//  Copyright 2009 Jordan Breeding. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//  Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "JBBPriorityQueue.h"
#import "NSObject+AssociatedObjects.h"

// block callbacks

CFComparisonResult JBBBlockCompare(id, id);
CFComparisonResult JBBBlockCallBack(const void *, const void *, void *);

// regular callbacks

CFComparisonResult JBBMinimumBoxedCompare(id <JBBBoxedComparisonProtocol>, id <JBBBoxedComparisonProtocol>);
CFComparisonResult JBBMinimumCompare(id <JBBComparisonProtocol>, id <JBBComparisonProtocol>);
CFComparisonResult JBBMinimumCallBack(const void *, const void *, void *);
CFComparisonResult JBBMaximumCallBack(const void *, const void *, void *);
void JBBBuildDescriptionCallBack(const void *, void *);

@interface JBBPriorityQueue ()
// synthesized properties

@property (assign) __strong CFBinaryHeapRef objs;
@property (retain) NSMutableArray *objsArray;
@property (assign) BOOL heapified;
@property (assign) BOOL boxed;
@property (retain) JBBComparisonBlock comparisonBlock;
@property (assign) CFBinaryHeapCallBacks callBacks;

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock class:(Class)classToStore ordering:(NSComparisonResult)ordering;
- (void)buildHeap;
@end

@implementation JBBPriorityQueue
@synthesize objs = mObjs;
@synthesize objsArray = mObjsArray;
@synthesize heapified = mHeapified;
@synthesize boxed = mBoxed;
@synthesize comparisonBlock = mComparisonBlock;
@synthesize callBacks = mCallBacks;

- (id)init {
    NSAssert(NO, @"Use of a more specific initializer is required for JBBPriorityQueue.");
    return nil;
}

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock {
    return [self initWithBlock:comparisonBlock class:nil ordering:NSOrderedAscending];
}

- (id)initWithClass:(Class)classToStore {
    return [self initWithClass:classToStore ordering:NSOrderedAscending];
}

- (id)initWithClass:(Class)classToStore ordering:(NSComparisonResult)ordering {
    return [self initWithBlock:nil class:classToStore ordering:ordering];
}

- (id)initWithBlock:(JBBComparisonBlock)comparisonBlock class:(Class)classToStore ordering:(NSComparisonResult)ordering {
    self = [super init];

    if (self) {
        self.heapified = NO;
        self.boxed = NO;
        self.comparisonBlock = nil;

        // we can abuse kCFStringBinaryHeapCallBacks here

        mCallBacks.version = 0;
        mCallBacks.retain = kCFStringBinaryHeapCallBacks.retain;
        mCallBacks.release = kCFStringBinaryHeapCallBacks.release;
        mCallBacks.copyDescription = kCFStringBinaryHeapCallBacks.copyDescription;
        mCallBacks.compare = NULL;

        if (comparisonBlock) {
            self.comparisonBlock = comparisonBlock;
            mCallBacks.compare = JBBBlockCallBack;
        } else {
            NSAssert([classToStore instancesRespondToSelector:@selector(compare:)], @"JBBPriorityQueue requires nodes to respond to @selector(compare:)");

            const char *boxedReturnType = "@";

            if (strcmp(boxedReturnType, [[classToStore instanceMethodSignatureForSelector:@selector(compare:)] methodReturnType]) == 0) {
                self.boxed = YES;
            }

            NSAssert(ordering != NSOrderedSame, @"JBBPriorityQueue requires ordering to be NSOrderedAscending or NSOrderedDescending");
            mCallBacks.compare = (ordering == NSOrderedAscending) ? JBBMinimumCallBack : JBBMaximumCallBack;
        }

        self.objs = (CFBinaryHeapRef)CFMakeCollectable(CFBinaryHeapCreate(NULL, 0, &mCallBacks, NULL));
        self.objsArray = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc {
    if (self.objs) {
        CFRelease(self.objs);
        self.objs = NULL;
    }

    self.objsArray = nil;
    self.comparisonBlock = nil;

    [super dealloc];
}

- (void)buildHeap {
    if (self.heapified) {
        return;
    }

    [self.objsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        [obj am_associateValue:self withKey:@"JBBSortDelegate"];
        CFBinaryHeapAddValue(self.objs, obj);
    }];

    [self.objsArray removeAllObjects];

    self.heapified = YES;
}

- (void)push:(id)obj {
    if (self.heapified) {
        [obj am_associateValue:self withKey:@"JBBSortDelegate"];
        CFBinaryHeapAddValue(self.objs, obj);
    } else {
        [self.objsArray addObject:obj];
    }
}

- (void)pushObjects:(NSArray *)objs {
    self.heapified = NO;

    [self.objsArray addObjectsFromArray:objs];
}

- (id)pop {
    id returnVal = [[self peek] retain];

    CFBinaryHeapRemoveMinimumValue(self.objs);

    return [returnVal autorelease];
}

- (id)peek {
    [self buildHeap];

    // There is a bug in CFBinaryHeapGetMinimumIfPresent().
    // FIXME: rdar://problem/7444195

    return [[(id)CFBinaryHeapGetMinimum(self.objs) retain] autorelease];

    //    id returnVal = nil;
    //
    //    if (CFBinaryHeapGetMinimumIfPresent(self.mObjs, (const void**)&returnVal)) {
    //        [returnVal retain];
    //    }
    //
    //    return [returnVal autorelease];
}

- (void)addObject:(id)obj {
    [self push:obj];
}

- (void)addObjects:(NSArray *)objs {
    [self pushObjects:objs];
}

- (id)removeFirstObject {
    return [self pop];
}

- (id)firstObject {
    return [self peek];
}

- (NSString *)description {
    [self buildHeap];

    CFBinaryHeapRef tempHeap = CFBinaryHeapCreateCopy(NULL, 0, self.objs);

    // This is technically not working now, there is a bug in CFBinaryHeap, the description is incorrect
    // on Snow Leopard.
    // FIXME: rdar://problem/7219189

    //return [NSString stringWithFormat:@"JBBPriorityQueue = %@", [NSMakeCollectable(CFCopyDescription(tempHeap)) autorelease]];

    NSMutableString *result = [NSMutableString stringWithFormat:@"<JBBPriorityQueue: %p> {", self];
    if (CFBinaryHeapGetCount(tempHeap) != 0) {
        [result appendFormat:@"\n"];
        CFBinaryHeapApplyFunction(tempHeap, JBBBuildDescriptionCallBack, result);
    }
    [result appendFormat:@"}"];

    CFRelease(tempHeap);

    return result;
}

- (CFIndex)count {
    return CFBinaryHeapGetCount(self.objs) + [self.objsArray count];
}

- (BOOL)isEmpty {
    return (CFBinaryHeapGetCount(self.objs) == 0) && ([self.objsArray count] == 0);
}

- (NSUInteger)hash {
    [self buildHeap];

    NSUInteger localHash = 0;

    localHash ^= CFHash(self.objs);
    localHash ^= self.boxed;

    return localHash;
}

- (BOOL)isEqual:(id)otherObj {
    if (self == otherObj) {
        return YES;
    }

    if (![otherObj isKindOfClass:[JBBPriorityQueue class]]) {
        return NO;
    }

    return [self isEqualToQueue:otherObj];
}

- (BOOL)isEqualToQueue:(JBBPriorityQueue *)otherQueue {
    if (self == otherQueue) {
        return YES;
    }

    [self buildHeap];
    [otherQueue buildHeap];

    if (self.boxed != otherQueue.boxed) {
        return NO;
    }

    CFBinaryHeapRef heap1 = CFBinaryHeapCreateCopy(NULL, 0, self.objs);
    CFBinaryHeapRef heap2 = CFBinaryHeapCreateCopy(NULL, 0, otherQueue.objs);

    const void **array1 = calloc(CFBinaryHeapGetCount(heap1), sizeof(void *));
    CFBinaryHeapGetValues(heap1, array1);
    NSArray *NSArray1 = [NSArray arrayWithObjects:(id *)array1 count:CFBinaryHeapGetCount(heap1)];
    free(array1);

    const void **array2 = calloc(CFBinaryHeapGetCount(heap2), sizeof(void *));
    CFBinaryHeapGetValues(heap2, array2);
    NSArray *NSArray2 = [NSArray arrayWithObjects:(id *)array2 count:CFBinaryHeapGetCount(heap2)];
    free(array2);

    CFRelease(heap1);
    CFRelease(heap2);

    return [NSArray1 isEqual:NSArray2];
}
@end

// block callbacks

CFComparisonResult JBBBlockCompare(id lhs, id rhs) {
    JBBComparisonBlock localBlock = [[lhs am_associatedValueForKey:@"JBBSortDelegate"] comparisonBlock];

    return localBlock(lhs, rhs);
}

CFComparisonResult JBBBlockCallBack(const void *lhs, const void *rhs, void *info) {
    return JBBBlockCompare((id)lhs, (id)rhs);
}

// regular callbacks

CFComparisonResult JBBMinimumBoxedCompare(id <JBBBoxedComparisonProtocol> lhs, id <JBBBoxedComparisonProtocol> rhs) {
    return [[lhs compare:rhs] intValue];
}

CFComparisonResult JBBMinimumCompare(id <JBBComparisonProtocol> lhs, id <JBBComparisonProtocol> rhs) {
    return [lhs compare:rhs];
}

CFComparisonResult JBBMinimumCallBack(const void *lhs, const void *rhs, void *info) {
    if ([[(id)lhs am_associatedValueForKey:@"JBBSortDelegate"] boxed]) {
        return JBBMinimumBoxedCompare((id)lhs, (id)rhs);
    } else {
        return JBBMinimumCompare((id)lhs, (id)rhs);
    }
}

CFComparisonResult JBBMaximumCallBack(const void *lhs, const void *rhs, void *info) {
    return JBBMinimumCallBack(lhs, rhs, info) * -1;
}

void JBBBuildDescriptionCallBack(const void *val, void *context) {
    NSMutableString *descriptionString = (NSMutableString *)context;
    [descriptionString appendFormat:@"\t%@,\n", (id)val];
}

