//
//  NewGistWindowController.m
//  Gist Maker
//
//  Created by Randy on 11/7/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "NewGistWindowController.h"
#import "GitHubAPIController.h"

@interface NewGistWindowController ()
{
    NSString *gistText;
    NewGistWindowController *retainedSelf;
}
@end

@implementation NewGistWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSString *clipboardText = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];

    NSString *defaultText = @"";

    if (![gistText isEqualToString:@""] && gistText != nil)
        defaultText = gistText;
    else if (clipboardText != nil)
        defaultText = clipboardText;


    [textField setStringValue:defaultText];

    [[self window] makeFirstResponder:textField];

    // DON'T YELL AT ME JUST YET.
    // So, here's the problem... NewGistWindowControllers are always created in a local scope of a method
    // and NEVER do I _need_ to keep a reference to the window around. So it can just exist in the bottomless ... heap.
    // Since the Window controller has a strong reference to the window, and the window has a weak reference to the controller
    // the window imediately closes and deallocs when the controller's retain count hits 0, because the local varaiable
    // went out of scope. Keeping a strong reference to `self` means I keep a retain count of 1.
    // until the window is closed, then I remove the reference, and allow the controller to deallocate.
    retainedSelf = self;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.window setDelegate:nil];
    retainedSelf = nil;
}

- (void)setText:(NSString *)text
{
    // textfield may be nil...
    [textField setStringValue:text];

    gistText = [text copy];
}

- (IBAction)submitGist:(id)sender
{
    [[GitHubAPIController sharedController] postGist:[textField stringValue] failHandler:^(NSString *failedString){
        // this stuff was never actually tested... whoops. :)
        NewGistWindowController *newWindowController = [[NewGistWindowController alloc] initWithWindowNibName:@"NewGistWindowController"];
        [newWindowController setText:failedString];
        [[newWindowController window] makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }];

    [self close];
}

@end
