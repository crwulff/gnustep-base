/** NSOrderedSet - Set object to store key/value pairs
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

   <title>NSOrderedSet class reference</title>
   $Date$ $Revision$
   */

#import "common.h"
#import "Foundation/NSArray.h"
#import "Foundation/NSOrderedSet.h"
#import "Foundation/NSCoder.h"
#import "Foundation/NSEnumerator.h"
#import "Foundation/NSKeyValueCoding.h"
#import "Foundation/NSValue.h"
#import "Foundation/NSException.h"
#import "Foundation/NSIndexSet.h"
// For private method _decodeArrayOfObjectsForKey:
#import "Foundation/NSKeyedArchiver.h"
#import "GSPrivate.h"
#import "GNUstepBase/NSObject+GNUstepBase.h"
#import "GSFastEnumeration.h"
#import "GSDispatch.h"

@class	GSOrderedSet;
@interface GSOrderedSet : NSObject	// Help the compiler
@end
@class	GSMutableOrderedSet;
@interface GSMutableOrderedSet : NSObject	// Help the compiler
@end

/**
 *  <code>NSOrderedSet</code> maintains an ordered collection of unique objects
 *  (according to [NSObject-isEqual:]).
 */
@implementation NSOrderedSet

static Class NSOrderedSet_abstract_class;
static Class NSMutableOrderedSet_abstract_class;
static Class NSOrderedSet_concrete_class;
static Class NSMutableOrderedSet_concrete_class;

+ (id) allocWithZone: (NSZone*)z
{
  if (self == NSOrderedSet_abstract_class)
    {
      return NSAllocateObject(NSOrderedSet_concrete_class, 0, z);
    }
  else
    {
      return NSAllocateObject(self, 0, z);
    }
}

+ (void) initialize
{
  if (self == [NSOrderedSet class])
    {
      NSOrderedSet_abstract_class = self;
      NSOrderedSet_concrete_class = [GSOrderedSet class];
      [NSMutableOrderedSet class];
    }
}

/**
 *  New autoreleased empty set.
 */
+ (id) orderedSet
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()] init]);
}

/**
 *  New set containing (unique elements of) objects.
 */
+ (id) orderedSetWithArray: (NSArray*)objects
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithArray: objects]);
}

+ (id) orderedSetWithArray: (NSArray*)objects
                     range: (NSRange)range
                 copyItems: (BOOL)copyItems
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithArray: objects range: range copyItems: copyItems]);
}

/**
 *  New set containing single object anObject.
 */
+ (id) orderedSetWithObject: anObject
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithObjects: &anObject count: 1]);
}

/**
 *  New set containing (unique elements of) objects.
 */
+ (id) orderedSetWithObjects: (const id[])objects
	               count: (NSUInteger)count
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithObjects: objects count: count]);
}

/**
 *  New set with objects in given nil-terminated list.
 */
+ (id) orderedSetWithObjects: firstObject, ...
{
  id	set;

  GS_USEIDLIST(firstObject,
    set = [[self allocWithZone: NSDefaultMallocZone()]
      initWithObjects: __objects count: __count]);
  return AUTORELEASE(set);
}

/**
 *  Copy constructor.
 */
+ (id) orderedSetWithSet: (NSSet*)aSet
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithSet: aSet]);
}

+ (id) orderedSetWithSet: (NSSet*)aSet
               copyItems: (BOOL)copyItems
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithSet: aSet copyItems: copyItems]);
}

- (Class) classForCoder
{
  return NSOrderedSet_abstract_class;
}

/**
 * Returns a new copy of the receiver.<br />
 * The default abstract implementation of a copy is to use the
 * -initWithOrderedSet:copyItems: method with the flag set to YES.<br />
 * Concrete subclasses generally simply retain and return the receiver.
 */
- (id) copyWithZone: (NSZone*)z
{
  NSOrderedSet *copy = [NSOrderedSet_concrete_class allocWithZone: z];

  return [copy initWithOrderedSet: self copyItems: YES];
}

/**
 * Returns the number of objects stored in the set.
 */
