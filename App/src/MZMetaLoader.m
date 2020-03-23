//
//  MetaLoader.m
//  MetaZ
//
//  Created by Brian Olsen on 25/08/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import "MZMetaLoader.h"
#import <MetaZKit/MetaZKit.h>
#import "MZWriteQueue.h"
#import "MZWriteQueueStatus.h"
#import "NSUserDefaults+KeyPath.h"
#import "MZMetaDataDocument.h"


@interface MZLoadOperationDelegate : NSObject <MZEditsReadDelegate>
{
    MZLoadOperation* owner;
}
- (id)initWithOwner:(MZLoadOperation*)owner;

@end


@interface MZMetaLoader ()

- (void)loadedFile:(MZLoadOperation *)operation;
- (void)notifyLoadedFile:(MZLoadOperation *)operation;

@end


@implementation MZMetaLoader
@synthesize files;

#pragma mark - initialization 

static MZMetaLoader* sharedLoader = nil;

+(MZMetaLoader *)sharedLoader
{
    if(!sharedLoader)
        [[MZMetaLoader alloc] init];
    return sharedLoader;
}

-(id)init
{
    self = [super init];

    if(sharedLoader)
    {
        self = sharedLoader;
    } else if(self)
    {
        files = [[NSMutableArray alloc] init];
        loading = [[NSMutableArray alloc] init];
        sharedLoader = self;
    }
    return self;
}

-(NSArray *)types
{
    return [[MZPluginController sharedInstance] dataProviderTypes];
}

-(void)removeAllObjects
{
    [self willChangeValueForKey:@"files"];
    [files removeAllObjects];
    [self didChangeValueForKey:@"files"];
}

- (void)removeFilesAtIndexes:(NSIndexSet *)indexes
{
    [self willChangeValueForKey:@"files"];
    [files removeObjectsAtIndexes:indexes];
    [self didChangeValueForKey:@"files"];
}

- (void)removeObjectFromFilesAtIndex:(NSUInteger)idx
{
    [self willChangeValueForKey:@"files"];
    [files removeObjectAtIndex:idx];
    [self didChangeValueForKey:@"files"];
}

- (void)insertObject:(id)object inFilesAtIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"files"];
    [files insertObject:object atIndex:index];
    [self didChangeValueForKey:@"files"];
}

-(BOOL)loadFromFile:(NSString *)fileName
{
    return [self loadFromFile:fileName toIndex:[files count]];
}

-(BOOL)loadFromFiles:(NSArray *)fileNames
{
    return [self loadFromFiles:fileNames toIndex:[files count]];
}

- (BOOL)loadFromFile:(NSString *)fileName toIndex:(NSUInteger)index
{
    NSAssert(fileName, @"Provided fileName");
    return [self loadFromFiles:[NSArray arrayWithObject:fileName] toIndex:index];
}

- (BOOL)loadFromFiles:(NSArray *)fileNames toIndex:(NSUInteger)index
{
    NSAssert(fileNames, @"Provided filenames");
    if([fileNames count]==0)
        return YES;
    return [self loadFromFiles:fileNames
                     toIndexes:[NSIndexSet indexSetWithIndexesInRange:
                    NSMakeRange(index, [fileNames count])]];
}

- (BOOL)loadFromFiles:(NSArray *)fileNames toIndexes:(NSIndexSet*)indexes
{
    return [self loadFromFiles:fileNames toIndexes:indexes withMetaData:nil];
}


- (BOOL)loadFromFile:(NSString *)fileName withMetaData:(NSDictionary *)metaData;
{
    return [self loadFromFile:fileName toIndex:[files count] withMetaData:metaData];
}

- (BOOL)loadFromFiles:(NSArray *)fileNames withMetaData:(NSArray *)metaData;
{
    return [self loadFromFiles:fileNames toIndex:[files count] withMetaData:metaData];
}

- (BOOL)loadFromFile:(NSString *)fileName toIndex:(NSUInteger)index withMetaData:(NSDictionary *)metaData;
{
    NSAssert(fileName, @"Provided fileName");
    return [self loadFromFiles:[NSArray arrayWithObject:fileName]
                       toIndex:index
                  withMetaData:(metaData ? [NSArray arrayWithObject:metaData] : nil)];
}

