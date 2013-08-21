/** Concrete implementation of NSOrderedSet based on GSSet class
   Copyright (C) 1995, 1996, 1998, 2000 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Created: September 1995
   Rewrite by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Ordered set: Chris Wulff <crwulff@gmail.com>

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   _version 2 of the License, or (at your option) any later _version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
   */

#import "common.h"
#import "Foundation/NSSet.h"
#import "Foundation/NSOrderedSet.h"
#import "GNUstepBase/GSObjCRuntime.h"
#import "Foundation/NSAutoreleasePool.h"
#import "Foundation/NSArray.h"
#import "Foundation/NSEnumerator.h"
#import "Foundation/NSException.h"
#import "Foundation/NSPortCoder.h"
// For private method _decodeArrayOfObjectsForKey:
#import "Foundation/NSKeyedArchiver.h"
#import "GSPrivate.h"

#define	GSI_MAP_HAS_VALUE	0
#define	GSI_MAP_KTYPES		GSUNION_OBJ
#if	GS_WITH_GC
#include	<gc/gc_typed.h>
static GC_descr	nodeDesc;	// Type descriptor for map node.
#define	GSI_MAP_NODES(M, X) \
(GSIMapNode)GC_calloc_explicitly_typed(X, sizeof(GSIMapNode_t), nodeDesc)
#endif


#include "GNUstepBase/GSIMap.h"

static SEL	memberSel;

@interface GSOrderedSet : NSOrderedSet
{
@public
  GSIMapTable_t  map;
  GSMutableArray *array;
}
@end

@interface GSMutableOrderedSet : NSMutableOrderedSet
{
@public
  GSIMapTable_t	map;
  GSMutableArray *array;
@private
  NSUInteger _version;
}
@end

@interface GSOrderedSetEnumerator : NSEnumerator
{
  GSOrderedSet		*set;
  GSIMapEnumerator_t	enumerator;
}
@end

@implementation GSOrderedSet

static Class	arrayClass;
static Class	orderedSetClass;
static Class	mutableOrderedSetClass;

+ (void) initialize
{
  if (self == [GSOrderedSet class])
    {
#if	GS_WITH_GC
      /* We create a typed memory descriptor for map nodes.
       * Only the pointer to the key needs to be scanned.
       */
      GC_word	w[GC_BITMAP_SIZE(GSIMapNode_t)] = {0};
      GC_set_bit(w, GC_WORD_OFFSET(GSIMapNode_t, key));
      nodeDesc = GC_make_descriptor(w, GC_WORD_LEN(GSIMapNode_t));
#endif
      arrayClass = [NSArray class];
      orderedSetClass = [GSOrderedSet class];
      mutableOrderedSetClass = [GSMutableOrderedSet class];
      memberSel = @selector(member:);
    }
}

- (NSArray*) allObjects
{
  return RETAIN(array);
}

- (id) copyWithZone: (NSZone*)z
{
  return RETAIN(self);
}

- (NSUInteger) count
{
  return map.nodeCount;
}

- (void) dealloc
{
  GSIMapEmptyMap(&map);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  /* Encode the array as that keeps the order */
  [array encodeWithCoder: aCoder];
}

- (NSUInteger) hash
{
  return map.nodeCount;
}

- (id) init
{
  return [self initWithObjects: 0 count: 0];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  /* Init using the array and then add all objects to the map as well */
  [array initWithCoder: aCoder];

  if ([aCoder allowsKeyedCoding])
    {
      self = [super initWithCoder: aCoder];
    }
  else
    {
#if 0 // TODO - add array objects to the map
      unsigned	count;
      id		value;
      SEL		sel = @selector(decodeValueOfObjCType:at:);
      IMP		imp = [aCoder methodForSelector: sel];
      const char	*type = @encode(id);

      (*imp)(aCoder, sel, @encode(unsigned), &count);

      GSIMapInitWithZoneAndCapacity(&map, [self zone], count);
      while (count-- > 0)
        {
	  (*imp)(aCoder, sel, type, &value);
	  GSIMapAddKeyNoRetain(&map, (GSIMapKey)value);
	}
#endif
    }
  return self;
}

/* Designated initialiser */
- (id) initWithObjects: (const id*)objs count: (NSUInteger)c
{
  NSUInteger i;
  array = [NSMutableArray arrayWithCapacity: c];

  GSIMapInitWithZoneAndCapacity(&map, [self zone], c);
  for (i = 0; i < c; i++)
    {
      GSIMapNode     node;

      if (objs[i] == nil)
	{
	  DESTROY(self);
	  [NSException raise: NSInvalidArgumentException
		      format: @"Tried to init set with nil value"];
	}
      node = GSIMapNodeForKey(&map, (GSIMapKey)objs[i]);
      if (node == 0)
	{
	  GSIMapAddKey(&map, (GSIMapKey)objs[i]);
	  [array addObject: objs[i]];
        }
    }
  return self;
}

