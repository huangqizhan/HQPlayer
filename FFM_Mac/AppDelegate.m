//
//  AppDelegate.m
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/2/5.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "HQFrame+Interal.h"
#import "HQSegment+Inteal.h"
#import "HQClock+Interal.h"
#import "HQReanderable.h"
#import "HQPlayerItem+Internal.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window.contentViewController = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:[NSBundle mainBundle]];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
