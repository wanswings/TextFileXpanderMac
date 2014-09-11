//
//  AppDelegate.h
//  TextFileXpander
//
//  Created by wanswings on 2014/08/18.
//  Copyright (c) 2014 wanswings. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    @private
    NSStatusItem *fpItem;
    NSMenu *fpMenu;
    int idxLaunchAtStartup;
}

@end
