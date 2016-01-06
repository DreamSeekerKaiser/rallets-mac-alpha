//
//  SWBAppDelegate.m
//  ShadowsocksX
//
//  Created by clowwindy on 14-2-19.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import "GZIP.h"
#import "SWBConfigWindowController.h"
#import "SWBQRCodeWindowController.h"
#import "LoginController.h"
#import "SWBAppDelegate.h"
#import "GCDWebServer.h"
#import "ShadowsocksRunner.h"
#import "ProfileManager.h"
#import "AFNetworking.h"
#import "HttpUtil.h"
#import "Util.h"
#import "User.h"

#define kRalletsIsRunningKey @"ShadowsocksIsRunning"
#define kRalletsRunningModeKey @"ShadowsocksMode"
#define kRalletsHelper @"/Library/Application Support/RalletsX/Rallets_sysconf"
#define kSysconfVersion @"1.0.0"

@implementation SWBAppDelegate {
    SWBConfigWindowController *configWindowController;
    LoginController *loginController;
    SWBQRCodeWindowController *qrCodeWindowController;
    NSMenuItem *enableMenuItem;
    // 账户信息
    NSMenuItem *loginItem;
    NSMenuItem *premiumTrafficItem;
    NSMenuItem *myProfileItem;
    NSMenuItem *buyServiceItem;
    // 其他信息
    NSMenu *othersMenu;

    NSMenuItem *runnimgModeItem;
    NSMenu *serversMenu;
    NSMenu *accountMenu;
    BOOL isRunning;
    NSData *originalPACData;
    FSEventStreamRef fsEventStream;
    NSString *configPath;
    NSString *PACPath;
    NSString *userRulePath;
    AFHTTPRequestOperationManager *manager;
    NSTimer* ralletsNotificationtimer;
    NSTimer* updateConfigurationTimer;
}

static SWBAppDelegate *appDelegate;
+ (SWBAppDelegate*) one {
    return appDelegate;
}

static int RALLETS_NOTIFICATION_REQUEST_INTERVAL = 300;
- (void)noopAction {}

- (NSString*) enableMenuItemTitle {
    NSString* action = isRunning ? _L(Turn Off) : _L(Turn On);
    NSString* mode = [self.runningMode isEqualToString:@"global"] ? _L(Global Mode) : _L(Smart Mode);
    return [NSString stringWithFormat:@"%@  [%@]", action, mode];
}
- (NSString*) modeMenuItemTitle {
    
    return [NSString stringWithFormat:@"%@ %@", _L(Switch To), [self.runningMode isEqualToString:@"global"] ? _L(Smart Mode) : _L(Global Mode)];
}
- (NSString*) loginMenuItemTitle {
    return [User one].loggedIn ? [NSString stringWithFormat:@"%@ %@", _L(Logout), [User one].email] : _L(Login);
}

- (NSString*) runningMode {
    NSString* mode = [[NSUserDefaults standardUserDefaults] stringForKey:kRalletsRunningModeKey];
    return mode ? mode : @"global";
}
- (void) setRunningMode:(NSString *)mode {
    [[NSUserDefaults standardUserDefaults] setValue:mode forKey:kRalletsRunningModeKey];
    [self toggleSystemProxy:true];
    [self updateMenu];
}

- (void) updateAccountItems {
    User* user = [User one];
    [premiumTrafficItem setTitle:[NSString stringWithFormat:@"%@:  %.3f GB", _L(Remaining Traffic), [user premiumTraffic]]];
    BOOL loggedIn = user.loggedIn;
    [buyServiceItem setHidden:!loggedIn];
    [myProfileItem setHidden:!loggedIn];
}

- (void)updateMenu {
    [self updateAccountItems];
    [loginItem setTitle:[self loginMenuItemTitle]];
    [enableMenuItem setTitle:[self enableMenuItemTitle]];
    if (isRunning) {
        [enableMenuItem setState:1];
        NSImage *image = [NSImage imageNamed:@"menu_icon"];
        [image setTemplate:YES];
        self.item.image = image;
    } else {
        [enableMenuItem setState:0];
        NSImage *image = [NSImage imageNamed:@"menu_icon_disabled"];
        [image setTemplate:YES];
        self.item.image = image;
    }
    [runnimgModeItem setTitle:[self modeMenuItemTitle]];
    [self updateServersMenu];
}