- (NSUInteger) count
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      /* HACK ... MacOS-X seems to code differently if the coder is an
       * actual instance of NSKeyedArchiver
       */
      if ([aCoder class] == [NSKeyedArchiver class])
	{
	  [(NSKeyedArchiver*)aCoder _encodeArrayOfObjects: [self allObjects]
						   forKey: @"NS.objects"];
	}
      else
	{
	  unsigned	i = 0;
	  NSEnumerator	*e = [self objectEnumerator];
	  id		o;

	  while ((o = [e nextObject]) != nil)
	    {
	      NSString	*key;

	      key = [NSString stringWithFormat: @"NS.object.%u", i++];
	      [(NSKeyedArchiver*)aCoder encodeObject: o forKey: key];
	    }
	}
    }
  else
    {
      unsigned		count = [self count];
      NSEnumerator	*e = [self objectEnumerator];
      id		o;

      [aCoder encodeValueOfObjCType: @encode(unsigned) at: &count];
      while ((o = [e nextObject]) != nil)
	{
	  [aCoder encodeValueOfObjCType: @encode(id) at: &o];
	}
    }
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  Class		c;

  c = object_getClass(self);
  if (c == NSOrderedSet_abstract_class)
    {
      DESTROY(self);
      self = [NSOrderedSet_concrete_class allocWithZone: NSDefaultMallocZone()];
      return [self initWithCoder: aCoder];
    }
  else if (c == NSMutableOrderedSet_abstract_class)
    {
      DESTROY(self);
      self = [NSMutableOrderedSet_concrete_class allocWithZone: NSDefaultMallocZone()];
      return [self initWithCoder: aCoder];
    }

  if ([aCoder allowsKeyedCoding])
    {
      id	array;

      array = [(NSKeyedUnarchiver*)aCoder _decodeArrayOfObjectsForKey:
						@"NS.objects"];
      if (array == nil)
	{
	  unsigned	i = 0;
	  NSString	*key;
	  id		val;

	  array = [NSMutableArray arrayWithCapacity: 2];
	  key = [NSString stringWithFormat: @"NS.object.%u", i];
	  val = [(NSKeyedUnarchiver*)aCoder decodeObjectForKey: key];

	  while (val != nil)
	    {
	      [array addObject: val];
	      i++;
	      key = [NSString stringWithFormat: @"NS.object.%u", i];
	      val = [(NSKeyedUnarchiver*)aCoder decodeObjectForKey: key];
	    }
	}
      self = [self initWithArray: array];
    }
  else
    {
      unsigned	count;

      [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
      if (count > 0)
        {
	  unsigned	i;
	  GS_BEGINIDBUF(objs, count);

	  for (i = 0; i < count; i++)
	    {
	      [aCoder decodeValueOfObjCType: @encode(id) at: &objs[i]];
	    }
	  self = [self initWithObjects: objs count: count];
#if	GS_WITH_GC == 0
	  while (count-- > 0)
	    {
	      [objs[count] release];
	    }
#endif
	  GS_ENDIDBUF();
	}
    }
  return self;
}

/**
 * <p>In MacOS-X class clusters do not have designated initialisers,
 * and there is a general rule that -init is treated as the designated
 * initialiser of the class cluster, but that other intitialisers
 * may not work as expected and would need to be individually overridden
 * in any subclass.
 * </p>
 * <p>GNUstep tries to make it easier to subclass a class cluster,
 * by making class clusters follow the same convention as normal
 * classes, so the designated initialiser is the <em>richest</em>
 * initialiser.  This means that all other initialisers call the
 * documented designated initialiser (which calls -init only for
 * MacOS-X compatibility), and anyone writing a subclass only needs
 * to override that one initialiser in order to have all the other
 * ones work.
 * </p>
 * <p>For MacOS-X compatibility, you may also need to override various
 * other initialisers.  Exactly which ones, you will need to determine
 * by trial on a MacOS-X system ... and may vary between releases of
 * MacOS-X.  So to be safe, on MacOS-X you probably need to re-implement
 * <em>all</em> the class cluster initialisers you might use in conjunction
 * with your subclass.
 * </p>
 */
- (id) init
{
  self = [super init];
  return self;
}

- (id) initWithObject: (id)anObject
{
  self = [self init];
  return self;
}

/**
 *  Initialize with (unique elements of) objects in given nil-terminated list.
 */
- (id) initWithObjects: firstObject, ...
{
  GS_USEIDLIST(firstObject,
    self = [self initWithObjects: __objects count: __count]);
  return self;
}

