//
//  AppController.h
//  MetaZ
//
//  Created by Brian Olsen on 06/09/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import "MZMetaLoader.h"
#import "FilesUndoController.h"
#import "ResizeController.h"
#import "ImageWindowController.h"
#import "PreferencesWindowController.h"
#import "PresetsWindowController.h"
#import "ChapterEditor.h"
#import "MZFileNameTextStorage.h"
#import "MZYearDateFormatter.h"
#import "FilesArrayController.h"

@interface AppController : NSObject <NSUserInterfaceValidations> {
    NSWindow* window;
    NSTabView *tabView;
    NSNumberFormatter* episodeFormatter;
    NSNumberFormatter* seasonFormatter;
    MZYearDateFormatter* dateFormatter;
    NSDateFormatter* purchaseDateFormatter;
    NSSegmentedControl* filesSegmentControl;
    FilesArrayController* filesController;
    ResizeController* resizeController;
    FilesUndoController* undoController;
    NSTextView* shortDescription;
    NSTextView* longDescription;
    NSUndoManager* undoManager;
    NSImageView* imageView;
    ImageWindowController* imageEditController;
    PreferencesWindowController* prefController;
    PresetsWindowController* presetsController;
    NSProgressIndicator* searchIndicator;
    NSArrayController* searchController;
    NSSearchField* searchField;
    NSInteger remainingInShortDescription;
    NSTextField *tvShow;
    NSTextField *tvSeason;
    ChapterEditor* chapterEditor;
    NSProgressIndicator* loadingIndicator;
    NSInteger loadings;
    NSArrayController* picturesController;
    SUUpdater* updater;
    BOOL usingiTunesTVStandard_;
    
    MZFileNameTextStorage* fileNameStorage;
    NSTextView* fileNameEditor;
}
@property (nonatomic, strong) IBOutlet NSWindow* window;
@property (nonatomic, strong) IBOutlet NSTabView *tabView;
@property (nonatomic, strong) IBOutlet NSNumberFormatter* episodeFormatter;
@property (nonatomic, strong) IBOutlet NSNumberFormatter* seasonFormatter;
@property (nonatomic, strong) IBOutlet MZYearDateFormatter* dateFormatter;
@property (nonatomic, strong) IBOutlet NSDateFormatter* purchaseDateFormatter;
@property (nonatomic, strong) IBOutlet NSSegmentedControl* filesSegmentControl;
@property (nonatomic, strong) IBOutlet FilesArrayController* filesController;
@property (nonatomic, strong) IBOutlet ResizeController* resizeController;
@property (nonatomic, strong) IBOutlet FilesUndoController* undoController;
@property (nonatomic, strong) IBOutlet NSTextView* shortDescription;
@property (nonatomic, strong) IBOutlet NSTextView* longDescription;
@property (nonatomic, strong) IBOutlet NSImageView* imageView;
@property (nonatomic, strong) IBOutlet ChapterEditor* chapterEditor;
@property (nonatomic, strong) IBOutlet NSProgressIndicator* loadingIndicator;
@property (nonatomic, strong) IBOutlet NSArrayController* picturesController;
@property (nonatomic, strong) IBOutlet SUUpdater* updater;
@property (readonly) NSInteger remainingInShortDescription;
@property (nonatomic, strong) IBOutlet NSTextField *tvShow;
@property (nonatomic, strong) IBOutlet NSTextField *tvSeason;
@property (readonly) BOOL usingiTunesTVStandard;

+ (void)initialize;

#pragma mark - actions

- (IBAction)showAdvancedTab:(id)sender;
- (IBAction)showChapterTab:(id)sender;
- (IBAction)showInfoTab:(id)sender;
- (IBAction)showSortTab:(id)sender;
- (IBAction)showVideoTab:(id)sender;
- (IBAction)segmentClicked:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)revertChanges:(id)sender;
- (IBAction)showImageEditor:(id)sender;
- (IBAction)searchForImages:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)showPresets:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)showHomepage:(id)sender;
- (IBAction)showIssues:(id)sender;
- (IBAction)reportIssue:(id)sender;
- (IBAction)viewLog:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)tvShowChanged:(NSTextField *)sender;
- (IBAction)tvSeasonChanged:(NSTextField *)sender;

//- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;

#pragma mark - as window delegate
- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;

#pragma mark - as application delegate

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

@end
