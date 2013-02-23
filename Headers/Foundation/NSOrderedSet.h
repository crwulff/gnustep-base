/** Interface for NSOrderedSet, NSOrderedMutableSet for GNUStep
   Copyright (C) 1995, 1996, 1998 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
                Chris Wulff <crwulff@gmail.com>
   Created: Feb 2013

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   AutogsdocSource: NSOrderedSet.m

   */

#ifndef _NSOrderedSet_h_GNUSTEP_BASE_INCLUDE
#define _NSOrderedSet_h_GNUSTEP_BASE_INCLUDE
#import	<GNUstepBase/GSVersionMacros.h>

#import	<Foundation/NSObject.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSKeyValueObserving.h>
#import <GNUstepBase/GSBlocks.h>

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSArray, NSString, NSEnumerator, NSIndexSet, NSSet;

@interface NSOrderedSet : NSObject <NSCoding, NSCopying, NSMutableCopying, NSFastEnumeration>

+ (id) orderedSet;
+ (id) orderedSetWithArray: (NSArray*)objects;
+ (id) orderedSetWithArray: (NSArray*)objects
                     range: (NSRange)range
                 copyItems: (BOOL)copyItems;
+ (id) orderedSetWithObject: (id)anObject;
+ (id) orderedSetWithObjects: (id)firstObject, ...;
+ (id) orderedSetWithObjects: (const id[])objects
                       count: (NSUInteger)count;
+ (id) orderedSetWithSet: (NSSet*)aSet;
+ (id) orderedSetWithSet: (NSSet*)aSet
               copyItems: (BOOL)copyItems;

- (id) init;
- (id) initWithArray: (NSArray*)other;
- (id) initWithArray: (NSArray*)other
           copyItems: (BOOL)copyItems;
- (id) initWithArray: (NSArray*)other
               range: (NSRange)range
           copyItems: (BOOL)copyItems;
- (id) initWithObject: (id)anObject;
- (id) initWithObjects: (id)firstObject, ...;
- (id) initWithObjects: (const id[])objects
		 count: (NSUInteger)count;
- (id) initWithOrderedSet: (NSOrderedSet*)other;
- (id) initWithOrderedSet: (NSOrderedSet*)other
                copyItems: (BOOL)copyItems;
- (id) initWithOrderedSet: (NSOrderedSet*)other
                    range: (NSRange)range
                copyItems: (BOOL)copyItems;
- (id) initWithSet: (NSSet*)other;
- (id) initWithSet: (NSSet*)other
         copyItems: (BOOL)copyItems;

- (NSUInteger) count;
- (BOOL) containsObject: (id)anObject;
- (id) firstObject;
- (id) lastObject;
- (id) objectAtIndex: (NSUInteger)index;
- (id) objectAtIndexedSubscript: (NSUInteger)index;
- (NSArray*) objectsAtIndexes: (NSIndexSet*)indexes;
- (NSUInteger) indexOfObject: (id)object;
- (NSUInteger) indexOfObject: (id)object
               inSortedRange: (NSRange)range
                     options: (NSBinarySearchingOptions)opts
             usingComparator: (NSComparator)cmp;
- (NSEnumerator*) objectEnumerator;
- (NSEnumerator*) reverseObjectEnumerator;
- (NSOrderedSet*) reversedOrderedSet;
- (void) getObjects: (id __unsafe_unretained [])objects
              range: (NSRange)range;

- (BOOL) isEqualToOrderedSet: (NSOrderedSet*)other;
- (BOOL) intersectsOrderedSet: (NSOrderedSet*)otherSet;
- (BOOL) intersectsSet: (NSSet*)otherSet;
- (BOOL) isSubsetOfOrderedSet: (NSOrderedSet*)otherSet;
- (BOOL) isSubsetOfSet: (NSSet*)otherSet;

- (void) setValue: (id)value
           forKey: (NSString*)key;
- (id) valueForKey: (NSString*)key;

- (void) addObserver: (NSObject*)observer
          forKeyPath: (NSString*)keyPath
             options: (NSKeyValueObservingOptions)options
             context: (void*)context;
- (void) removeObserver: (NSObject*)observer
             forKeyPath: (NSString*)keyPath;
- (void) removeObserver: (NSObject*)observer
             forKeyPath: (NSString*)keyPath
                context: (void*)context;

- (NSArray*) sortedArrayUsingComparator: (NSComparator)comparator;
- (NSArray*) sortedArrayWithOptions: (NSSortOptions)opts
                    usingComparator: (NSComparator)comparator;

- (NSString*) description;
- (NSString*) descriptionWithLocale: (id)locale;
- (NSString*) descriptionWithLocale: (id)locale
                             indent: (NSUInteger)level;