/** <init /> <override-subclass />
 * Initialize to contain (unique elements of) objects.<br />
 * Calls -init (which does nothing but maintain MacOS-X compatibility),
 * and needs to be re-implemented in subclasses in order to have all
 * other initialisers work.
 */
- (id) initWithObjects: (const id[])objects
		 count: (NSUInteger)count
{
  self = [self init];
  return self;
}

/**
 * Returns a new instance containing the same objects as
 * the receiver.<br />
 * The default implementation does this by calling the
 * -initWithSet:copyItems: method on a newly created object,
 * and passing it NO to tell it just to retain the items.
 */
- (id) mutableCopyWithZone: (NSZone*)z
{
  NSMutableOrderedSet *copy = [NSMutableOrderedSet_concrete_class allocWithZone: z];

  return [copy initWithOrderedSet: self copyItems: NO];
}

/**
 *  Return enumerator over objects in set.
 */
- (NSEnumerator*) objectEnumerator
{
  return [self subclassResponsibility: _cmd];
}

/**
 *  Return enumerator over objects in set.  Order is reversed.
 */
- (NSEnumerator*) reverseObjectEnumerator
{
  return [self subclassResponsibility: _cmd];
}

- (NSOrderedSet*) reversedOrderedSet
{
  return [self subclassResponsibility: _cmd];
}

- (void) getObjects: (id __unsafe_unretained [])objects
              range: (NSRange)range
{
  [self subclassResponsibility: _cmd];
}

/**
 *  If anObject is in set, return it (the copy in the set).
 */
- (id) member: (id)anObject
{
  return [self subclassResponsibility: _cmd];
}

/**
 * Initialises a newly allocated set by adding all the objects
 * in the supplied array to the set.
 */
- (id) initWithArray: (NSArray*)other
{
  return [self initWithArray: other range: NSMakeRange(0, [other count]) copyItems: NO];
}

- (id) initWithArray: (NSArray*)other
           copyItems: (BOOL)copyItems
{
  return [self initWithArray: other range: NSMakeRange(0, [other count]) copyItems: copyItems];
}

- (id) initWithArray: (NSArray*)other
               range: (NSRange)range
           copyItems: (BOOL)copyItems
{
  if (range.length == 0)
    {
      return [self init];
    }
  else
    {
      GS_BEGINIDBUF(objs, range.length);

      unsigned	i;

      for (i = 0; i < range.length; i++)
        {
          if (copyItems)
            {
              objs[i] = [[other objectAtIndex: i+range.location] copy];
            }
	  else
            {
              objs[i] = [other objectAtIndex: i+range.location];
            }
        }
      self = [self initWithObjects: objs count: range.length];
      GS_ENDIDBUF();
      return self;
    }
}

- (id) initWithOrderedSet: (NSOrderedSet*)other
                    range: (NSRange)range
                copyItems: (BOOL)copyItems
{
  if (range.length == 0)
    {
      return [self init];
    }
  else
    {
      GS_BEGINIDBUF(objs, range.length);

      unsigned	i;

      for (i = 0; i < range.length; i++)
        {
          if (copyItems)
            {
              objs[i] = [[other objectAtIndex: i+range.location] copy];
            }
	  else
            {
              objs[i] = [other objectAtIndex: i+range.location];
            }
        }
      self = [self initWithObjects: objs count: range.length];
      GS_ENDIDBUF();
      return self;
    }
}

- (id) initWithOrderedSet: (NSOrderedSet*)other
{
  return [self initWithOrderedSet: other range: NSMakeRange(0, [other count]) copyItems: NO];
}

- (id) initWithOrderedSet: (NSOrderedSet*)other
                copyItems: (BOOL)copyItems
{
  return [self initWithOrderedSet: other range: NSMakeRange(0, [other count]) copyItems: copyItems];
}

/**
 * Initialises a newly allocated set by adding all the objects
 * in the supplied set.
 */
- (id) initWithSet: (NSSet*)other copyItems: (BOOL)copyItems
{
  unsigned	c = [other count];
  id		o, e = [other objectEnumerator];
  unsigned	i = 0;
  GS_BEGINIDBUF(os, c);

  while ((o = [e nextObject]))
    {
      if (copyItems)
	os[i] = [o copy];
      else
	os[i] = o;
      i++;
    }
  self = [self initWithObjects: os count: c];
#if	!GS_WITH_GC
  if (copyItems)
    while (i--)
      [os[i] release];
#endif
  GS_ENDIDBUF();
  return self;
}

