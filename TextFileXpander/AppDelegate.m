//
//  AppDelegate.m
//  TextFileXpander
//
//  Created by wanswings on 2014/08/18.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    fpMenu = [[NSMenu alloc] init];
    [self refreshData:self];

    // Create NSStatusBar and set length
    fpItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSSquareStatusItemLength];

    // Sets the images
    NSImage *statusImage = [NSImage imageNamed:@"status"];
    [fpItem setImage:statusImage];
    NSImage *altStatusImage = [NSImage imageNamed:@"status_alternative"];
    [fpItem setAlternateImage:altStatusImage];

    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    [fpItem setToolTip:appName];

    [fpItem setHighlightMode:YES];
    [fpItem setMenu:fpMenu];
}

// [CGKeyCode]
// C: 8
// V: 9
// command: 55
// shift: 56
// caps: 57
// option: 58
// control: 59
- (void)pasteCurrent {
    CGEventRef cmdDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, YES);
    CGEventRef vDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)9, YES);
    CGEventRef vUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)9, NO);
    CGEventRef cmdUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, NO);

    CGEventSetFlags(vDown,kCGEventFlagMaskCommand);
    CGEventSetFlags(vUp,kCGEventFlagMaskCommand);

    CGEventPost(kCGHIDEventTap, cmdDown);
    CGEventPost(kCGHIDEventTap, vDown);
    CGEventPost(kCGHIDEventTap, vUp);
    CGEventPost(kCGHIDEventTap, cmdUp);

    CFRelease(cmdDown);
    CFRelease(vDown);
    CFRelease(vUp);
    CFRelease(cmdUp);
}

- (void)pushData:(id)sender
{
    NSString *str = [sender representedObject];

    NSString *pattern = @"^([a-z]+):\\s*(.+)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                        options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regexp firstMatchInString:str
                                        options:0 range:NSMakeRange(0, str.length)];
    if (match) {
        NSString *matchCmd = [str substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"matchCmd: %@", matchCmd);
        NSString *matchStr = [str substringWithRange:[match rangeAtIndex:2]];
        NSLog(@"matchStr: %@", matchStr);

        NSString *sendStr = nil;
        BOOL isSendPasteboard = NO;

        if ([matchCmd isEqual:@"dict"]) {
            // dict
            sendStr = [@"dict://" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"flight"]) {
            // flight
            sendStr = [@"http://www.google.com/search?q=flight%20" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"mailto"]) {
            // mailto
            sendStr = [NSString stringWithFormat:@"mailto:%@", matchStr];
        }
        else if ([matchCmd isEqual:@"map"]) {
            // map
            sendStr = [@"http://maps.google.com/maps?q=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"people"]) {
            // people
            sendStr = @"addressbook://";
            str = matchStr;
            isSendPasteboard = YES;
        }
        else if ([matchCmd isEqual:@"route"]) {
            // route
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
            NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                                options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSLog(@"matchfrom: %@", matchfrom);
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];
                NSLog(@"matchto: %@", matchto);

                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://maps.google.com/maps?saddr="];
                [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [wk appendString:@"&daddr="];
                [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                sendStr = wk;
            }
        }
        else if ([matchCmd isEqual:@"tel"]) {
            // tel
            str = matchStr;
        }
        else if ([matchCmd isEqual:@"twitter"]) {
            // twitter
            sendStr = [@"twitter://post?message=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"url"]) {
            // url
            sendStr = matchStr;
        }
        else if ([matchCmd isEqual:@"weather"]) {
            // weather
            sendStr = [@"http://www.weather.com/search/enhancedlocalsearch?where=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"youtube"]) {
            // youtube
            sendStr = [@"http://www.youtube.com/results?search_query=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        if (sendStr != nil) {
            NSLog(@"%@: %@", matchCmd, sendStr);
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sendStr]];
            if (!isSendPasteboard) {
                return;
            }
            // wait 1.0s
            [NSThread sleepForTimeInterval:1.0];
        }
    }

    // To Pasteboard
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pboard setString:str forType:NSStringPboardType];
    NSLog(@"To Pasteboard: %@", str);
    // To Active App
    [self pasteCurrent];
}

- (void)launchApplication:(id)sender
{
    NSString *fullPath = [sender representedObject];
    // Launch App
    NSLog(@"Launch text editor with: %@", fullPath);
    [[NSWorkspace sharedWorkspace] openFile:fullPath withApplication:nil andDeactivate:YES];
}

- (BOOL)isLaunchAtStartup:(BOOL)doAddRemove {
    BOOL registered = NO;
    LSSharedFileListRef loginItemsListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef loginItems = LSSharedFileListCopySnapshot(loginItemsListRef, NULL);
    CFURLRef bundleURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];

    for (id item in (__bridge NSArray *)loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            if ([(NSString *)CFURLGetString(itemURLRef) isEqual:(NSString *)CFURLGetString(bundleURL)]) {
                registered = YES;
                if (doAddRemove) {
                    // Remove
                    LSSharedFileListItemRemove(loginItemsListRef, itemRef);
                }
                CFRelease(itemURLRef);
                break;
            }
            else {
                CFRelease(itemURLRef);
            }
        }
    }
    if (!registered && doAddRemove) {
        // Add
        LSSharedFileListItemRef itemRef =
            LSSharedFileListInsertItemURL(loginItemsListRef, kLSSharedFileListItemLast, NULL, NULL, bundleURL, NULL ,NULL);
        CFRelease(itemRef);
    }

    CFRelease(loginItems);
    CFRelease(loginItemsListRef);

    if (doAddRemove) {
        return !registered;
    }
    else {
        return registered;
    }
}