- (void) initSystemStatusBar {
    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:20];
    NSImage *image = [NSImage imageNamed:@"menu_icon"];
    [image setTemplate:YES];
    self.item.image = image;
    self.item.highlightMode = YES;
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Rallets"];
    [menu setMinimumWidth:200];
    enableMenuItem = [[NSMenuItem alloc] initWithTitle:[self enableMenuItemTitle] action:@selector(toggleRunning) keyEquivalent:@""];
    runnimgModeItem = [[NSMenuItem alloc] initWithTitle:[self modeMenuItemTitle] action:@selector(toggleRunningMode) keyEquivalent:@""];
    
    [menu addItem:enableMenuItem];
    [menu addItem:runnimgModeItem];
    
    [menu addItem:[NSMenuItem separatorItem]];

    // 服务器下拉菜单
    serversMenu = [[NSMenu alloc] init];
    NSMenuItem *serversItem = [[NSMenuItem alloc] init];
    [serversItem setTitle:_L(Servers)];
    [serversItem setSubmenu:serversMenu];
    [menu addItem:serversItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // 账户下拉菜单
    accountMenu = [[NSMenu alloc] init];
    NSMenuItem *accountItem = [[NSMenuItem alloc] init];
    [accountItem setTitle:_L(Account)];
    [accountItem setSubmenu:accountMenu];
    [menu addItem:accountItem];
    
    loginItem = [[NSMenuItem alloc] initWithTitle:_L(Login) action:@selector(onPressLoginItem) keyEquivalent:@""];
    myProfileItem = [[NSMenuItem alloc] initWithTitle:_L(My Profile) action:@selector(openMyProfilePage) keyEquivalent:@""];
    buyServiceItem = [[NSMenuItem alloc] initWithTitle:_L(Buy Service) action:@selector(openPaymentPage) keyEquivalent:@""];
    premiumTrafficItem = [[NSMenuItem alloc] initWithTitle:_L(Remaining Traffic) action:@selector(noopAction) keyEquivalent:@""];

    [accountMenu addItem:myProfileItem];
    [accountMenu addItem:buyServiceItem];
    [accountMenu addItem:loginItem];
    [accountMenu addItem:[NSMenuItem separatorItem]];
    [accountMenu addItem:premiumTrafficItem];
    
    [menu addItem:[NSMenuItem separatorItem]];

    // 其它
    othersMenu = [[NSMenu alloc] init];
    NSMenuItem *othersItem = [[NSMenuItem alloc] init];
    [othersItem setTitle:_L(Others)];
    [othersItem setSubmenu:othersMenu];
    [menu addItem:othersItem];
    [othersMenu addItemWithTitle:_L(Update Routing List) action:@selector(updatePACFromGFWList) keyEquivalent:@""];
    [othersMenu addItemWithTitle:_L(About Rallets) action:@selector(showHelp) keyEquivalent:@""];
    [othersMenu addItemWithTitle:[NSString stringWithFormat:@"%@: %@", _L(Version), [Util currentVersion]] action:@selector(noopAction) keyEquivalent:@""];
    
    //    [menu addItemWithTitle:_L(Edit User Rule) action:@selector(editUserRule) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Quit) action:@selector(exit) keyEquivalent:@""];
    self.item.menu = menu;
    [self updateMenu];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification{
    appDelegate = self;
    [self initSystemStatusBar];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self installHelper];

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    [self toggleSystemProxy:NO];
    [HttpUtil postRalletsNotification];
    [self startTimer];
    // Insert code here to initialize your application
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    originalPACData = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"proxy" withExtension:@"pac.gz"]] gunzippedData];
    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path:@"/proxy.pac" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        return [GCDWebServerDataResponse responseWithData:[self PACData] contentType:@"application/x-ns-proxy-autoconfig"];
    }
    ];

    [webServer startWithPort:8090 bonjourName:@"webserver"];

    manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    configPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @".ShadowsocksX"];
    PACPath = [NSString stringWithFormat:@"%@/%@", configPath, @"gfwlist.js"];
    userRulePath = [NSString stringWithFormat:@"%@/%@", configPath, @"user-rule.txt"];
    [self monitorPAC:configPath];
    [self restoreRunning];
    [self updateMenu];
}

- (NSData *)PACData {
    if ([[NSFileManager defaultManager] fileExistsAtPath:PACPath]) {
        return [NSData dataWithContentsOfFile:PACPath];
    } else {
        return originalPACData;
    }
}

- (void)toggleRunningMode {
    self.runningMode = [self.runningMode isEqualToString:@"global"] ? @"auto" : @"global";
}
- (void)enableGlobal {
    self.runningMode = @"global";
}

- (void)enableAuto {
    self.runningMode = @"auto";
}

- (void)chooseServer:(id)sender {
    NSInteger tag = [sender tag];
    Configuration *configuration = [ProfileManager configuration];
    if (tag == -1 || tag < configuration.profiles.count) {
        configuration.current = tag;
    }
    [ProfileManager saveConfiguration:configuration];
    [self updateServersMenu];
}

