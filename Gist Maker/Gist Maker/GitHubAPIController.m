//
//  GitHubAPIController.m
//  Gist Maker
//
//  Created by Randy on 10/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import "GitHubAPIController.h"
#import "SSKeychain.h"
#import "Base64.h"

static GitHubAPIController *sharedGitHubAPIController;
static NSString *const kGitHubGistMakerService = @"com.rclconcepts.gistmaker";


// FIX ME: perhaps this should be rewritten to use NSURLConnection's delegate
// API instead of the blocks? There is weird issues with authentication with
// the block API... in that it's basically broken. :)

@interface GitHubAPIController ()

- (void)_authenticate;

@end

@implementation GitHubAPIController

+ (id)sharedController
{
    if (!sharedGitHubAPIController)
        sharedGitHubAPIController = [[self alloc] init];
    
    return sharedGitHubAPIController;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self setAuthenticationStatus:GitHubAuthenticationStatusVoid];
        [self _authenticate];
    }
    
    return self;
}

@synthesize authenticationStatus;

- (void)_authenticate
{
    // Pull from keychain
    NSArray *accounts = [SSKeychain accountsForService:kGitHubGistMakerService];
    
    if ([accounts count] < 1)
        return;
    
    NSDictionary *account = [accounts objectAtIndex:0];

    NSString *username = [account objectForKey:kSSKeychainAccountKey];
    NSString *password = [SSKeychain passwordForService:kGitHubGistMakerService account:username];

    [self authenticatWithUsername:username password:password];
}

- (void)authenticatWithUsername:(NSString *)aUsername password:(NSString *)aPassword
{
    [self setAuthenticationStatus:GitHubAuthenticationStatusAuthenticating];

    NSString *path = [NSString stringWithFormat:@"https://api.github.com/user"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];

    NSString *loginString = [NSString stringWithFormat:@"%@:%@", aUsername, aPassword];
    NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [Base64 encodeString:loginString]];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *aResponse, NSData *data, NSError *anError) {

        if (anError != nil)
        {
            NSLog(@"%@", anError);
            NSLog(@"HTTP Response: %ld", [(NSHTTPURLResponse *)aResponse statusCode]);
            // do something for this.
            [self setAuthenticationStatus:GitHubAuthenticationStatusError];
            return;
        }

        NSError *parseError = nil;

        id responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        NSRange validrange = NSMakeRange(200, 99);
        
        if (parseError != nil || ![responseDict isKindOfClass:[NSDictionary class]] || !NSLocationInRange([(NSHTTPURLResponse *)aResponse statusCode], validrange))
        {
            [self setAuthenticationStatus:GitHubAuthenticationStatusError];
            // do something for this.
            return;
        }



        if ([[responseDict objectForKey:@"message"] isEqualToString:@"Bad credentials"])
            [self setAuthenticationStatus:GitHubAuthenticationStatusFailed];
        else
        {
            [self setAuthenticationStatus:GitHubAuthenticationStatusAuthenticated];
            
            //save username and password to keychain yo!
            [SSKeychain setPassword:aPassword forService:kGitHubGistMakerService account:aUsername];
        }
     
    }];
}

- (NSDictionary *)currentUser
{
    static NSString *gistsShouldBePublicKey = @"gistsShouldBePublicKey";

    NSArray *accounts = [SSKeychain accountsForService:kGitHubGistMakerService];
    
    if ([accounts count] < 1)
        return nil;

    NSDictionary *account = [accounts objectAtIndex:0];
    NSString *user = [account objectForKey:kSSKeychainAccountKey];
    NSString *pass = [SSKeychain passwordForService:kGitHubGistMakerService account:user];
    
    BOOL shouldBePublic = [[NSUserDefaults standardUserDefaults] boolForKey:gistsShouldBePublicKey];

    return @{@"username": user,
             @"password": pass,
             @"gistsShouldBePublic": [NSNumber numberWithBool:shouldBePublic]
            };
}

- (void)postGist:(NSString *)aString
{
    [self postGist:aString failHandler:nil];
}

- (void)postGist:(NSString *)aString failHandler:(void (^)(NSString *failedGistString))aFailBlock
{
    GitHubAuthenticationStatus status = [self authenticationStatus];
    
    /*if (status == GitHubAuthenticationStatusAuthenticating)
    {
        queue up the astring and fail handler... 
    }*/
    if (status != GitHubAuthenticationStatusAuthenticated)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"You are not authenticated with GitHub!" defaultButton:@"Show me!" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.github.com/gists"]];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *user = [self currentUser];
    
    NSString *loginString = [NSString stringWithFormat:@"%@:%@", [user objectForKey:@"username"], [user objectForKey:@"password"]];
    NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [Base64 encodeString:loginString]];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    id shouldBePublic = [user objectForKey:@"gistsShouldBePublic"];
    
    if (shouldBePublic == nil)
        shouldBePublic = [NSNumber numberWithBool:NO];

    NSDictionary *files = @{
        @"GistMaker": @{
        @"content":aString
        }
    };
    
    NSDictionary *requestDict = @{
        @"public": shouldBePublic,
        @"files": files
    };
    
    NSError *encodeError = nil;
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&encodeError];
    
    if (encodeError)
        ; //cry
    
    [request setHTTPBody:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *aResponse, NSData *data, NSError *anError) {
        
        NSError *decodeError = nil;
        
        id responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeError];
        
        NSRange validrange = NSMakeRange(200, 99);
        
        if (NSLocationInRange([(NSHTTPURLResponse *)aResponse statusCode], validrange))
        {
            //take the response yo, and copy the new URL to the clipboard,
            [[NSPasteboard generalPasteboard] clearContents];
            [[NSPasteboard generalPasteboard] writeObjects:[NSArray arrayWithObject:[responseDict objectForKey:@"html_url"]]];
            // make some beepy noise or something
            [[NSSound soundNamed:@"Glass"] play];
        }
        else
        {
            [[NSSound soundNamed:@"Funk"] play];

            if (aFailBlock != nil)
                aFailBlock(aString);
        }
    }];
}

- (void)logout
{
    NSArray *accounts = [SSKeychain accountsForService:kGitHubGistMakerService];
    
    if ([accounts count] < 1)
        return;

    NSString *user = [[accounts objectAtIndex:0] objectForKey:kSSKeychainAccountKey];
    [SSKeychain deletePasswordForService:kGitHubGistMakerService account:user];
    [self setAuthenticationStatus:GitHubAuthenticationStatusVoid];
}

@end