/**
 *  Initialize with same items as other (items not copied).
 */
- (id) initWithSet: (NSSet*)other
{
  return [self initWithSet: other copyItems: NO];
}

/**
 *  Return array of all objects in set.  Order is undefined.
 */
- (NSArray*) allObjects
{
  id		e = [self objectEnumerator];
  unsigned	i;
  unsigned	c = [self count];
  NSArray	*result = nil;
  GS_BEGINIDBUF(k, c);

  for (i = 0; i < c; i++)
    {
      k[i] = [e nextObject];
    }
  return AUTORELEASE([[NSArray allocWithZone: NSDefaultMallocZone()]
    initWithObjects: k count: c]);
  GS_ENDIDBUF();
  return result;
}

/**
 *  Return whether set contains an object equal to this one according
 *  to [NSObject-isEqual:].
 */
- (BOOL) containsObject: (id)anObject
{
  return (([self member: anObject]) ? YES : NO);
}

- (NSUInteger) hash
{
  return [self count];
}

- (id) firstObject
{
  if ([self count] == 0)
    return nil;
  else
    {
      return [self objectAtIndex: 0];
    }
}

- (id) lastObject
{
  if ([self count] == 0)
    return nil;
  else
    {
      return [self objectAtIndex: [self count] - 1];
    }
}

- (id) objectAtIndex: (NSUInteger)index
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (id) objectAtIndexedSubscript: (NSUInteger)index
{
  return [self objectAtIndex: index];
}

- (NSArray*) objectsAtIndexes: (NSIndexSet*)indexes
{
  NSArray      *array = nil;
  unsigned	c = [indexes count];
  unsigned	i = 0;
  NSRange       range = NSMakeRange(0, c);

  GS_BEGINITEMBUF(ib, c, NSUInteger);
  [indexes getIndexes: ib maxCount: c inIndexRange: &range];

  GS_BEGINIDBUF(os, c);

  for (i = 0; i < c; i++)
    {
      os[i] = [self objectAtIndex: ib[i]];
    }
  array = [[NSArray alloc] initWithObjects: os count: c];
  GS_ENDIDBUF();
  GS_ENDITEMBUF();
  return array;
}

- (NSUInteger) indexOfObject: (id)object
{
  [self subclassResponsibility: _cmd];
  return 0;
}

- (NSUInteger) indexOfObject: (id)object
               inSortedRange: (NSRange)range
                     options: (NSBinarySearchingOptions)opts
             usingComparator: (NSComparator)cmp
{
  [self subclassResponsibility: _cmd];
  return 0;
}

/**
 *  Return whether set intersection with otherSet is non-empty.
 */
- (BOOL) intersectsOrderedSet: (NSOrderedSet*) otherSet
{
  id	o = nil, e = nil;

  // -1. If this set is empty, this method should return NO.
  if ([self count] == 0)
    return NO;

  // 0. Loop for all members in otherSet
  e = [otherSet objectEnumerator];
  while ((o = [e nextObject])) // 1. pick a member from otherSet.
    {
      if ([self member: o])    // 2. check the member is in this set(self).
        return YES;
    }
  return NO;
}

/**
 *  Return whether set intersection with otherSet is non-empty.
 */
- (BOOL) intersectsSet: (NSSet*) otherSet
{
  id	o = nil, e = nil;

  // -1. If this set is empty, this method should return NO.
  if ([self count] == 0)
    return NO;

  // 0. Loop for all members in otherSet
  e = [otherSet objectEnumerator];
  while ((o = [e nextObject])) // 1. pick a member from otherSet.
    {
      if ([self member: o])    // 2. check the member is in this set(self).
        return YES;
    }
  return NO;
}

/**
 *  Return whether subset of otherSet.
 */
- (BOOL) isSubsetOfOrderedSet: (NSOrderedSet*) otherSet
{
  id o = nil, e = nil;

  // -1. members of this set(self) <= that of otherSet
  if ([self count] > [otherSet count])
    return NO;

  // 0. Loop for all members in this set(self).
  e = [self objectEnumerator];
  while ((o = [e nextObject]))
    {
      // 1. check the member is in the otherSet.
      if ([otherSet member: o])
       {
         // 1.1 if true -> continue, try to check the next member.
         continue ;
       }
      else
       {
         // 1.2 if false -> return NO;
         return NO;
       }
    }
  // 2. return YES; all members in this set are also in the otherSet.
  return YES;
}

