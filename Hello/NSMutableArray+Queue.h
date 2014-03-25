//
//  NSMutableArray+Queue.h
//  Hello
//
//  Created by James Mattis on 3/22/14.
//  Copyright (c) 2014 World Champ Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)

-(id)headOfQueue;
-(id)dequeue;
-(void)enqueue:(id)object;

@end
