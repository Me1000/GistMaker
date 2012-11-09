//
//  LoginWindowController.h
//  Gist Maker
//
//  Created by Randy on 10/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSString *const kPreferenceGlobalShortcut = @"GistMakerGlobalShortcut";

@class MASShortcutView;

@interface LoginWindowController : NSWindowController<NSWindowDelegate, NSTextFieldDelegate>

@property(weak) IBOutlet NSTextField *usernameField;
@property(weak) IBOutlet NSTextField *passwordField;
@property(weak) IBOutlet NSButton *privateCheckbox;
@property(weak) IBOutlet NSTextField *authenticationStatusField;
@property(weak) IBOutlet NSProgressIndicator *loginSpinner;
@property(weak) IBOutlet MASShortcutView *shortcutView;

- (IBAction)enterKeyActionTextFields:(id)sender;
- (IBAction)checkBoxValueChanged:(id)sender;
- (IBAction)logout:(id)sender;

@end