/**
 *  Return whether subset of otherSet.
 */
- (BOOL) isSubsetOfSet: (NSSet*) otherSet
{
  id o = nil, e = nil;

  // -1. members of this set(self) <= that of otherSet
  if ([self count] > [otherSet count])
    return NO;

  // 0. Loop for all members in this set(self).
  e = [self objectEnumerator];
  while ((o = [e nextObject]))
    {
      // 1. check the member is in the otherSet.
      if ([otherSet member: o])
       {
         // 1.1 if true -> continue, try to check the next member.
         continue ;
       }
      else
       {
         // 1.2 if false -> return NO;
         return NO;
       }
    }
  // 2. return YES; all members in this set are also in the otherSet.
  return YES;
}

- (BOOL) isEqual: (id)other
{
  if ([other isKindOfClass: [NSOrderedSet class]])
    return [self isEqualToOrderedSet: other];
  return NO;
}

/**
 *  Return whether each set is subset of the other.
 */
- (BOOL) isEqualToOrderedSet: (NSOrderedSet*)other
{
  if ([self count] != [other count])
    return NO;
  else
    {
      id	o, e = [self objectEnumerator];

      while ((o = [e nextObject]))
	if (![other member: o])
	  return NO;
    }
  /* xxx Recheck this. */
  return YES;
}

- (NSArray*) sortedArrayUsingComparator: (NSComparator)comparator
{
  return [self sortedArrayWithOptions: 0 usingComparator: comparator];
}

- (NSArray*) sortedArrayWithOptions: (NSSortOptions)opts
                    usingComparator: (NSComparator)comparator;
{
  // TODO:
  return nil;
}

/**
 *  Returns listing of objects in set.
 */
- (NSString*) description
{
  return [self descriptionWithLocale: nil];
}

/**
 *  Returns listing of objects in set.
 */
- (NSString*) descriptionWithLocale: (id)locale
{
  return [[self allObjects] descriptionWithLocale: locale];
}

- (NSString*) descriptionWithLocale: (id)locale
                             indent: (NSUInteger)level
{
  // TODO: indent
  return [[self allObjects] descriptionWithLocale: locale];
}

- (NSArray*) array
{
  return [self allObjects];
}

- (NSSet*) set
{
  // TODO
  return nil;
}

- (void) setValue: (id)value
           forKey: (NSString*)key
{
}

- (id) valueForKey: (NSString*)key
{
  // TODO
  return nil;
}

- (void) addObserver: (NSObject*)observer
          forKeyPath: (NSString*)keyPath
             options: (NSKeyValueObservingOptions)options
             context: (void*)context
{
  // TODO
}

- (void) removeObserver: (NSObject*)observer
             forKeyPath: (NSString*)keyPath
{
  // TODO
}

- (void) removeObserver: (NSObject*)observer
             forKeyPath: (NSString*)keyPath
                context: (void*)context
{
  // TODO
}