- (BOOL)loadFromFiles:(NSArray *)fileNames toIndex:(NSUInteger)index withMetaData:(NSArray *)metaData;
{
    NSAssert(fileNames, @"Provided filenames");
    if([fileNames count]==0)
        return YES;
    return [self loadFromFiles:fileNames
                     toIndexes:[NSIndexSet indexSetWithIndexesInRange:
                                NSMakeRange(index, [fileNames count])]
                  withMetaData:metaData];
}

- (BOOL)loadFromFiles:(NSArray *)fileNames toIndexes:(NSIndexSet*)indexes withMetaData:(NSArray *)metaData
{
    NSAssert(fileNames, @"Provided filenames");
    if([fileNames count]==0)
        return YES;
    NSAssert([fileNames count]==[indexes count], @"Count of indexes and filenames");
    if(metaData)
        NSAssert([fileNames count]==[metaData count], @"Count of metaData and filenames");
    
    BOOL suppressAlreadyLoadedWarning = [[NSUserDefaults standardUserDefaults]
        boolForKeyPath:MZDataProviderFileAlreadyLoadedWarningKey];
    NSMutableArray* realFileNames = [NSMutableArray arrayWithArray:fileNames];
    NSMutableIndexSet* realIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:indexes];
        
    NSArray* loadedFileNames = [files arrayByPerformingKeyPath:@"loadedFileName"];
    NSMutableArray* queuedFileNames = [NSMutableArray array];
    for(MZWriteQueueStatus* status in [[MZWriteQueue sharedQueue] queueItems])
    {
        if(![status completed])
            [queuedFileNames addObject:[[status edits] loadedFileName]];
    }
    NSInteger index = [indexes lastIndex];
    for(NSInteger i=[fileNames count]-1; i>=0; i--)
    {
        NSString* fileName = [fileNames objectAtIndex:i];
        NSInteger idx = [loadedFileNames indexOfObject:fileName];
        BOOL inQueue = NO;
        BOOL inLoading = NO;
        if(idx == NSNotFound)
        {
            idx = [queuedFileNames indexOfObject:fileName];
            inQueue = idx != NSNotFound;
        }

        if(idx == NSNotFound)
        {
            NSInteger i = 0;
            for(MZLoadOperation* op in loading)
            {
                if([op.filePath isEqual:fileName])
                {
                    idx = i;
                    inLoading = YES;
                    break;
                }
                i++;
            }
        }
            
        if(idx != NSNotFound)
        {
            NSString* basefile = [fileName lastPathComponent];
            if(!suppressAlreadyLoadedWarning)
            {
                NSAlert* alert = [[NSAlert alloc] init];
                if(inQueue)
                {
                    [alert setMessageText:
                        [NSString stringWithFormat:
                            NSLocalizedString(@"File \"%@\" is already in queue", @"Already loaded warning message"),
                                basefile]];
                }
                else if(inLoading)
                {
                    [alert setMessageText:
                        [NSString stringWithFormat:
                            NSLocalizedString(@"File \"%@\" is already being loaded", @"Already loaded warning message"),
                                basefile]];
                }
                else
                {
                    [alert setMessageText:
                        [NSString stringWithFormat:
                            NSLocalizedString(@"File \"%@\" is already loaded", @"Already loaded warning message"),
                                basefile]];
                }
                [alert setShowsSuppressionButton:YES];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button")];

                [alert runModal];
                suppressAlreadyLoadedWarning = [[alert suppressionButton] state] == NSOnState;
                [[NSUserDefaults standardUserDefaults]
                    setBool:suppressAlreadyLoadedWarning 
                    forKeyPath:MZDataProviderFileAlreadyLoadedWarningKey];
            }
            [realFileNames removeObjectAtIndex:i];
            [realIndexes removeIndex:index];
            if([realIndexes countOfIndexesInRange:NSMakeRange(index, [indexes lastIndex]+1)] > 0)
            {
                [realIndexes shiftIndexesStartingAtIndex:[indexes indexGreaterThanIndex:index] by:-1];
            }
        }
        index = [indexes indexLessThanIndex:index];
    }
    fileNames = realFileNames;
    indexes = realIndexes;

    if([loading count]==0)
    {
        defaultVideoType = [[NSUserDefaults standardUserDefaults] integerForKey:@"incomingVideoType"];
        lastSelection = MZUnsetVideoType;
    }

    index = [indexes firstIndex];
    NSEnumerator* md = nil;
    if(metaData)
        md = [metaData objectEnumerator];
    for ( NSString* fileName in fileNames )
    {
        NSDictionary* extra = nil;
        if(md)
            extra = [md nextObject];
        MZLoadOperation* operation = [MZLoadOperation loadWithFilePath:fileName atIndex:index extra:extra];
        NSScriptCommand* cmd = [NSScriptCommand currentCommand];
        if(cmd)
        {
            operation.scriptCommand = cmd;
            [cmd suspendExecution];
        }
        [loading addObject:operation];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:MZMetaLoaderStartedNotification
                          object:operation
                        userInfo:nil];
        index = [indexes indexGreaterThanIndex:index];
    }
    return YES;
}

