//
//  NSMutableArray+Queue.m
//  Hello
//
//  Created by James Mattis on 3/22/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

-(id)headOfQueue
{
    if (self.count > 0)
    {
        id object = [self objectAtIndex:0];
        
        return object;
    }
    else
    {
        return nil;
    }
}

-(id)dequeue
{
    if (self.count > 0)
    {
        id object = [self objectAtIndex:0];
        
        if (object != nil)
        {
            [self removeObjectAtIndex:0];
        }
        
        return object;
    }
    else
    {
        return nil;
    }
}

-(void)enqueue:(id)object
{
    [self addObject:object];
}

@end