- (id) valueForKeyPath: (NSString*)path
{
  id result = (id) nil;

  if ([path hasPrefix: @"@"])
    {
      NSRange   r;

      r = [path rangeOfString: @"."];
      if (r.length == 0)
        {
          if ([path isEqualToString: @"@count"] == YES)
            {
              result = [NSNumber numberWithUnsignedInt: [self count]];
            }
          else
            {
              result = [self valueForKey: path];
            }
        }
      else
        {
          NSString      *op = [path substringToIndex: r.location];
          NSString      *rem = [path substringFromIndex: NSMaxRange(r)];
          unsigned      count = [self count];

          if ([op isEqualToString: @"@count"] == YES)
            {
              result = [NSNumber numberWithUnsignedInt: count];
            }
          else if ([op isEqualToString: @"@avg"] == YES)
            {
              double        d = 0;

              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  while ((o = [e nextObject]) != nil)
                    {
                      d += [[o valueForKeyPath: rem] doubleValue];
                    }
                  d /= count;
                }
              result = [NSNumber numberWithDouble: d];
            }
          else if ([op isEqualToString: @"@max"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      if (result == nil
                        || [result compare: o] == NSOrderedAscending)
                        {
                          result = o;
                        }
                    }
                }
            }
          else if ([op isEqualToString: @"@min"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      if (result == nil
                        || [result compare: o] == NSOrderedDescending)
                        {
                          result = o;
                        }
                    }
                }
            }
          else if ([op isEqualToString: @"@sum"] == YES)
            {
              double        d = 0;

              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  while ((o = [e nextObject]) != nil)
                    {
                      d += [[o valueForKeyPath: rem] doubleValue];
                    }
                }
              result = [NSNumber numberWithDouble: d];
            }
          else if ([op isEqualToString: @"@distinctUnionOfArrays"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [NSMutableOrderedSet orderedSet];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObjectsFromArray: o];
                    }
                  result = [result allObjects];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else if ([op isEqualToString: @"@distinctUnionOfObjects"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [NSMutableOrderedSet orderedSet];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObject: o];
                    }
                  result = [result allObjects];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else if ([op isEqualToString: @"@distinctUnionOfSets"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [NSMutableOrderedSet orderedSet];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObjectsFromArray: [o allObjects]];
                    }
                  result = [result allObjects];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else if ([op isEqualToString: @"@unionOfArrays"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [GSMutableArray array];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObjectsFromArray: o];
                    }
                  [result makeImmutableCopyOnFail: NO];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else if ([op isEqualToString: @"@unionOfObjects"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [GSMutableArray array];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObject: o];
                    }
                  [result makeImmutableCopyOnFail: NO];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else if ([op isEqualToString: @"@unionOfSets"] == YES)
            {
              if (count > 0)
                {
                  NSEnumerator  *e = [self objectEnumerator];
                  id            o;

                  result = [GSMutableArray array];
                  while ((o = [e nextObject]) != nil)
                    {
                      o = [o valueForKeyPath: rem];
                      [result addObjectsFromArray: [o allObjects]];
                    }
                  [result makeImmutableCopyOnFail: NO];
                }
              else
                {
                  result = [NSArray array];
                }
            }
          else
            {
              result = [super valueForKeyPath: path];
            }
        }
    }
  else
    {
      result = [super valueForKeyPath: path];
    }

  return result;
}

- (void) enumerateObjectsAtIndexes: (NSIndexSet*)indexSet
                           options: (NSEnumerationOptions)opts
                        usingBlock: (GSOrderedSetEnumeratorBlock)block
{
  // TODO
}

- (void) enumerateObjectsUsingBlock: (GSOrderedSetEnumeratorBlock)aBlock
{
  [self enumerateObjectsWithOptions: 0 usingBlock: aBlock];
}

- (void) enumerateObjectsWithOptions: (NSEnumerationOptions)opts
                          usingBlock: (GSOrderedSetEnumeratorBlock)aBlock
{
  BLOCK_SCOPE BOOL shouldStop = NO;
  id<NSFastEnumeration> enumerator = self;
  NSUInteger index = 0;

  GS_DISPATCH_CREATE_QUEUE_AND_GROUP_FOR_ENUMERATION(enumQueue, opts)
  FOR_IN (id, obj, enumerator)
  {
    GS_DISPATCH_SUBMIT_BLOCK(enumQueueGroup,enumQueue, if (shouldStop) {return;}, return;, aBlock, obj, index, &shouldStop);
    if (shouldStop)
      {
	break;
      }
    index++;
  }
  END_FOR_IN(enumerator)
  GS_DISPATCH_TEARDOWN_QUEUE_AND_GROUP_FOR_ENUMERATION(enumQueue, opts)
}

- (NSUInteger) indexOfObjectAtIndexes: (NSIndexSet*)indexSet
                              options: (NSEnumerationOptions)opts
                          passingTest: (GSOrderedSetFilterBlock)aBlock
{
  // TODO
  return 0;
}

- (NSUInteger) indexOfObjectPassingTest: (GSOrderedSetFilterBlock)aBlock
{
  return [self indexOfObjectWithOptions: 0 passingTest: aBlock];
}

- (NSUInteger) indexOfObjectWithOptions: (NSEnumerationOptions)opts
                            passingTest: (GSOrderedSetFilterBlock)aBlock
{
  // TODO
  return 0;
}

- (NSIndexSet*) indexesOfObjectsAtIndexes: (NSIndexSet*)indexSet
                                  options: (NSEnumerationOptions)opts
                              passingTest: (GSOrderedSetFilterBlock)aBlock
{
  // TODO
  return nil;
}

