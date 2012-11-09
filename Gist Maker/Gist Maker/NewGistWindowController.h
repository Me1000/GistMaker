//
//  NewGistWindowController.h
//  Gist Maker
//
//  Created by Randy on 11/7/12.
//  Copyright (c) 2012 RCLConcepts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NewGistWindowController : NSWindowController<NSWindowDelegate>
{
    IBOutlet NSTextField *textField;
}

- (void)setText:(NSString *)text;
- (IBAction)submitGist:(id)sender;

@end