- (void)toggleLaunchAtStartup:(id)sender {
    if ([self isLaunchAtStartup:YES]) {
        [[fpMenu itemAtIndex:idxLaunchAtStartup] setState:NSOnState];
    }
    else {
        [[fpMenu itemAtIndex:idxLaunchAtStartup] setState:NSOffState];
    }
}

- (void)refreshData:(id)sender
{
    [fpMenu removeAllItems];
    int idxMain = 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *dirPath = [defaults stringForKey:@"dirPath"];
    if (dirPath) {
        NSLog(@"Load path: %@", dirPath);
        // Get files
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *list = [fileManager contentsOfDirectoryAtPath:dirPath error:&error];
        list = [list sortedArrayUsingSelector:@selector(compare:)];

        NSString *pattern = @"^(-{2}-+)\\s*(.*)";
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                            options:NSRegularExpressionCaseInsensitive error:&error];
        BOOL existData = NO;
        for (NSString *fname in list) {
            @autoreleasepool {
                NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                [style setLineBreakMode:NSLineBreakByTruncatingTail];
                NSDictionary *paragraphStyle = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                style, NSParagraphStyleAttributeName,
                                                nil];

                NSString *fullPath = [dirPath stringByAppendingPathComponent:fname];
                NSDictionary *attrs = [fileManager attributesOfItemAtPath:fullPath error:&error];
                if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] && [fname hasSuffix:@".txt"]) {
                    // Only text file
                    NSString *fdata = [NSString stringWithContentsOfFile:fullPath
                                                    encoding:NSUTF8StringEncoding error:&error];
                    // Create submenu
                    NSMenu *submenu = [[NSMenu alloc] init];
                    __block BOOL existSubData = NO;
                    __block int idxSub = 0;
                    [fdata enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                        if (line.length > 0) {
                            existSubData = YES;
                            @autoreleasepool {
                                ;
                                NSTextCheckingResult *match = [regexp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
                                if (match) {
                                    NSMenuItem *subItem = [NSMenuItem separatorItem];
                                    [submenu addItem:subItem];
                                    idxSub++;
                                }
                                else {
                                    NSAttributedString *itemName =
                                        [[NSAttributedString alloc] initWithString:line attributes:paragraphStyle];
                                    NSMenuItem *subItem =
                                        [[NSMenuItem alloc] initWithTitle:line action:@selector(pushData:) keyEquivalent:@""];
                                    [subItem setAttributedTitle:itemName];
                                    [submenu addItem:subItem];
                                    [[submenu itemAtIndex:idxSub++] setRepresentedObject:line];
                                }
                            }
                        }
                    }];

                    NSMenuItem *menuItem = [fpMenu addItemWithTitle:fname
                                                        action:@selector(launchApplication:) keyEquivalent:@""];
                    if (existSubData) {
                        [fpMenu setSubmenu:submenu forItem:menuItem];
                    }
                    [menuItem setRepresentedObject:fullPath];
                    idxMain++;
                    existData = YES;
                }
            }
        }
        if (existData) {
            [fpMenu addItem:[NSMenuItem separatorItem]];
            idxMain++;
        }
    }
    else {
        NSLog(@"Load path: No data!");
    }
    [fpMenu addItemWithTitle:@"Select Directory" action:@selector(selectDir:) keyEquivalent:@""];
    idxMain++;
    [fpMenu addItemWithTitle:@"Refresh" action:@selector(refreshData:) keyEquivalent:@""];
    idxMain++;
    [fpMenu addItemWithTitle:@"Launch at startup" action:@selector(toggleLaunchAtStartup:) keyEquivalent:@""];
    idxLaunchAtStartup = idxMain++;
    [[fpMenu itemAtIndex:idxLaunchAtStartup] setOnStateImage:[NSImage imageNamed:@"check"]];
    if ([self isLaunchAtStartup:NO]) {
        [[fpMenu itemAtIndex:idxLaunchAtStartup] setState:NSOnState];
    }
    [fpMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
}

- (void)selectDir:(id)sender
{
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    // Sets whether the user can select multiple files (and directories) at one time for opening.
    [openDlg setAllowsMultipleSelection:NO];
    // Sets whether the user can select directories in the panel’s browser.
    [openDlg setCanChooseDirectories:YES];
    // Sets whether the user can select files in the panel’s browser.
    [openDlg setCanChooseFiles:NO];
    // Sets the prompt of the default button.
    [openDlg setPrompt:@"Select"];

    // Display the dialog.  If the OK button was pressed,
    // process the directory.
    if ([openDlg runModal] == NSOKButton) {
        // Get the directory path.
        NSString *dirPath = [[openDlg URL] path];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:dirPath forKey:@"dirPath"];
        [defaults synchronize];
        // ~/Library/Preferences/com.wanswings.TextFileXpander.plist
        NSLog(@"Save path: %@", dirPath);

        [self refreshData:self];
    }
}

@end
