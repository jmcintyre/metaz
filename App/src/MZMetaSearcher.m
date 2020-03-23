//
//  MZMetaSearch.m
//  MetaZ
//
//  Created by Brian Olsen on 04/09/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import "MZMetaSearcher.h"


@implementation MZMetaSearcher

#pragma mark - initialization 

static MZMetaSearcher* sharedSearcher = nil;

+(MZMetaSearcher *)sharedSearcher {
    if(!sharedSearcher)
        [[MZMetaSearcher alloc] init];
    return sharedSearcher;
}

-(id)init {
    self = [super init];

    if(sharedSearcher)
    {
        self = sharedSearcher;
    } else if(self)
    {
        results = [[NSMutableArray alloc] init];
        //[results addObject:[MZSearchResult result]];
        sharedSearcher = self;
    }
    return self;
}

#pragma mark - properties
@synthesize results;

- (id)fakeResult
{
    if(hasFake)
        return [results objectAtIndex:0];
    return nil;
}

- (void)setFakeResult:(id)result
{
    [self willChangeValueForKey:@"results"];
    if(!result)
    {
        if(hasFake)
            [results removeObjectAtIndex:0];
        hasFake = NO;
    }
    else if(hasFake)
    {
        [results replaceObjectAtIndex:0 withObject:result];
    }
    else
    {
        [results insertObject:result atIndex:0];
        hasFake = YES;
    }
    [self didChangeValueForKey:@"results"];
}

#pragma mark - Actions

- (void)startSearchWithData:(NSDictionary *)data;
{
    [self clearResults];
    [[MZPluginController sharedInstance] searchAllWithData:data delegate:self];
}

- (void)clearResults
{
    NSInteger expected = hasFake ? 1 : 0;
    if([results count] > expected)
    {
        [self willChangeValueForKey:@"results"];
        if(!hasFake)
            [results removeAllObjects];
        else
            [results removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [results count]-1)]];
        [self didChangeValueForKey:@"results"];
    }
}


#pragma mark - MZSearchProviderDelegate implementation

- (void) searchProvider:(MZSearchProviderPlugin *)provider result:(NSArray*)result
{
    [self willChangeValueForKey:@"results"];
    [results addObjectsFromArray:result];
    [self didChangeValueForKey:@"results"];
}

@end