- (NSArray*) array;
- (NSSet*) set;

DEFINE_BLOCK_TYPE(GSOrderedSetEnumeratorBlock, void, id, NSUInteger, BOOL*);
DEFINE_BLOCK_TYPE(GSOrderedSetFilterBlock, BOOL, id, NSUInteger, BOOL*);

- (void) enumerateObjectsAtIndexes: (NSIndexSet*)indexSet
                           options: (NSEnumerationOptions)opts
                        usingBlock: (GSOrderedSetEnumeratorBlock)block;
/**
 * Enumerate over the collection using a given block.  The first argument is
 * the object.  The second argument is the index of the object. The third
 * argument is a pointer to a BOOL indicating whether the enumeration should
 * stop.  Setting this to YES will interupt the enumeration.
 */
- (void) enumerateObjectsUsingBlock:(GSOrderedSetEnumeratorBlock)aBlock;

/**
 * Enumerate over the collection using a given block.  The first argument is
 * the object.  The second argument is the index of the object. The third
 * argument is a pointer to a BOOL indicating whether the enumeration should
 * stop.  Setting this to YES will interupt the enumeration.
 *
 * The opts argument is a bitfield.  Setting the NSNSEnumerationConcurrent flag
 * specifies that it is thread-safe.  The NSEnumerationReverse bit specifies
 * that it should be enumerated in reverse order.
 */
- (void) enumerateObjectsWithOptions: (NSEnumerationOptions)opts
                          usingBlock: (GSOrderedSetEnumeratorBlock)aBlock;

- (NSUInteger) indexOfObjectAtIndexes: (NSIndexSet*)indexSet
                              options: (NSEnumerationOptions)opts
                          passingTest: (GSOrderedSetFilterBlock)aBlock;
- (NSUInteger) indexOfObjectPassingTest: (GSOrderedSetFilterBlock)aBlock;
- (NSUInteger) indexOfObjectWithOptions: (NSEnumerationOptions)opts
                            passingTest: (GSOrderedSetFilterBlock)aBlock;
- (NSIndexSet*) indexesOfObjectsAtIndexes: (NSIndexSet*)indexSet
                                  options: (NSEnumerationOptions)opts
                              passingTest: (GSOrderedSetFilterBlock)aBlock;
- (NSIndexSet*) indexesOfObjectsPassingTest: (GSOrderedSetFilterBlock)aBlock;
- (NSIndexSet*) indexesOfObjectsWithOptions: (NSEnumerationOptions)opts
                                passingTest: (GSOrderedSetFilterBlock)aBlock;

@end

@interface NSMutableOrderedSet: NSOrderedSet

+ (id) orderedSetWithCapacity: (NSUInteger)numItems;

- (id) initWithCapacity: (NSUInteger)numItems;

- (void) addObject: (id)anObject;
- (void) addObjects: (const id[])objects
              count: (NSUInteger)count;
- (void) addObjectsFromArray: (NSArray*)array;
- (void) insertObject: (id)anObject
              atIndex: (NSUInteger)index;
- (void) setObject: (id)anObject
atIndexedSubscript: (NSUInteger)idx;
- (void) insertObjects: (NSArray*)objects
             atIndexes: (NSIndexSet*)indexes;

- (void) removeObject: (id)anObject;
- (void) removeObjectAtIndex: (NSUInteger)index;
- (void) removeObjectsAtIndexes: (NSIndexSet*)indexes;
- (void) removeObjectsInArray: (NSArray*)array;
- (void) removeObjectsInRange: (NSRange)range;
- (void) removeAllObjects;

- (void) replaceObjectAtIndex: (NSUInteger)index
                   withObject: (id)anObject;
- (void) replaceObjectsAtIndexes: (NSIndexSet*)indexes
                     withObjects: (NSArray*)objects;
- (void) replaceObjectsInRange: (NSRange)range
                   withObjects: (const id[])objects
                         count: (NSUInteger)count;
- (void) setObject: (id)anObject
           atIndex: (NSUInteger)index;
- (void) moveObjectsAtIndexes: (NSIndexSet*)indexes
                      toIndex: (NSUInteger)index;
- (void) exchangeObjectAtIndex: (NSUInteger)index1
             withObjectAtIndex: (NSUInteger)index2;

- (void) intersectOrderedSet: (NSOrderedSet*)other;
- (void) intersectSet: (NSSet*)other;
- (void) minusOrderedSet: (NSOrderedSet*)other;
- (void) minusSet: (NSSet*)other;
- (void) unionOrderedSet: (NSOrderedSet*)other;
- (void) unionSet: (NSSet*)other;
@end

#if	defined(__cplusplus)
}
#endif

#endif
