//
//  PureMetaEdits.m
//  MetaZ
//
//  Created by Brian Olsen on 15/10/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import "PureMetaEdits.h"
#import <MetaZKit/MZTag.h>

@implementation PureMetaEdits

- (id)initWithEdits:(MetaEdits *)theEdits
{
    self = [super init];
    if(self)
    {
        edits = theEdits;
        NSArray* tags = [edits providedTags];
        for(MZTag* tag in tags)
        {
            NSString* key = [tag identifier];
            NSObject<TagData>* pure = edits.provider.pure;
            [pure addObserver: self 
                   forKeyPath: key
                      options: NSKeyValueObservingOptionPrior
                      context: nil];
            [self addMethodGetterForKey:key ofType:1 withObjCType:[tag encoding]];
        }

    }
    return self;
}

- (void)dealloc
{
    NSObject<TagData>* pure = edits.provider.pure;
    NSArray* tags = [edits providedTags];
    for(MZTag *tag in tags)
        [pure removeObserver:self forKeyPath: [tag identifier]];
}

- (id)owner
{
    return [edits owner];
}

-(id)getterValueForKey:(NSString *)aKey
{
    id ret = [edits.changes objectForKey:aKey];
    if(ret != nil) // Changed
    {
        MZTag* tag = [MZTag tagForIdentifier:aKey];
        return [tag convertObjectForRetrival:ret];
    }
    NSObject<TagData>* pure = edits.provider.pure;
    return [pure valueForKey:aKey];
}

#pragma mark - MZDynamicObject handling

-(void)handleDataForKey:(NSString *)aKey ofType:(NSUInteger)aType forInvocation:(NSInvocation *)anInvocation
{
    id ret = [self getterValueForKey:aKey];
    [anInvocation setReturnObject:ret];
}

-(id)handleDataForMethod:(NSString *)aMethod withKey:(NSString *)aKey ofType:(NSUInteger)aType
{
    return [self getterValueForKey:aKey];
}


#pragma mark - as observer

- (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber * prior = [change objectForKey:NSKeyValueChangeNotificationIsPriorKey];
    if([prior boolValue])
        [self willChangeValueForKey:key];
    else
        [self didChangeValueForKey:key];
}

#pragma mark - NSCoding implementation

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        edits = [decoder decodeObjectForKey:@"edits"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:edits forKey:@"edits"];
}

#pragma mark - NSCopying implementation

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
