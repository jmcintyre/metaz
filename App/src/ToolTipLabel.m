//
//  ToolTipLabel.m
//  MetaZ
//
//  Created by Brian Olsen on 16/11/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import "ToolTipLabel.h"


@implementation ToolTipLabel

- (void)mouseEntered:(NSEvent *)theEvent
{
    MZLoggerDebug(@"Mouse entered label");
}


- (void)showToolTip:(NSString *)toolTip
{
    if(!showsToolTip)
        text = [self stringValue];
    showsToolTip = YES;
    [super setStringValue:toolTip];
}

- (void)clearToolTip
{
    if(text)
        [super setStringValue:text];
    showsToolTip = NO;
}

- (void)setObjectValue:(id)value
{
    [self setStringValue:value];
}

- (void)setStringValue:(NSString *)aString
{
    if(showsToolTip)
    {
        text = aString;
    }
    else
        [super setStringValue:aString];
}

@end