- (NSIndexSet*) indexesOfObjectsPassingTest: (GSOrderedSetFilterBlock)aBlock;
{
  return [self indexesOfObjectsWithOptions: 0 passingTest: aBlock];
}

- (NSIndexSet*) indexesOfObjectsWithOptions: (NSEnumerationOptions)opts
                                passingTest: (GSOrderedSetFilterBlock)aBlock
{
  BOOL                  shouldStop = NO;
  id<NSFastEnumeration> enumerator = self;
  NSMutableIndexSet *resultSet = [NSMutableIndexSet indexSet];
  NSUInteger index = 0;

  FOR_IN (id, obj, enumerator)
    {
      BOOL include = CALL_BLOCK(aBlock, obj, index, &shouldStop);

      if (include)
        {
          [resultSet addIndex: index];
        }
      if (shouldStop)
        {
          break;
        }
      index++;
    }
  END_FOR_IN(enumerator)

  return [resultSet makeImmutableCopyOnFail: NO];
}

/** Return a set formed by adding anObject to the receiver.
 */
- (NSSet *) setByAddingObject: (id)anObject
{
  NSMutableSet  *m;
  NSSet         *s;

  m = [self mutableCopy];
  [m addObject: anObject];
  s = [m copy];
  [m release];
  return [s autorelease];
}

/** Return a set formed by adding the contents of other to the receiver.
 */
- (NSSet *) setByAddingObjectsFromArray: (NSArray *)other
{
  NSMutableSet  *m;
  NSSet         *s;

  m = [self mutableCopy];
  [m addObjectsFromArray: other];
  s = [m copy];
  [m release];
  return [s autorelease];
}

/** Return a set formed as a union of the receiver and other.
 */
- (NSSet *) setByAddingObjectsFromSet: (NSSet *)other
{
  NSMutableSet  *m;
  NSSet         *s;

  m = [self mutableCopy];
  [m unionSet: other];
  s = [m copy];
  [m release];
  return [s autorelease];
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state
                                   objects: (id*)stackbuf
                                     count: (NSUInteger)len
{
    [self subclassResponsibility: _cmd];
    return 0;
}
@end


/**
 *  Mutable version of [NSOrderedSet].
 */
@implementation NSMutableOrderedSet

+ (void) initialize
{
  if (self == [NSMutableOrderedSet class])
    {
      NSMutableOrderedSet_abstract_class = self;
      NSMutableOrderedSet_concrete_class = [GSMutableOrderedSet class];
    }
}

/**
 *  New autoreleased instance with given capacity.
 */
+ (id) orderedSetWithCapacity: (NSUInteger)numItems
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()]
    initWithCapacity: numItems]);
}

+ (id) allocWithZone: (NSZone*)z
{
  if (self == NSMutableOrderedSet_abstract_class)
    {
      return NSAllocateObject(NSMutableOrderedSet_concrete_class, 0, z);
    }
  else
    {
      return NSAllocateObject(self, 0, z);
    }
}

- (Class) classForCoder
{
  return NSMutableOrderedSet_abstract_class;
}

/** <init /> <override-subclass />
 * Initialises a newly allocated set to contain no objects but
 * to have space available to hold the specified number of items.<br />
 * Additions of items to a set initialised
 * with an appropriate capacity will be more efficient than addition
 * of items otherwise.<br />
 * Calls -init (which does nothing but maintain MacOS-X compatibility),
 * and needs to be re-implemented in subclasses in order to have all
 * other initialisers work.
 */
- (id) initWithCapacity: (NSUInteger)numItems
{
  self = [self init];
  return self;
}

/**
 * Adds anObject to the set.<br />
 * The object is retained by the set.
 */
- (void) addObject: (id)anObject
{
  [self subclassResponsibility: _cmd];
}

- (void) addObjects: (const id[])objects
              count: (NSUInteger)count
{
  unsigned i;

  for (i = 0; i < count; i++)
    {
      [self addObject: objects[i]];
    }
}

/**
 * Adds all the objects in the array to the receiver.
 */
- (void) addObjectsFromArray: (NSArray*)array
{
  unsigned i, c = [array count];

  for (i = 0; i < c; i++)
    {
      [self addObject: [array objectAtIndex: i]];
    }
}

- (void) insertObject: (id)anObject
              atIndex: (NSUInteger)index
{
  [self subclassResponsibility: _cmd];
}

