//
//  AppDelegate.m
//  TextFileXpander
//
//  Created by wanswings on 2014/08/18.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import "AppDelegate.h"

static NSString *const DOWNLOAD_URL = @"https://github.com/wanswings/TextFileXpanderMac/releases";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

    fpMenu = [[NSMenu alloc] init];
    [self refreshData:self];

    // Create NSStatusBar and set length
    fpItem = [[NSStatusBar systemStatusBar]statusItemWithLength:NSSquareStatusItemLength];

    // Sets the images
    NSImage *statusImage = [NSImage imageNamed:@"status"];
    [fpItem setImage:statusImage];
    NSImage *altStatusImage = [NSImage imageNamed:@"status_alternative"];
    [fpItem setAlternateImage:altStatusImage];

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
    NSLog(@"pushData: %@", str);

    NSString *pattern1 = @"^([a-z]+):\\s*(.+)";
    NSError *error1 = nil;
    NSRegularExpression *regexp1 = [NSRegularExpression regularExpressionWithPattern:pattern1
                                        options:NSRegularExpressionCaseInsensitive error:&error1];
    NSTextCheckingResult *match1 = [regexp1 firstMatchInString:str
                                        options:0 range:NSMakeRange(0, str.length)];
    if (match1) {
        NSString *matchCmd = [str substringWithRange:[match1 rangeAtIndex:1]];
        NSLog(@"matchCmd: %@", matchCmd);
        NSString *matchStr = [str substringWithRange:[match1 rangeAtIndex:2]];
        NSLog(@"matchStr: %@", matchStr);

        NSString *sendStr = nil;
        BOOL isSendPasteboard = NO;

        if ([matchCmd isEqual:@"currency"]) {
            // currency
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(\\S+)";
            NSError *error2 = nil;
            NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                                options:NSRegularExpressionCaseInsensitive error:&error2];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];

                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://www.google.com/finance/?q="];
                [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                sendStr = wk;
            }
            else {
                str = matchStr;
            }
        }
        else if ([matchCmd isEqual:@"dict"]) {
            // dict
            sendStr = [@"dict://" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"flight"]) {
            // flight
            sendStr = [@"http://flightaware.com/live/flight/" stringByAppendingString:
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
        else if ([matchCmd isEqual:@"near"]) {
            // near
            sendStr = [@"http://foursquare.com/explore?near=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"people"]) {
            // people
            sendStr = @"addressbook://";
            str = matchStr;
            isSendPasteboard = YES;
        }
        else if ([matchCmd isEqual:@"recipe"]) {
            // recipe
            sendStr = [@"http://www.epicurious.com/tools/searchresults?search=" stringByAppendingString:
                       [matchStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([matchCmd isEqual:@"route"]) {
            // route
            NSString *pattern2 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
            NSError *error2 = nil;
            NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                                options:NSRegularExpressionCaseInsensitive error:&error2];
            NSTextCheckingResult *match2 = [regexp2 firstMatchInString:matchStr
                                                options:0 range:NSMakeRange(0, matchStr.length)];
            if (match2) {
                NSString *matchfrom = [matchStr substringWithRange:[match2 rangeAtIndex:1]];
                NSString *matchto = [matchStr substringWithRange:[match2 rangeAtIndex:2]];

                NSMutableString *wk = [NSMutableString string];
                [wk setString:@"http://maps.google.com/maps?saddr="];
                if (![matchfrom isEqual:@"here"]) {
                    [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }
                [wk appendString:@"&daddr="];
                [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                sendStr = wk;
            }
            else {
                str = matchStr;
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
            sendStr = [@"http://www.google.com/search?q=weather%20" stringByAppendingString:
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

- (void)about:(id)sender
{
    NSString *str = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];

    NSAlert *alert = [NSAlert alertWithMessageText:[@"About " stringByAppendingString:appName]
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:@"Download site"
                         informativeTextWithFormat:@"Version: %@", str
                      ];
    long iHitButton = [alert runModal];
    if (iHitButton == NSAlertOtherReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:DOWNLOAD_URL]];
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
        NSError *error0 = nil;
        NSArray *list = [fileManager contentsOfDirectoryAtPath:dirPath error:&error0];
        list = [list sortedArrayUsingSelector:@selector(compare:)];

        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
        BOOL existData = NO;
        for (NSString *fname in list) {
            @autoreleasepool {
                NSString *fullPath = [dirPath stringByAppendingPathComponent:fname];
                error0 = nil;
                NSDictionary *attrs = [fileManager attributesOfItemAtPath:fullPath error:&error0];
                if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] && [fname hasSuffix:@".txt"]) {
                    // Only text file
                    error0 = nil;
                    NSString *fdata = [NSString stringWithContentsOfFile:fullPath
                                                    encoding:NSUTF8StringEncoding error:&error0];
                    // Create submenu
                    NSMenu *submenu = [[NSMenu alloc] init];
                    NSString *pattern1 = @"^(-{2}-+)\\s*(.*)";
                    NSString *pattern2 = @"^([a-z]+):(.+)";
                    __block BOOL existSubData = NO;
                    __block int idxSub = 0;
                    __block NSColor *fg;
                    [fdata enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                        if (line.length > 0) {
                            existSubData = YES;
                            @autoreleasepool {
                                NSError *error1 = nil;
                                NSRegularExpression *regexp1 = [NSRegularExpression regularExpressionWithPattern:pattern1
                                                                    options:NSRegularExpressionCaseInsensitive error:&error1];
                                NSTextCheckingResult *match1 = [regexp1 firstMatchInString:line
                                                                    options:0 range:NSMakeRange(0, line.length)];
                                if (match1) {
                                    NSMenuItem *subItem = [NSMenuItem separatorItem];
                                    [submenu addItem:subItem];
                                    idxSub++;
                                }
                                else {
                                    NSError *error2 = nil;
                                    NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                                                        options:NSRegularExpressionCaseInsensitive error:&error2];
                                    NSTextCheckingResult *match2 = [regexp2 firstMatchInString:line
                                                                        options:0 range:NSMakeRange(0, line.length)];
                                    if (match2) {
                                        NSString *matchCmd = [line substringWithRange:[match2 rangeAtIndex:1]];
                                        NSString *matchStr = [line substringWithRange:[match2 rangeAtIndex:2]];

                                        if ([matchCmd isEqual:@"currency"]) {
                                            // currency
                                            [self getCurrencyStart:matchStr idxMain:idxMain idxSub:idxSub];
                                            fg = [NSColor blackColor];
                                        }
                                        else if ([matchCmd isEqual:@"marker"]) {
                                            // marker
                                            fg = [self getMarkerColor:matchStr line:&line];
                                        }
                                        else {
                                            fg = [NSColor blackColor];
                                        }
                                    }
                                    else {
                                        fg = [NSColor blackColor];
                                    }
                                    NSDictionary *paragraphStyle = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    style, NSParagraphStyleAttributeName,
                                                                    fg, NSForegroundColorAttributeName,
                                                                    nil];

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
    [fpMenu addItemWithTitle:[@"About " stringByAppendingString:appName] action:@selector(about:) keyEquivalent:@""];
    idxMain++;
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

- (NSColor *)getMarkerColor:(NSString *)param line:(NSString **)line
{
    NSColor *fg;

    NSString *pattern = @"^\\s*(strong:|weak:)?\\s*(.+)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                        options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regexp firstMatchInString:param
                                        options:0 range:NSMakeRange(0, param.length)];
    if (match) {
        if ([match rangeAtIndex:1].length == 0) {
            fg = [NSColor blueColor];
        }
        else {
            NSString *matchCmd = [param substringWithRange:[match rangeAtIndex:1]];
            if ([matchCmd isEqual:@"strong:"]) {
                fg = [NSColor redColor];
            }
            else if ([matchCmd isEqual:@"weak:"]) {
                fg = [NSColor lightGrayColor];
            }
            else {
                fg = [NSColor blueColor];
            }
        }
        *line = [param substringWithRange:[match rangeAtIndex:2]];
    }
    else {
        fg = [NSColor blackColor];
    }

    return fg;
}

- (void)getCurrencyStart:(NSString *)param idxMain:(int)idxMain idxSub:(int)idxSub
{
    NSString *pattern1 = @"^\\s*from:\\s*(.+)\\s+to:\\s*(.+)";
    NSError *error1 = nil;
    NSRegularExpression *regexp1 = [NSRegularExpression regularExpressionWithPattern:pattern1
                                        options:NSRegularExpressionCaseInsensitive error:&error1];
    NSTextCheckingResult *match1 = [regexp1 firstMatchInString:param
                                        options:0 range:NSMakeRange(0, param.length)];
    if (!match1) {
        return;
    }

    NSString *matchfrom = [param substringWithRange:[match1 rangeAtIndex:1]];
    NSString *matchto = [param substringWithRange:[match1 rangeAtIndex:2]];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSMutableString *wk = [NSMutableString string];
        [wk setString:@"http://www.google.com/finance/converter?a=1&from="];
        [wk appendString:[matchfrom stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [wk appendString:@"&to="];
        [wk appendString:[matchto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *url = [NSURL URLWithString:wk];

        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url
                                                  cachePolicy:NSURLRequestReloadIgnoringCacheData
                                              timeoutInterval:10.0];
        NSURLResponse *res = nil;
        NSError *error = nil;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
        NSString *estr = [error localizedDescription];
        if ([estr length] > 0) {
            NSLog(@"Error: %@", estr);
            return;
        }
        NSString *str = [[NSString alloc] initWithData:returnData encoding:NSISOLatin1StringEncoding];

        NSString *pattern2 = @"<span class=bld>([0-9\\.]+).+</span>";
        NSError *error2 = nil;
        NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:pattern2
                                            options:NSRegularExpressionCaseInsensitive error:&error2];
        NSTextCheckingResult *match2 = [regexp2 firstMatchInString:str
                                            options:0 range:NSMakeRange(0, str.length)];
        if (match2) {
            NSString *matchValue = [str substringWithRange:[match2 rangeAtIndex:1]];

            [[[fpMenu itemAtIndex:idxMain].submenu itemAtIndex:idxSub] setToolTip:matchValue];
            NSLog(@"Response: %@", matchValue);
        }
    }];
}

@end
