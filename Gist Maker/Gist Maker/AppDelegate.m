//
//  AppDelegate.m
//  Gist Maker
//
//  Created by Randy on 10/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "AppDelegate.h"
#import "GitHubAPIController.h"
#import "LoginWindowController.h"
#import "MASShortcut.h"
#import "MASShortcut+Monitoring.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcutView+UserDefaults.h"
#import "NewGistWindowController.h"

@interface AppDelegate ()
{
    LoginWindowController *loginController;
    //NSAppleScript *selectedTextScript;
}

//- (void)_postSelectedText:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // get the login ball rollin'
    [GitHubAPIController sharedController];
    
	[MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceGlobalShortcut handler:^{
		//[self _postSelectedText:nil];
        [self createNewGist:nil];
	}];
}

- (IBAction)createNewGist:(id)sender
{
    NewGistWindowController *newGistWindow = [[NewGistWindowController alloc] initWithWindowNibName:@"NewGistWindow"];
    [newGistWindow showWindow:nil];
    [[newGistWindow window] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showPrefWindow:(id)sender
{
    if (!loginController)
        loginController = [[LoginWindowController alloc] initWithWindowNibName:@"LoginWindow"];

    [[loginController window] orderFront:self];
}

/*// FIX ME PLEASE: I wish this would work... but it don't. :(
- (void)_postSelectedText:(id)sender
{
    NSDictionary *error = nil;
    
    if (!selectedTextScript)
    {
        selectedTextScript = [[NSAppleScript alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"GetSelectedText" withExtension:@"scpt"] error:&error];
        
        if (error != nil)
        {
            NSLog(@"error: %@", error);
            return;
        }
    }
    
    NSAppleEventDescriptor *returnValue = [selectedTextScript executeAndReturnError:&error];
    if (error != nil)
    {
        NSLog(@"execution error: %@", error);
        return;
    }
    
    NSLog(@"Current text: %@", [returnValue stringValue]);
}*/

@end
