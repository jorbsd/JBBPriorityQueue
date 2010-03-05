//
//  NSObject+AssociatedObjects.h
//
//  Created by Andy Matuschak on 8/27/09.
//  Public domain because I love you.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (AMAssociatedObjects)
- (void)am_associateValue:(id)value withKey:(void *)key; // Retains value.
- (id)am_associatedValueForKey:(void *)key;
@end
