//
//  LoginWindowController.m
//  Gist Maker
//
//  Created by Randy on 10/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "LoginWindowController.h"
#import "GitHubAPIController.h"
#import "MASShortcutView+UserDefaults.h"

@interface LoginWindowController ()

- (BOOL)isAuthenticated;
- (void)login;

- (void)updatedAuthenticationStatusField;

@end

@implementation LoginWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        [[GitHubAPIController sharedController] addObserver:self forKeyPath:@"authenticationStatus" options:0 context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [[GitHubAPIController sharedController] removeObserver:self forKeyPath:@"authenticationStatus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    static NSString *authenticationStatusPath = @"authenticationStatus";

    if ([keyPath isEqualToString:authenticationStatusPath])
        [self updatedAuthenticationStatusField];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setDelegate:self];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    GitHubAPIController *apiController = [GitHubAPIController sharedController];
    NSDictionary *user = [apiController currentUser];
    
    [self.usernameField setStringValue:[user objectForKey:@"username"]];
    [self.passwordField setStringValue:[user objectForKey:@"password"]];
    BOOL state = [[user objectForKey:@"gistsShouldBePublic"] boolValue];
    [self.privateCheckbox setState:state == YES ? NSOffState : NSOnState];
    
    [self.shortcutView setAssociatedUserDefaultsKey:kPreferenceGlobalShortcut];
}

- (void)login
{
    NSString *username = [self.usernameField stringValue];
    NSString *password = [self.passwordField stringValue];
    
    [[GitHubAPIController sharedController] authenticatWithUsername:username password:password];
}

- (void)updatedAuthenticationStatusField
{
    GitHubAuthenticationStatus status = [[GitHubAPIController sharedController] authenticationStatus];

    [self.authenticationStatusField setHidden:NO];

    if (status == GitHubAuthenticationStatusError)
    {
        [self.authenticationStatusField setStringValue:@"There was an error. :("];
        [self.authenticationStatusField setTextColor:[NSColor redColor]];
        [self.loginSpinner setHidden:YES];
        [self.loginSpinner stopAnimation:self];
    }
    else if (status == GitHubAuthenticationStatusFailed)
    {
        [self.authenticationStatusField setStringValue:@"Authentication failed"];
        [self.authenticationStatusField setTextColor:[NSColor redColor]];
        [self.loginSpinner setHidden:YES];
        [self.loginSpinner stopAnimation:self];
    }
    else if (status == GitHubAuthenticationStatusAuthenticated)
    {
        [self.authenticationStatusField setStringValue:@"Logged in!"];
        [self.authenticationStatusField setTextColor:[NSColor greenColor]];
        [self.loginSpinner setHidden:YES];
        [self.loginSpinner stopAnimation:self];
    }
    else if (status == GitHubAuthenticationStatusAuthenticating)
    {
        [self.authenticationStatusField setStringValue:@""];
        [self.loginSpinner setHidden:NO];
        [self.loginSpinner startAnimation:self];
    }
    else if(status == GitHubAuthenticationStatusVoid)
    {
        [self.authenticationStatusField setStringValue:@""];
        [self.loginSpinner setHidden:YES];
        [self.loginSpinner stopAnimation:self];
    }
}

- (IBAction)checkBoxValueChanged:(id)sender
{
    BOOL shouldBePublic = [self.privateCheckbox state] == NSOffState;
    [[NSUserDefaults standardUserDefaults] setBool:shouldBePublic forKey:@"gistsShouldBePublicKey"];
}

- (IBAction)logout:(id)sender
{
    [[GitHubAPIController sharedController] logout];
}

#pragma mark Window delegate
- (IBAction)windowDidBecomeMain:(NSNotification *)notification
{
    [self updatedAuthenticationStatusField];
}

#pragma mark Textfield delegate and actions

- (void)controlTextDidChange:(NSNotification *)obj
{
    //NSLog(@"Text changed");
}

- (void)enterKeyActionTextFields:(id)sender
{
    [self controlTextDidEndEditing:nil];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[self.usernameField stringValue] length] > 0 && [[self.passwordField stringValue] length] > 0)
        [self login];
}

@end