- (void)updateServersMenu {
    Configuration *configuration = [ProfileManager configuration];
    [serversMenu removeAllItems];
    int i = 0;
    NSMenuItem *publicItem = [[NSMenuItem alloc] initWithTitle:_L(Public Server) action:@selector(chooseServer:) keyEquivalent:@""];
    publicItem.tag = -1;
    for (Profile *profile in configuration.profiles) {
        NSString *title;
        if (profile.remarks.length) {
            title = [NSString stringWithFormat:@"%@", profile.remarks];
        } else {
            title = @"Rallets Server";
        }
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(chooseServer:) keyEquivalent:@""];
        item.tag = i;
        if (i == configuration.current) {
            [item setState:1];
        }
        [serversMenu addItem:item];
        i++;
    }
}

void onPACChange(
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    [appDelegate reloadSystemProxy];
}

- (void)reloadSystemProxy {
    [self toggleSystemProxy:isRunning];
}

- (void)monitorPAC:(NSString *)pacPath {
    if (fsEventStream) {
        return;
    }
    CFStringRef mypath = (__bridge CFStringRef)(pacPath);
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&mypath, 1, NULL);
    void *callbackInfo = NULL; // could put stream-specific data here.
    CFAbsoluteTime latency = 3.0; /* Latency in seconds */

    /* Create the stream, passing in a callback */
    fsEventStream = FSEventStreamCreate(NULL,
            &onPACChange,
            callbackInfo,
            pathsToWatch,
            kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
            latency,
            kFSEventStreamCreateFlagNone /* Flags explained in reference */
    );
    FSEventStreamScheduleWithRunLoop(fsEventStream, [[NSRunLoop mainRunLoop] getCFRunLoop], (__bridge CFStringRef)NSDefaultRunLoopMode);
    FSEventStreamStart(fsEventStream);
}

- (void)editPAC {
    if (![[NSFileManager defaultManager] fileExistsAtPath:PACPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error];
        // TODO check error
        [originalPACData writeToFile:PACPath atomically:YES];
    }
    [self monitorPAC:configPath];
    
    NSArray *fileURLs = @[[NSURL fileURLWithPath:PACPath]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}


- (void)editUserRule {
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:userRulePath]) {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error];
    // TODO check error
    [@"! Put user rules line by line in this file.\n! See https://adblockplus.org/en/filter-cheatsheet\n" writeToFile:userRulePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
  }
  
  NSArray *fileURLs = @[[NSURL fileURLWithPath:userRulePath]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (void)showLogs {
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Console.app"];
}

- (void)showHelp {
    [Util openUrl:@"http://rallets.com"];
}
- (void)openMyProfilePage {
    [[User one] openAccountPageWithAutoLogin:@"profile"];
}

- (void)openPaymentPage {
    [[User one] openAccountPageWithAutoLogin:@"payment"];
}
- (void)ralletsNotification {
    if ([User one].loggedIn) {
        NSLog(@"rallets_notification");
        NSMutableURLRequest *postRequest = [HttpUtil makeRequest:@"rallets_notification" params:nil];
        self.receivedData = [NSMutableData data];
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self];
        if(!conn) {
            NSLog(@"Post /rallets_notification failed");
        }
    }
}
- (void)ralletsNotification: (NSTimer*) timer {
    [self ralletsNotification];
}

- (void)onPressLoginItem {
    [self logout:@"You are logged out"];
}

- (void) logout:(NSString*) message {
    [ProfileManager setConfigsIfDifferent:nil];
    [self showLoginForm];
    [loginController showWarningTitle:message];
    [[User one] logout];
    [self setRunning:NO];
    [self stopProxy];
}
- (void) closeLoginForm {
    if (loginController) {
        [loginController.windows performClose:loginController];
    }
}
- (void)showLoginForm {
    [self closeLoginForm];
    loginController = [[LoginController alloc] initWithWindowNibName:@"LoginWindow"];
    loginController.delegate = self;
    [loginController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [loginController.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"terminating");
    if (isRunning) {
        [self toggleSystemProxy:NO];
    }
}

- (void)configurationDidChange {
    [self updateMenu];
}

- (void)runProxy {
    //[ShadowsocksRunner reloadConfig];
    for (; ;) {
        if ([ShadowsocksRunner runProxy]) {
            sleep(1);
        } else {
            sleep(2);
        }
    }
}

- (void)exit {
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)installHelper {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kRalletsHelper] || ![self isSysconfVersionOK]) {
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"bash %@\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"installation success");
        } else {
            NSLog(@"installation failure");
        }
    }
}

- (BOOL)isSysconfVersionOK {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kRalletsHelper];
    
    NSArray *args;
    args = [NSArray arrayWithObjects:@"-v", nil];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fd;
    fd = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [fd readDataToEndOfFile];
    
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (![str isEqualToString:kSysconfVersion]) {
        return NO;
    }
    return YES;
}