- (BOOL) intersectsOrderedSet: (NSSet*) otherSet
{
  Class	c;

  /*
   *  If this set is empty, or the other is nil, this method should return NO.
   */
  if (map.nodeCount == 0)
    {
      return NO;
    }
  if (otherSet == nil)
    {
      return NO;
    }

  // Loop for all members in otherSet
  c = object_getClass(otherSet);
  if (c == orderedSetClass || c == mutableOrderedSetClass)
    {
      GSIMapTable		m = &((GSOrderedSet*)otherSet)->map;
      GSIMapEnumerator_t	enumerator = GSIMapEnumeratorForMap(m);
      GSIMapNode 		node = GSIMapEnumeratorNextNode(&enumerator);

      while (node != 0)
	{
	  if (GSIMapNodeForKey(&map, node->key) != 0)
	    {
	      GSIMapEndEnumerator(&enumerator);
	      return YES;
	    }
	  node = GSIMapEnumeratorNextNode(&enumerator);
	}
      GSIMapEndEnumerator(&enumerator);
    }
  else
    {
      NSEnumerator	*e;
      id		o;

      e = [otherSet objectEnumerator];
      while ((o = [e nextObject])) // 1. pick a member from otherSet.
	{
	  if (GSIMapNodeForKey(&map, (GSIMapKey)o) != 0)
	    {
	      return YES;
	    }
	}
    }
  return NO;
}

- (BOOL) isSubsetOfSet: (NSSet*) otherSet
{
  GSIMapEnumerator_t	enumerator;
  GSIMapNode 		node;
  IMP			imp;

  // -1. members of this set(self) <= that of otherSet
  if (map.nodeCount > [otherSet count])
    {
      return NO;
    }
  if (map.nodeCount == 0)
    {
      return YES;
    }

  imp = [otherSet methodForSelector: memberSel];
  enumerator = GSIMapEnumeratorForMap(&map);
  node = GSIMapEnumeratorNextNode(&enumerator);

  // 0. Loop for all members in this set(self).
  while (node != 0)
    {
      // 1. check the member is in the otherSet.
      if ((*imp)(otherSet, memberSel, node->key.obj) != nil)
	{
	  // 1.1 if true -> continue, try to check the next member.
	  node = GSIMapEnumeratorNextNode(&enumerator);
	}
      else
	{
	  // 1.2 if false -> return NO;
	  GSIMapEndEnumerator(&enumerator);
	  return NO;
	}
    }
  GSIMapEndEnumerator(&enumerator);
  // 2. return YES; all members in this set are also in the otherSet.
  return YES;
}

- (BOOL) isEqualToOrderedSet: (NSOrderedSet*)other
{
  return [array isEqualToArray: [other array]];
}

- (id) objectAtIndex: (NSUInteger)index
{
  return [array objectAtIndex: index];
}

- (NSUInteger) indexOfObject: (id)object;
{
  return [array indexOfObject: object];
}

- (NSUInteger) indexOfObject: (id)object
               inSortedRange: (NSRange)range
                     options: (NSBinarySearchingOptions)opts
             usingComparator: (NSComparator)cmp
{
  return [array indexOfObject: object
		inSortedRange: range
		      options: opts
	      usingComparator: cmp];
}

- (void) makeObjectsPerform: (SEL)aSelector
{
  [array makeObjectsPerform: aSelector];
}

- (void) makeObjectsPerformSelector: (SEL)aSelector
{
  [array makeObjectsPerform: aSelector];
}

- (void) makeObjectsPerformSelector: (SEL)aSelector withObject: argument
{
  [array makeObjectsPerformSelector: aSelector withObject: argument];
}

- (void) makeObjectsPerform: (SEL)aSelector withObject: argument
{
  [array makeObjectsPerform: aSelector withObject: argument];
}

- (id) member: (id)anObject
{
  if (anObject != nil)
    {
      GSIMapNode node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);

      if (node != 0)
	{
	  return node->key.obj;
	}
    }
  return nil;
}

- (NSEnumerator*) objectEnumerator
{
  return [array objectEnumerator];
}

- (NSEnumerator*) reverseObjectEnumerator
{
  return [array reverseObjectEnumerator];
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state
                                   objects: (id*)stackbuf
                                     count: (NSUInteger)len
{
  state->mutationsPtr = (unsigned long *)self;
  return GSIMapCountByEnumeratingWithStateObjectsCount
    (&map, state, stackbuf, len);
}
@end

@implementation GSMutableOrderedSet

+ (void) initialize
{
  if (self == [GSMutableOrderedSet class])
    {
      GSObjCAddClassBehavior(self, [GSOrderedSet class]);
    }
}

- (void) addObject: (id)anObject
{
  GSIMapNode node;

  if (anObject == nil)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Tried to add nil to set"];
    }
  node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);
  if (node == 0)
    {
      GSIMapAddKey(&map, (GSIMapKey)anObject);
      [array addObject: anObject];
      _version++;
    }
}

