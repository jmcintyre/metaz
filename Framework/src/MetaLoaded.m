//
//  MetaLoaded.m
//  MetaZ
//
//  Created by Brian Olsen on 25/08/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import <MetaZKit/MetaLoaded.h>
#import <MetaZKit/MZPluginController.h>
#import <MetaZKit/MZTag.h>
//#import <MetaZKit/MetaEdits.h>

@implementation MetaLoaded
@synthesize loadedFileName;
@synthesize owner;

+ (id)metaWithOwner:(id)theOwner filename:(NSString *)aFileName dictionary:(NSDictionary *)dict;
{
    return [[self alloc] initWithOwner:theOwner filename:aFileName dictionary:dict];
}

-(id)initWithOwner:(id)theOwner filename:(NSString *)aFileName dictionary:(NSDictionary *)dict {
    self = [super init];
    if(self)
    {
        owner = theOwner;
        loadedFileName = aFileName;
        values = [[NSDictionary alloc]initWithDictionary:dict];
        for(MZTag* tag in [owner providedTags])
        {
            NSString* key = [tag identifier];
            [self addMethodGetterForKey:key ofType:1 withObjCType:[tag encoding]];
        }
    }
    return self;
}

-(NSArray *)providedTags {
    return [owner providedTags];
}

- (id<MetaData>)pure
{
    return self;
}

- (void)prepareForQueue
{
}

- (void)prepareFromQueue
{
}


-(id)getterValueForKey:(NSString *)aKey
{
    id ret = [values objectForKey:aKey];
    MZTag* tag = [MZTag tagForIdentifier:aKey];
    return [tag convertObjectForRetrival:ret];
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

#pragma mark - NSCoding implementation

- (id)initWithCoder:(NSCoder *)decoder
{
    NSDictionary* dict;
    NSString* loadedFile;
    id theOwner;
    NSString * ownerId;
    if([decoder allowsKeyedCoding])
    {
        loadedFile = [decoder decodeObjectForKey:@"loadedFileName"];
        dict = [decoder decodeObjectForKey:@"values"];
        theOwner = [decoder decodeObjectForKey:@"owner"];
        if(!theOwner)
            ownerId = [decoder decodeObjectForKey:@"ownerId"];
    }
    else
    {
        loadedFile = [decoder decodeObject];
        dict = [decoder decodeObject];
        theOwner = [decoder decodeObject];
        ownerId = [decoder decodeObject];
    }
    if(!theOwner)
    {
        theOwner = [[MZPluginController sharedInstance]
            dataProviderWithIdentifier:ownerId];
    }
    return [self initWithOwner:theOwner filename:loadedFile dictionary:dict];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if([encoder allowsKeyedCoding])
    {
        [encoder encodeObject:loadedFileName forKey:@"loadedFileName"];
        [encoder encodeObject:values forKey:@"values"];
        [encoder encodeConditionalObject:owner forKey:@"owner"];
        [encoder encodeObject:[owner identifier] forKey:@"ownerId"];
    }
    else
    {
        [encoder encodeObject:loadedFileName];
        [encoder encodeObject:values];
        [encoder encodeConditionalObject:owner];
        [encoder encodeObject:[owner identifier]];
    }
}

#pragma mark - NSCopying implementation

- (id)copyWithZone:(NSZone *)zone
{
    //return [[MetaLoaded alloc] initWithFilename:loadedFileName dictionary:values];
    return self;
}

@end
