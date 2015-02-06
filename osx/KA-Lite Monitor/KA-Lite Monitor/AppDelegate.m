//
//  AppDelegate.m
//  KA-Lite Monitor
//
//  Created by cyril on 1/20/15.
//  Copyright (c) 2015 FLE. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
//    @property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize fusername;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Setup the status menu item.
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setImage:[NSImage imageNamed:@"favicon"]];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setToolTip:@"Click to show the KA-Lite menu items."];

    // We need to show preferences if local_settings.py or database does not exist.
    bool mustShowPreferences = false;
    @try {
        NSString *localSettings = getLocalSettingsPath();
        if (localSettings == nil) {
            NSLog(@"local_settings.py not found, must show preferences...");
            mustShowPreferences = true;
        } else {
            NSLog(@"FOUND local_settings.py!");
        }
        
        NSString *database = getDatabasePath();
        if (database == nil) {
            NSLog(@"Database not found, must show preferences.");
            mustShowPreferences = true;
        } else {
            NSLog(@"FOUND database!");
        }
        
        NSLog(@"KA Lite was successfully started!");
    }
    @catch (NSException *ex) {
        NSLog(@"KA Lite had an Error: %@", ex);
    }
    
    void *sel = @selector(closeSplash);
    if (mustShowPreferences == true) {
        NSLog(@"==> must show preferences");
        sel = @selector(showPreferences);
    }
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:sel userInfo:nil repeats:NO];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    // TODO(cpauya): Confirm quit action from user.
    runKalite(@"stop");
    NSLog(@"==> quitting...");
}


/********************
  Useful Methods
********************/


int copyLocalSettings() {
    NSLog(@"==> Copying local_settings.default as local_settings.py...");
    NSString *source = [[NSBundle mainBundle] pathForResource:@"local_settings" ofType:@"default"];
    NSLog(@"==> localSettings: %@", source);
    
    NSString *target = getResourcePath(@"ka-lite/kalite/local_settings.py");
    NSString *command = [NSString stringWithFormat:@"cp \"%@\" \"%@\"", source, target];
    NSLog(@"==> Running command: %@", command);
    
    const char *cmd = [command UTF8String];
    int i = system(cmd);
    showNotification(@"Copied local_settings.default to local_settings.py.");
    return i;
}


NSString *getResourcePath(NSString *pathToAppend) {
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:pathToAppend];
    path = [path stringByStandardizingPath];
    return path;
}


NSString *getLocalSettingsPath() {
    NSString *localSettings = [[NSBundle mainBundle] pathForResource:@"ka-lite/kalite/local_settings" ofType:@"py"];
    return localSettings;
}


NSString *getDatabasePath() {
    NSString *database = [[NSBundle mainBundle] pathForResource:@"ka-lite/kalite/database/data" ofType:@"sqlite"];
    return database;
}


// REF: http://stackoverflow.com/a/10284037/845481
// convert const char* to NSString * and convert back - _NSAutoreleaseNoPool()
int runKalite(NSString *command) {
    // It needs the `KALITE_DIR` and `KALITE_PYTHON` environment variables, so we set them here for every call.
    // TODO(cpauya): We must prompt user on a preferences dialog and persist these perhaps on `local_settings.py`?
    NSString *kaliteDir;
    NSString *pyrun;
    NSString *kalitePath;
    NSString *finalCmd;
    
    @try {
        kaliteDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ka-lite"];
        kaliteDir = [kaliteDir stringByStandardizingPath];
        
        pyrun = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pyrun-2.7/bin/pyrun"];
        pyrun = [pyrun stringByStandardizingPath];
        
        kalitePath = [kaliteDir stringByAppendingString:@"/bin/kalite"];
        
        finalCmd = [NSString stringWithFormat: @"export KALITE_DIR=\"%@\"", kaliteDir];
        finalCmd = [NSString stringWithFormat: @"%@; export KALITE_PYTHON=\"%@\"", finalCmd, pyrun];
        finalCmd = [NSString stringWithFormat: @"%@; \"%@\" %@", finalCmd, kalitePath, command];
        
        // convert to objective-c string for use in `system` call
        const char *exportCommand = [finalCmd UTF8String];
        NSLog(@"==> Running exportCommand %s", exportCommand);
        int i = system(exportCommand);
        
        NSLog(@"==> return is %i... done.", i);
        return i;
    }
    @catch (NSException *ex) {
        NSLog(@"Error running `kalite` %@", ex);
    }
}


void alert(NSString *message) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}