- (void) addObjectsFromArray: (NSArray*)anArray
{
  NSUInteger	count = [anArray count];

  while (count-- > 0)
    {
      id	anObject = [anArray objectAtIndex: count];

      if (anObject == nil)
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"Tried to add nil to set"];
	}
      else
	{
	  GSIMapNode node;

	  node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);
	  if (node == 0)
	    {
	      GSIMapAddKey(&map, (GSIMapKey)anObject);
              [array addObject: anObject];
	      _version++;
	    }
	}
    }
}

/* Override _version from GSOrderedSet */
- (id) copyWithZone: (NSZone*)z
{
  NSOrderedSet *copy = [orderedSetClass allocWithZone: z];

  return [copy initWithOrderedSet: self copyItems: NO];
}

- (id) init
{
  return [self initWithCapacity: 0];
}

/* Designated initialiser */
- (id) initWithCapacity: (NSUInteger)cap
{
  GSIMapInitWithZoneAndCapacity(&map, [self zone], cap);
  return self;
}

- (id) initWithObjects: (const id*)objects
		 count: (NSUInteger)count
{
  self = [self initWithCapacity: count];

  while (count--)
    {
      id	anObject = objects[count];

      if (anObject == nil)
	{
	  NSLog(@"Tried to init a set with a nil object");
	  continue;
	}
      else
	{
	  GSIMapNode node;

	  node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);
	  if (node == 0)
	    {
	      GSIMapAddKey(&map, (GSIMapKey)anObject);
	      [array addObject: anObject];
	    }
	}
    }
  return self;
}

- (void) intersectOrderedSet: (NSOrderedSet*) other
{
  if (other != self)
    {
      GSIMapEnumerator_t	enumerator = GSIMapEnumeratorForMap(&map);
      GSIMapBucket		bucket = GSIMapEnumeratorBucket(&enumerator);
      GSIMapNode 		node = GSIMapEnumeratorNextNode(&enumerator);

      while (node != 0)
	{

	  if ([other containsObject: node->key.obj] == NO)
	    {
	      GSIMapRemoveNodeFromMap(&map, bucket, node);
	      [array removeObject: node->key.obj];
	      GSIMapFreeNode(&map, node);
	    }
	  bucket = GSIMapEnumeratorBucket(&enumerator);
	  node = GSIMapEnumeratorNextNode(&enumerator);
	}
      GSIMapEndEnumerator(&enumerator);
    }
}

- (id) makeImmutableCopyOnFail: (BOOL)force
{
  GSClassSwizzle(self, [GSOrderedSet class]);
  return self;
}

- (void) minusOrderedSet: (NSOrderedSet*) other
{
  if (other == self)
    {
      GSIMapCleanMap(&map);
    }
  else
    {
      NSEnumerator	*e = [other objectEnumerator];
      id		anObject;

      while ((anObject = [e nextObject]) != nil)
	{
	  GSIMapRemoveKey(&map, (GSIMapKey)anObject);
	  [array removeObject: anObject];
	  _version++;
	}
    }
}

- (void) removeAllObjects
{
  GSIMapCleanMap(&map);
  [array removeAllObjects];
}

- (void) removeObject: (id)anObject
{
  if (anObject == nil)
    {
      NSWarnMLog(@"attempt to remove nil object");
      return;
    }
  GSIMapRemoveKey(&map, (GSIMapKey)anObject);
  [array removeObject: anObject];
  _version++;
}

- (void) unionOrderedSet: (NSOrderedSet*) other
{
  if (other != self)
    {
      NSEnumerator	*e = [other objectEnumerator];

      if (e != nil)
	{
	  id	anObject;
	  SEL	sel = @selector(nextObject);
	  IMP	imp = [e methodForSelector: sel];

	  while ((anObject = (*imp)(e, sel)) != nil)
	    {
	      GSIMapNode node;

	      node = GSIMapNodeForKey(&map, (GSIMapKey)anObject);
	      if (node == 0)
		{
		  GSIMapAddKey(&map, (GSIMapKey)anObject);
	          [array addObject: anObject];
		  _version++;
		}
	    }
	}
    }
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state
                                   objects: (id*)stackbuf
                                     count: (NSUInteger)len
{
  state->mutationsPtr = (unsigned long *)&_version;
  return GSIMapCountByEnumeratingWithStateObjectsCount
    (&map, state, stackbuf, len);
}
@end