- (void)startTimer {
    ralletsNotificationtimer = [NSTimer scheduledTimerWithTimeInterval:RALLETS_NOTIFICATION_REQUEST_INTERVAL target:self selector:@selector(ralletsNotification:) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    [ralletsNotificationtimer invalidate];
    ralletsNotificationtimer = nil;
}

- (void)toggleRunning {
    NSLog(@"loggedIn?: %hhd, running?: %hhd", [User one].loggedIn, isRunning);
    if (![User one].loggedIn && !isRunning) return;
    [self setRunning:!isRunning];
}

- (void)setRunning:(BOOL)isR {
    [self toggleSystemProxy:isR];
    [[NSUserDefaults standardUserDefaults] setBool:isR forKey:kRalletsIsRunningKey];
    [self updateMenu];
}

- (void)restoreRunning {
    [self toggleSystemProxy:[[NSUserDefaults standardUserDefaults] boolForKey:kRalletsIsRunningKey]];
}

- (void)toggleSystemProxy:(BOOL)useProxy {
    isRunning = useProxy;
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kRalletsHelper];

    NSString *param;
    if (useProxy) {
        param = [self runningMode];
    } else {
        param = @"off";
    }

    // this log is very important
    NSLog(@"run shadowsocks helper in toggleSystemProxy: %@", kRalletsHelper);
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects:param, nil];
    [task setArguments:arguments];

    NSPipe *stdoutpipe = [NSPipe pipe];
    [task setStandardOutput:stdoutpipe];

    NSPipe *stderrpipe = [NSPipe pipe];
    [task setStandardError:stderrpipe];
    
    [task launch];

    [Util logFileHandler:stdoutpipe];
    [Util logFileHandler:stderrpipe];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:_L(OK)];
    [alert addButtonWithTitle:_L(Cancel)];
    [alert setMessageText:_L(Use this server?)];
    [alert setInformativeText:url];
    [alert setAlertStyle:NSInformationalAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        BOOL result = [ShadowsocksRunner openSSURL:[NSURL URLWithString:url]];
        if (!result) {
            alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:_L(OK)];
            [alert setMessageText:@"Invalid Rallets URL"];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert runModal];
        }
    }
}

- (void)stopProxy {
    [self toggleSystemProxy:NO];
    [serversMenu removeAllItems];
}

- (NSAlert*) sysNotifictaionAlert:(NSString*)primaryText informativeText:(NSString*)informativeText {
    _sysNotifictaionAlert = [[NSAlert alloc] init];
    [_sysNotifictaionAlert setMessageText:@"Rallets notification"];
    [_sysNotifictaionAlert addButtonWithTitle:primaryText];
    [_sysNotifictaionAlert addButtonWithTitle:_L(取消)];
    [_sysNotifictaionAlert setAlertStyle:NSInformationalAlertStyle];
    [_sysNotifictaionAlert setInformativeText:informativeText];
    return _sysNotifictaionAlert;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData");
    [self.receivedData appendData:data];
    NSLog(@"%ld",[self.receivedData length]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    NSLog(@"%ld",[self.receivedData length]);
    [HttpUtil processRalletsNotificationData:[NSJSONSerialization JSONObjectWithData:self.receivedData options:kNilOptions error:nil]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Post /rallets_notification results error");
}

- (void)updatePACFromGFWList {
    [manager GET:@"https://raw.githubusercontent.com/ralletstellar/gfwlist/master/gfwlist.txt" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Objective-C is bullshit
        NSData *data = responseObject;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *data2 = [[NSData alloc] initWithBase64Encoding:str];
        if (!data2) {
            NSLog(@"can't decode base64 string");
            return;
        }
        // Objective-C is bullshit
        NSString *str2 = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
        NSArray *lines = [str2 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSString *str3 = [[NSString alloc] initWithContentsOfFile:userRulePath encoding:NSUTF8StringEncoding error:nil];
        if (str3) {
            NSArray *rules = [str3 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            lines = [lines arrayByAddingObjectsFromArray:rules];
        }
        
        NSMutableArray *filtered = [[NSMutableArray alloc] init];
        for (NSString *line in lines) {
            if ([line length] > 0) {
                unichar s = [line characterAtIndex:0];
                if (s == '!' || s == '[') {
                    continue;
                }
                [filtered addObject:line];
            }
        }
        // Objective-C is bullshit
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtered options:NSJSONWritingPrettyPrinted error:&error];
        NSString *rules = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSData *data3 = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"abp" withExtension:@"js"]];
        NSString *template = [[NSString alloc] initWithData:data3 encoding:NSUTF8StringEncoding];
        NSString *result = [template stringByReplacingOccurrencesOfString:@"__RULES__" withString:rules];
        [[result dataUsingEncoding:NSUTF8StringEncoding] writeToFile:PACPath atomically:YES];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = _L(Routing List of Smart Mode Updated);
        [alert runModal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];
}
@end
