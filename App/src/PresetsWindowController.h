//
//  PresetsController.h
//  MetaZ
//
//  Created by Brian Olsen on 26/10/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresetSegmentedControl.h"

@interface PresetsWindowController : NSWindowController
{
    NSArrayController* filesController;
    NSArrayController* presetsController;
    NSTableView* presetsView;
    PresetSegmentedControl* segmentedControl;
    NSUndoManager* undoManager;
    NSMutableSet* undoHelpers;
}
- (id)initWithController:(NSArrayController*)controller;

@property (nonatomic, strong) IBOutlet NSArrayController* filesController;
@property (nonatomic, strong) IBOutlet NSArrayController* presetsController;
@property (nonatomic, strong) IBOutlet NSTableView* presetsView;
@property (nonatomic, strong) IBOutlet NSSegmentedControl* segmentedControl;
@property (readonly) NSUndoManager* undoManager;

- (void)checkSegmentEnabled;

#pragma mark - actions
- (IBAction)segmentClicked:(id)sender;
- (IBAction)applyPreset:(id)sender;
- (IBAction)addPreset:(id)sender;
- (IBAction)removePreset:(id)sender;

#pragma mark - as window delegate
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;

@end
