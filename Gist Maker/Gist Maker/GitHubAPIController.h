//
//  GitHubAPIController.h
//  Gist Maker
//
//  Created by Randy on 10/31/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const GitHubAuthenticationStatusDidChangeNotification = @"GitHubAuthenticationStatusDidChangeNotification";

typedef enum GitHubAuthenticationStatus {
    GitHubAuthenticationStatusFailed = -1,
    GitHubAuthenticationStatusVoid = 0,
    GitHubAuthenticationStatusAuthenticated = 1,
    GitHubAuthenticationStatusAuthenticating = 2,
    GitHubAuthenticationStatusError = 3
} GitHubAuthenticationStatus;
    

@interface GitHubAPIController : NSObject

+ (id)sharedController;

@property GitHubAuthenticationStatus authenticationStatus;

- (void)authenticatWithUsername:(NSString *)aUsername password:(NSString *)aPassword;

- (NSDictionary *)currentUser;

- (void)postGist:(NSString *)aSting;
- (void)postGist:(NSString *)aString failHandler:(void (^)(NSString *failedGistString))aFailBlock;

- (void)logout;

@property (nonatomic, strong) NSImage* avatar;
@property (nonatomic, strong) NSURL* avatarURL;

@end