- (void)loadedFile:(MZLoadOperation *)operation
{
    MZVideoType currentVideoType = defaultVideoType;
    if( operation.scriptCommand )
    {
        NSNumber* num = [[operation.scriptCommand evaluatedArguments] objectForKey:@"VideoType"];
        if(num && [num intValue] != MZUnsetVideoType ) {
            currentVideoType = [num intValue];
        }
    }
    
    MetaEdits* edits = operation.edits;
    if(!edits)
    {
        [loading removeObject:operation];
        NSString* baseFile = [operation.filePath lastPathComponent];
        NSString* errMsg = [NSString stringWithFormat:
            NSLocalizedString(@"The file '%@' is in an unsupported format.", @"Bad file title"), baseFile];
        
        NSAlert *alerts = [NSAlert alertWithError:operation.error];
        [alerts runModal];

        /*
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = errMsg;
        alert.informativeText = @"";
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button text")];
        [alert runModal];
         */
        
        /*NSRunCriticalAlertPanel(errMsg,
            @"", NSLocalizedString(@"OK", @"Button text"), nil, nil);*/
        MZLoggerError(@"Could no load file '%@'", operation.filePath);
        [self notifyLoadedFile:operation];
        if( operation.scriptCommand )
        {
            [operation.scriptCommand setScriptErrorNumber:kENOENTErr];
            [operation.scriptCommand setScriptErrorString:errMsg];
            [operation.scriptCommand resumeExecutionWithResult:nil];
        }
        return;
    }

    if([edits videoType] == MZUnsetVideoType)
    {
        if(currentVideoType<=MZUnsetVideoType)
        {
            NSAlert* alert = [[NSAlert alloc] init];
            [alert setMessageText:
                [NSString stringWithFormat:
                    NSLocalizedString(@"Video type for file \"%@\" could not be determined", @"Video type prompt"),
                    [edits fileName]]];
            NSPopUpButton* sel = [[NSPopUpButton alloc] 
                initWithFrame:NSMakeRect(0, 0, 145, 25)
                    pullsDown:NO];
            MZTag* tag = [MZTag tagForIdentifier:MZVideoTypeTagIdent];
            [sel setCell:[tag editorCell]];
            [sel setKeyEquivalent:@"t"];
            [sel setKeyEquivalentModifierMask:NSEventModifierFlagCommand];

            if(lastSelection!=MZUnsetVideoType)
                [sel selectItemWithTag:lastSelection];

            [alert setAccessoryView:sel];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button")];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button")];

            if([loading count]>1)
            {
                [alert setShowsSuppressionButton:YES];
                [[alert suppressionButton] setTitle:
                    NSLocalizedString(@"Apply to all", @"Confirmation text")];
            }
            
            NSInteger returnCode = [alert runModal];
            lastSelection = [[sel selectedItem] tag];
            BOOL applyAll = [loading count]>1 && [[alert suppressionButton] state] == NSOnState;

            if(returnCode != NSAlertFirstButtonReturn)
            {
                [loading removeObject:operation];
                [self notifyLoadedFile:operation];
                if( operation.scriptCommand )
                {
                    [operation.scriptCommand setScriptErrorNumber:userCanceledErr];
                    [operation.scriptCommand resumeExecutionWithResult:nil];
                }
                return;
            }
                
            [edits setVideoType:lastSelection];
            if(applyAll)
                defaultVideoType = lastSelection;
        }
        else
            [edits setVideoType:currentVideoType];
    }
    
    NSUInteger index = operation.index;
    if(index > [files count])
        index = [files count];

    [self willChangeValueForKey:@"files"];
    [files insertObject:edits atIndex:index];
    [self didChangeValueForKey:@"files"];
    [loading removeObject:operation];
    [self notifyLoadedFile:operation];
    if( operation.scriptCommand )
    {
        MZMetaDataDocument* doc = [MZMetaDataDocument documentWithEdit:edits];
        [operation.scriptCommand resumeExecutionWithResult:doc];
    }
}