void showNotification(NSString *subtitle) {
    // REF: http://stackoverflow.com/questions/12267357/nsusernotification-with-custom-soundname?rq=1
    // TODO(cpauya): These must be ticked by user on preferences if they want notifications, sounds, or not.
    NSUserNotification* notification = [[NSUserNotification alloc]init];
    notification.title = @"KA-Lite";
    notification.subtitle = subtitle;
    notification.soundName = @"Basso.aiff";
//    notification.informativeText = @"informative text here";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


NSString *getUsernameChars() {
    NSString *chars = @"@.+-_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSLog(@"chars %@", chars);
    return chars;
}


// REF: http://stackoverflow.com/a/26423271/845481
// Check IF one String contains the same characters as another string
- (BOOL)string:(NSString *)string containsAllCharactersInString:(NSString *)charString {
    NSUInteger stringLen = [string length];
    NSUInteger charStringLen = [charString length];
    for (NSUInteger i = 0; i < charStringLen; i++) {
        unichar c = [charString characterAtIndex:i];
        BOOL found = NO;
        for (NSUInteger j = 0; j < stringLen && !found; j++)
            found = [string characterAtIndex:j] == c;
        if (!found)
            return NO;
    }
    return YES;
}


/********************
 END Useful Methods
 ********************/


- (IBAction)start:(id)sender {
    showNotification(@"Starting...");
    int i = runKalite(@"start");
    if (i == 0) {
        [self.statusItem setImage:[NSImage imageNamed:@"stop"]];
        [self.statusItem setToolTip:@"KA-Lite is running."];
        showNotification(@"You can now click on 'Open in Browser' menu");
    } else {
        [self.statusItem setImage:[NSImage imageNamed:@"exclaim"]];
        [self.statusItem setToolTip:@"KA-Lite has encountered an error, pls check the Console."];
        showNotification(@"Has encountered an error, pls check the Console.");
    }
}


- (IBAction)stop:(id)sender {
    NSLog(@"==> Stopping...");
    showNotification(@"Stopping...");
    int i = runKalite(@"stop");
    if (i == 0) {
        [self.statusItem setImage:[NSImage imageNamed:@"favicon"]];
        [self.statusItem setToolTip:@"KA-Lite is not running."];
        showNotification(@"Stopped");
    } else {
        [self.statusItem setImage:[NSImage imageNamed:@"exclaim"]];
        [self.statusItem setToolTip:@"KA-Lite has encountered an error, pls check the Console."];
        showNotification(@"Has encountered an error, pls check the Console.");
    }
}


- (IBAction)open:(id)sender {
    NSLog(@"==> Opening KA-Lite in browser...");
    // TODO(cpauya): Get the ip address and port from `local_settings.py` or preferences.
    // REF: http://stackoverflow.com/a/7129543/845481
    // Open URL with Safari no matter what system browser is set to
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:8008/"];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] ) {
        NSLog(@"==> Failed to open url: %@",[url description]);
        showNotification([NSString stringWithFormat:@" Failed to open url: %@",[url description]]);
    }
}


- (IBAction)closeSplash:(id)sender {
    [self closeSplash];
}


- (IBAction)showPreferences:(id)sender {
    [self showPreferences];
}


- (IBAction)hidePreferences:(id)sender {
    NSLog(@"==> hiding preferences...");
    [window orderOut:[window identifier]];
}


- (IBAction)savePreferences:(id)sender {
    
    NSString *username = self.fusername.stringValue;
    self.username = username;
    [self savePreferences];
}


- (IBAction)discardPreferences:(id)sender {
    [self discardPreferences];
}


- (void)closeSplash {
    [splash orderOut:self];
}


- (void)showPreferences {
    [splash orderOut:self];
    NSLog(@"==> showing preferences...");
    [self loadPreferences];
    [window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)loadPreferences {
    // TODO(cpauya): Get the persisted preferences.
    // If none found, we must prompt the preference dialog.
    NSLog(@"==> loading preferences...");
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *username = [prefs stringForKey:@"username"];
    self.username = username;
    return;
}


- (void)savePreferences {
    /*
     1. Validate the following:
        * username length max of 30 characters
        * password length max of 128 characters
        * username allowed characters are "letters, numbers and @/./+/-/_ characters" based on django.contrib.auth.models.AbstractUser
     2. TODO(cpauya): Save the preferences: REF: http://stackoverflow.com/questions/10148788/xcode-cocoa-app-preferences
     3. Copy local_settings_sample.py to local_settings.py
     4. Run `kalite manage setup` if no database was found.
     */

    NSLog(@"==> saving preferences...");
    
    if (self.username == nil) {
        alert(@"Username must not be blank and can only contain letters, numbers and @/./+/-/_ characters.");
        return;
    }

    NSString *usernameChars = getUsernameChars();
    if ([self string:usernameChars containsAllCharactersInString:self.username] == NO) {
        alert(@"Invalid username characters found, please use letters, numbers and @/./+/-/_ characters.");
        return;
    }
    
    if ([self.username length] > 30) {
        alert(@"Username must not exceed 30 characters.");
        return;
    }

    if (self.password == nil || self.confirmPassword == nil) {
        alert(@"Invalid password or the password does not match on both fields.");
        return;
    }

    if (![self.password isEqualToString:self.confirmPassword]) {
        alert(@"The password does not match on both fields.");
        return;
    }

    if ([self.password length] > 128) {
        alert(@"Password must not exceed 128 characters.");
        return;
    }
    
    // TODO(cpauya): Save the preferences.
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:self.username forKey:@"username"];

    // Copy `local_settings.default` if no `local_settings.py` was found.
    NSString *localSettingsPath = getLocalSettingsPath();
    if (localSettingsPath == nil) {
        copyLocalSettings();
    }
    
    // Automatically run `kalite manage setup` if no database was found.
    NSString *databasePath = getDatabasePath();
    if (databasePath == nil) {
        // Get admin account credentials from preferences.
        showNotification(@"Running `kalite manage setup`.");
        NSString *cmd = [NSString stringWithFormat:@"manage setup --username %@ --password %@ --noinput",
                         self.username, self.password];
        int i = runKalite(cmd);
        if (i == 0) {
            [window orderOut:[window identifier]];
        } else {
            alert(@"Running 'manage setup' failed, please see Console.");
        }
    }
}


- (void)discardPreferences {
    NSLog(@"==> discarding changes in preferences...");
    // TODO(cpauya): Discard changes and load the saved preferences.
    [window orderOut:[window identifier]];
}


- (void)loadLog {
    // REF: http://boredzo.org/blog/archives/2008-01-23/asl-searching
    // REF: http://stackoverflow.com/questions/13621343/getting-time-of-logs-stored-in-asl-log-files-with-asl-api-objective-c
    // TODO(cpauya): Actually, it is not practical to load log data here.
    // We must use ASL + notifications instead of this.
    return;
}


@end
