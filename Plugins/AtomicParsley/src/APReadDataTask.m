//
//  APReadDataTask.m
//  MetaZ
//
//  Created by Brian Olsen on 19/01/10.
//  Copyright 2010 Maven-Group. All rights reserved.
//

#import "APReadDataTask.h"


@implementation APReadDataTask

+ (id)taskWithProvider:(AtomicParsleyPlugin *)provider fromFileName:(NSString *)fileName dictionary:(NSMutableDictionary *)tagdict
{
    return [[[self class] alloc] initWithProvider:provider fromFileName:fileName dictionary:tagdict];
}

- (id)initWithProvider:(AtomicParsleyPlugin *)theProvider fromFileName:(NSString *)theFileName dictionary:(NSMutableDictionary *)theTagdict
{
    self = [super init];
    if(self)
    {
        self.file = [NSURL fileURLWithPath:theFileName];
        provider = theProvider;
        fileName = theFileName;
        tagdict = theTagdict;
    }
    return self;
}


- (void)parseData
{
    [provider parseData:self.data withFileName:fileName dict:tagdict];
}

@end


@implementation APPictureReadDataTask

+ (id)taskWithDictionary:(NSMutableDictionary *)tagdict
{
    return [[[self class] alloc] initWithDictionary:tagdict];
}

- (id)initWithDictionary:(NSMutableDictionary *)theTagdict
{
    self = [super init];
    if(self)
    {
        tagdict = theTagdict;
        file = [NSString temporaryPathWithFormat:@"MetaZImage_%@"];
    }
    return self;
}



@synthesize file;

- (void)startOnMainThread
{
    if([tagdict objectForKey:MZPictureTagIdent])
        [super startOnMainThread];
    else
    {
        self.executing = NO;
        self.finished = YES;
    }
}

- (void)taskTerminatedWithStatus:(int)status
{
    if(status != 0 || [self isCancelled])
    {
        [self setErrorFromStatus:status];
        self.executing = NO;
        self.finished = YES;
        return;
    }

    NSString* artfile = [file stringByAppendingString:@"_artwork_1"];
        
    NSFileManager* mgr = [NSFileManager manager];
    BOOL isDir;
    if([mgr fileExistsAtPath:[artfile stringByAppendingString:@".png"] isDirectory:&isDir] && !isDir)
    {
        NSData* data = [NSData dataWithContentsOfFile:[artfile stringByAppendingString:@".png"]];
        [tagdict setObject:data forKey:MZPictureTagIdent];
        [mgr removeItemAtPath:[artfile stringByAppendingString:@".png"] error:NULL];
    }
    else if([mgr fileExistsAtPath:[artfile stringByAppendingString:@".jpg"] isDirectory:&isDir] && !isDir)
    {
        NSData* data = [NSData dataWithContentsOfFile:[artfile stringByAppendingString:@".jpg"]];
        [tagdict setObject:data forKey:MZPictureTagIdent];
        [mgr removeItemAtPath:[artfile stringByAppendingString:@".jpg"] error:NULL];
    }
    

    self.executing = NO;
    self.finished = YES;
}

@end


@implementation APChapterReadDataTask

+ (id)taskWithFileName:(NSString*)fileName dictionary:(NSMutableDictionary *)tagdict;
{
    return [[[self class] alloc] initWithFileName:fileName dictionary:tagdict];
}

- (id)initWithFileName:(NSString*)fileName dictionary:(NSMutableDictionary *)theTagdict;
{
    self = [super init];
    if(self)
    {
        self.file = [NSURL fileURLWithPath:fileName];
        [self setArguments:[NSArray arrayWithObjects:@"-l", fileName, nil]];
        tagdict = theTagdict;
    }
    return self;
}


- (void)parseData
{
    if(!tagdict)
        return;
        
    NSString* str = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    
    NSRange f = [str rangeOfString:@"Duration "];
    NSString* movieDurationStr = [str substringWithRange:NSMakeRange(f.location+f.length, 12)];
    MZTimeCode* movieDuration = [MZTimeCode timeCodeWithString:movieDurationStr];
    [tagdict setObject:movieDuration forKey:MZDurationTagIdent];
    
    NSArray* lines = [str componentsSeparatedByString:@"\tChapter #"];
    if([lines count]>1)
    {
        NSMutableArray* chapters = [NSMutableArray array];
        NSUInteger len = [lines count];
        for(NSUInteger i=1; i<len; i++)
        {
            NSString* line = [[lines objectAtIndex:i]
                              stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSString* startStr = [line substringWithRange:NSMakeRange(6, 12)];
            NSString* durationStr = [line substringWithRange:NSMakeRange(21, 12)];
            NSString* name = [line substringWithRange:NSMakeRange(37, [line length]-38)];
            
            MZTimeCode* start = [MZTimeCode timeCodeWithString:startStr];
            MZTimeCode* duration = [MZTimeCode timeCodeWithString:durationStr];
            
            if(!start || !duration)
                break;
            
            MZTimedTextItem* item = [MZTimedTextItem textItemWithStart:start duration:duration text:name];
            [chapters addObject:item];
        }
        if([chapters count] == len-1)
            [tagdict setObject:chapters forKey:MZChaptersTagIdent];
    }
}

@end