- (void) setObject: (id)anObject
atIndexedSubscript: (NSUInteger)idx
{
  [self subclassResponsibility: _cmd];
}

- (void) insertObjects: (NSArray*)objects
             atIndexes: (NSIndexSet*)indexes
{
  [self subclassResponsibility: _cmd];
}

/**
 * Removes the anObject from the receiver.
 */
- (void) removeObject: (id)anObject
{
  [self subclassResponsibility: _cmd];
}

- (void) removeObjectAtIndex: (NSUInteger)index
{
  [self subclassResponsibility: _cmd];
}

- (void) removeObjectsAtIndexes: (NSIndexSet*)indexes
{
  [self subclassResponsibility: _cmd];
}

- (void) removeObjectsInArray: (NSArray*)array
{
  [self subclassResponsibility: _cmd];
}

- (void) removeObjectsInRange: (NSRange)range
{
  [self subclassResponsibility: _cmd];
}

/**
 * Removes all objects from the receiver.
 */
- (void) removeAllObjects
{
  [self subclassResponsibility: _cmd];
}

- (void) replaceObjectAtIndex: (NSUInteger)index
                   withObject: (id)anObject
{
  [self subclassResponsibility: _cmd];
}

- (void) replaceObjectsAtIndexes: (NSIndexSet*)indexes
                     withObjects: (NSArray*)objects
{
  [self subclassResponsibility: _cmd];
}

- (void) replaceObjectsInRange: (NSRange)range
                   withObjects: (const id[])objects
                         count: (NSUInteger)count
{
  [self subclassResponsibility: _cmd];
}

- (void) setObject: (id)anObject
           atIndex: (NSUInteger)index
{
  [self subclassResponsibility: _cmd];
}

- (void) moveObjectsAtIndexes: (NSIndexSet*)indexes
                      toIndex: (NSUInteger)index
{
  [self subclassResponsibility: _cmd];
}

- (void) exchangeObjectAtIndex: (NSUInteger)index1
             withObjectAtIndex: (NSUInteger)index2
{
  [self subclassResponsibility: _cmd];
}

- (id) initWithObjects: (const id[])objects
		 count: (NSUInteger)count
{
  self = [self initWithCapacity: count];
  if (self != nil)
    {
      while (count--)
	{
	  [self addObject: objects[count]];
	}
    }
  return self;
}

/**
 * Removes from the receiver all the objects it contains
 * which are not also in other.
 */
- (void) intersectOrderedSet: (NSOrderedSet*) other
{
  if (other != self)
    {
      id keys = [self objectEnumerator];
      id key;

      while ((key = [keys nextObject]))
	{
	  if ([other containsObject: key] == NO)
	    {
	      [self removeObject: key];
	    }
	}
    }
}

/**
 * Removes from the receiver all the objects it contains
 * which are not also in other.
 */
- (void) intersectSet: (NSSet*) other
{
  id keys = [self objectEnumerator];
  id key;

  while ((key = [keys nextObject]))
    {
      if ([other containsObject: key] == NO)
        {
          [self removeObject: key];
        }
    }
}

/**
 * Removes from the receiver all the objects that are in
 * other.
 */
- (void) minusOrderedSet: (NSOrderedSet*) other
{
  if (other == self)
    {
      [self removeAllObjects];
    }
  else
    {
      id keys = [other objectEnumerator];
      id key;

      while ((key = [keys nextObject]))
	{
	  [self removeObject: key];
	}
    }
}

/**
 * Removes from the receiver all the objects that are in
 * other.
 */
- (void) minusSet: (NSSet*) other
{
  id keys = [other objectEnumerator];
  id key;

  while ((key = [keys nextObject]))
    {
      [self removeObject: key];
    }
}

/**
 * Adds all the objects from other to the receiver.
 */
- (void) unionOrderedSet: (NSOrderedSet*) other
{
  if (other != self)
    {
      id keys = [other objectEnumerator];
      id key;

      while ((key = [keys nextObject]))
	{
	  [self addObject: key];
	}
    }
}

/**
 * Adds all the objects from other to the receiver.
 */
- (void) unionSet: (NSSet*) other
{
  id keys = [other objectEnumerator];
  id key;

  while ((key = [keys nextObject]))
    {
      [self addObject: key];
    }
}

@end
