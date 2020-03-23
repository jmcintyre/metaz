//
//  MZMetaDataDocument.m
//  MetaZ
//
//  Created by Brian Olsen on 15/07/12.
//  Copyright 2012 Maven-Group. All rights reserved.
//
#import "MZMetaDataDocument.h"
#import "MetaZApplication.h"
#import "MZMetaLoader.h"
#import "MZScriptingAdditions.h"
#import "MZScriptingEnums.h"
#import <MetaZKit/MZLogger.h>

@implementation MZTagItem

+ (id)itemWithTag:(MZTag*)theTag document:(MZMetaDataDocument *)theDocument;
{
    return [[self alloc] initWithTag:theTag document:theDocument];
}

- (id)initWithTag:(MZTag*)theTag document:(MZMetaDataDocument *)theDocument;
{
    self = [super init];
    if(self) {
        tag = theTag;
        document = theDocument;
    }
    return self;
}

- (NSString *)name
{
    return tag.scriptName;
}

- (id)value
{
    id pure = document.data.pure;
    return [pure valueForKey:tag.identifier];
}

- (void)setValue:(id)value
{
    [document.data setValue:value forKey:tag.identifier];
}

- (id)scriptValue
{
    id value = self.value;
    if(value)
    {
        if([tag isKindOfClass:[MZEnumTag class]] )
        {
            id eTag = tag;
            value = [[MZScriptingEnums scriptingEnumsForMainBundle]
                            enumValueForEnum:[eTag enumScriptName]
                                   withValue:value];
        }
        else
        {
            id specifier = [value objectSpecifier];
            if(specifier)
                value = specifier;
        }
    }
    return value;
}

- (void)setScriptValue:(id)value
{
    if([value isKindOfClass:[NSAppleEventDescriptor class]])
        value = [value objectValue];
    MZLoggerDebug(@"Set Value %@ %@ %@", document.data, value, tag.identifier);
    self.value = value;
}

- (NSScriptObjectSpecifier *)objectSpecifier;
{
    NSScriptObjectSpecifier* objectSpecifier = [document objectSpecifier];
    return [[NSNameSpecifier alloc]
        initWithContainerClassDescription:[objectSpecifier keyClassDescription]
                       containerSpecifier:objectSpecifier
                                      key:@"tags"
                                    name:self.name];
}

@end


@implementation MZMetaDataDocument

+ (void) initialize {
	[super initialize];
	static BOOL tooLate = NO;
	if( ! tooLate ) {
		[[NSScriptCoercionHandler sharedCoercionHandler] registerCoercer:[self class] selector:@selector( coerceMetaDataDocument:toString: ) toConvertFromClass:[MZMetaDataDocument class] toClass:[NSString class]];
		tooLate = YES;
	}
}

+ (id) coerceMetaDataDocument:(MZMetaDataDocument *) value toString:(Class) class
{
	return [value.data loadedFileName];
}

+ (id)documentWithEdit:(MetaEdits *)edit;
{
    return [[self alloc] initWithEdit:edit];
}

+ (id)documentWithEdit:(MetaEdits *)edit container:(NSString *)container saved:(BOOL)saved;
{
    return [[self alloc] initWithEdit:edit container:container saved:saved];
}

- (id)initWithEdit:(MetaEdits *)edit;
{
    return [self initWithEdit:edit container:@"orderedDocuments" saved:NO];
}

- (id)initWithEdit:(MetaEdits *)edit container:(NSString *)aContainer saved:(BOOL)theSaved;
{
    self = [super init];
    if(self)
    {
        data = edit;
        container = aContainer;
        saved = theSaved;
    }
    return self;
}

@synthesize data;

- (NSURL *)fileURL;
{
    return [NSURL fileURLWithPath:saved ? [data savedFileName] : [data loadedFileName]];
}

- (NSString *)displayName;
{
    return [[[data loadedFileName] lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL)isDocumentEdited;
{
    return [data changed];
}

- (MZTimeCode *)duration;
{
    return [data duration];
}

- (NSArray *)tags;
{
    if(!tags)
    {
        NSMutableArray* ret = [NSMutableArray array];
        for(MZTag* tag in [data providedTags])
        {
            [ret addObject:[MZTagItem itemWithTag:tag document:self]];
        }
        tags = [[NSArray alloc] initWithArray:ret];
    }
    return tags;
}

- (id)valueInTagsWithName:(NSString *)name
{
    MZTag* tag = [MZTag tagForScriptName:[name lowercaseString]];
    if(tag)
        return [MZTagItem itemWithTag:tag document:self];
    return nil;
}

- (NSScriptObjectSpecifier *)objectSpecifier;
{
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)
        [NSScriptClassDescription classDescriptionForClass:[MetaZApplication class]];// 1
    return [[NSNameSpecifier alloc]
        initWithContainerClassDescription:containerClassDesc
        containerSpecifier:nil key:container
        name:[self displayName]];
}

- (id)handleCloseScriptCommand:(NSScriptCommand *)cmd;
{
    NSUInteger idx = [[MZMetaLoader sharedLoader].files indexOfObject:data];
    if(idx != NSNotFound)
        [[MZMetaLoader sharedLoader] removeFilesAtIndexes:[NSIndexSet indexSetWithIndex:idx]];
    return nil;
}

- (id)handleSaveScriptCommand:(NSScriptCommand *)cmd;
{
    return nil;
}


@end