- (void)notifyLoadedFile:(MZLoadOperation *)operation;
{
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    if(operation.edits)
        [info setObject:operation.edits forKey:MZMetaEditsNotificationKey];
    if(operation.error)
        [info setObject:operation.error forKey:MZNSErrorKey];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:MZMetaLoaderFinishedNotification
                      object:operation
                    userInfo:info];
}


- (void)moveObjects:(NSArray *)objects toIndex:(NSUInteger)index
{
    [self willChangeValueForKey:@"files"];
    NSMutableIndexSet* idx = [[NSMutableIndexSet alloc] init];
    for(MetaEdits* edit in objects)
    {
        for(int i=[files count]-1; i>=0; i--)
        {
            MetaEdits* ob = [files objectAtIndex:i];
            if(ob == edit)
                [idx addIndex:i];
        }
    }
    [files removeObjectsAtIndexes:idx];

    index -= [idx countOfIndexesInRange:NSMakeRange(0, index)];
    for(int i=[objects count]-1; i>=0; i--)
    {
        [files insertObject:[objects objectAtIndex:i] atIndex:index];
    }
    [self didChangeValueForKey:@"files"];
}

- (void)reloadEdits:(MetaEdits *)edits
{
    [self willChangeValueForKey:@"files"];
    [edits prepareFromQueue];
    [files addObject:edits];
    [self didChangeValueForKey:@"files"];
}

@end

@implementation MZLoadOperation

+ (id)loadWithFilePath:(NSString *)filePath atIndex:(NSUInteger )index extra:(NSDictionary *)extra
{
    return [[self alloc] initWithFilePath:filePath atIndex:index extra:extra];
}

- (id)initWithFilePath:(NSString *)theFilePath atIndex:(NSUInteger )theIndex extra:(NSDictionary *)extra
{
    self = [super init];
    if(self)
    {
        filePath = theFilePath;
        index = theIndex;
        delegate = [[MZLoadOperationDelegate alloc] initWithOwner:self];
        controller = [[MZPluginController sharedInstance] loadFromFile:filePath delegate:delegate extra:extra];
    }
    return self;
}

@synthesize edits;
@synthesize index;
@synthesize filePath;
@synthesize error;
@synthesize scriptCommand;

- (void)dataProvider:(MZDataProviderPlugin *)provider
          controller:(id<MZDataController>)controller
         loadedEdits:(MetaEdits *)theEdits
            fromFile:(NSString *)fileName
               error:(NSError *)theError
{
    edits = theEdits;
    error = theError;
    
    // loadedFile: runs a modeal alert so we use NSEventTrackingRunLoopMode
    // to avoid showing more than one alert at a time
    [[MZMetaLoader sharedLoader] performSelectorOnMainThread:@selector(loadedFile:) 
                withObject:self
                waitUntilDone:YES
                modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]]; 
}

@end

@implementation MZLoadOperationDelegate

- (id)initWithOwner:(MZLoadOperation*)theOwner
{
    self = [super init];
    if(self)
        owner = theOwner;
    return self;
}

- (void)dataProvider:(MZDataProviderPlugin *)provider
          controller:(id<MZDataController>)controller
         loadedEdits:(MetaEdits *)theEdits
            fromFile:(NSString *)fileName
               error:(NSError *)theError
{
    [owner dataProvider:provider controller:controller loadedEdits:theEdits fromFile:fileName error:theError];
}

@end

