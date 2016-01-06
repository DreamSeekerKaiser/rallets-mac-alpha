//
// Created by clowwindy on 14-2-27.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "ShadowsocksRunner.h"
#import "local.h"
#define _L(s) NSLocalizedString(@#s, nil)

@implementation ShadowsocksRunner {
}

+ (BOOL)settingsAreNotComplete {
    if ((![ShadowsocksRunner isUsingPublicServer]) && ([[NSUserDefaults standardUserDefaults] stringForKey:kRalletsIPKey] == nil ||
                                                       [[NSUserDefaults standardUserDefaults] stringForKey:kRalletsPortKey] == nil ||
                                                       [[NSUserDefaults standardUserDefaults] stringForKey:kRalletsPasswordKey] == nil)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)runProxy {
    static BOOL portOccupiedDialogShown = NO;

    if (![ShadowsocksRunner settingsAreNotComplete]) {
        int status = local_main();
        // == 2 为端口被占用
        if(status != 0 && !portOccupiedDialogShown){
            portOccupiedDialogShown = YES;
            NSString *title, *msg;
            if (status == 1) {
                title = _L(FAIL_LISTEN_PORT_TITLE);
                msg = _L(FAIL_LISTEN_PORT_MSG);
            } else if (status == 2){
                title = _L(PORT_OCCUPIED_TITLE);
                msg = _L(PORT_OCCUPIED_MSG);
            }
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:title];
            [alert setInformativeText:msg];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
        }
        return YES;
    } else {
#ifdef DEBUG
        NSLog(@"warning: settings are not complete");
#endif
        return NO;
    }
}

+ (void)reloadConfig {
    if (![ShadowsocksRunner settingsAreNotComplete]) {
        if ([ShadowsocksRunner isUsingPublicServer]) {
            set_config("106.186.124.182", "8911", "Shadowsocks", "aes-128-cfb");
            memcpy(shadowsocks_key, "\x45\xd1\xd9\x9e\xbd\xf5\x8c\x85\x34\x55\xdd\x65\x46\xcd\x06\xd3", 16);
        } else {
            NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kRalletsEncryptionKey];
            if (!v) {
                v = @"aes-256-cfb";
            }
            set_config([[[NSUserDefaults standardUserDefaults] stringForKey:kRalletsIPKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kRalletsPortKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kRalletsPasswordKey] cStringUsingEncoding:NSUTF8StringEncoding], [v cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
}

+ (BOOL)openSSURL:(NSURL *)url {
    if (!url.host) {
        return NO;
    }
    NSString *urlString = [url absoluteString];
    int i = 0;
    NSString *errorReason = nil;
    while(i < 2) {
        if (i == 1) {
            NSData *data = [[NSData alloc] initWithBase64Encoding:url.host];
            NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            urlString = decodedString;
        }
        i++;
        urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
        NSRange firstColonRange = [urlString rangeOfString:@":"];
        NSRange lastColonRange = [urlString rangeOfString:@":" options:NSBackwardsSearch];
        NSRange lastAtRange = [urlString rangeOfString:@"@" options:NSBackwardsSearch];
        if (firstColonRange.length == 0) {
            errorReason = @"colon not found";
            continue;
        }
        if (firstColonRange.location == lastColonRange.location) {
            errorReason = @"only one colon";
            continue;
        }
        if (lastAtRange.length == 0) {
            errorReason = @"at not found";
            continue;
        }
        if (!((firstColonRange.location < lastAtRange.location) && (lastAtRange.location < lastColonRange.location))) {
            errorReason = @"wrong position";
            continue;
        }
        NSString *method = [urlString substringWithRange:NSMakeRange(0, firstColonRange.location)];
        NSString *password = [urlString substringWithRange:NSMakeRange(firstColonRange.location + 1, lastAtRange.location - firstColonRange.location - 1)];
        NSString *IP = [urlString substringWithRange:NSMakeRange(lastAtRange.location + 1, lastColonRange.location - lastAtRange.location - 1)];
        NSString *port = [urlString substringWithRange:NSMakeRange(lastColonRange.location + 1, urlString.length - lastColonRange.location - 1)];
        [ShadowsocksRunner saveConfigForKey:kRalletsIPKey value:IP];
        [ShadowsocksRunner saveConfigForKey:kRalletsPortKey value:port];
        [ShadowsocksRunner saveConfigForKey:kRalletsPasswordKey value:password];
        [ShadowsocksRunner saveConfigForKey:kRalletsEncryptionKey value:method];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kRalletsUsePublicServer];
        [ShadowsocksRunner reloadConfig];
        return YES;
    }
    
    NSLog(@"%@", errorReason);
    return NO;
}

+(NSURL *)generateSSURL {
    if ([ShadowsocksRunner isUsingPublicServer]) {
        return nil;
    }
    NSString *parts = [NSString stringWithFormat:@"%@:%@@%@:%@",
                       [ShadowsocksRunner configForKey:kRalletsEncryptionKey],
                       [ShadowsocksRunner configForKey:kRalletsPasswordKey],
                       [ShadowsocksRunner configForKey:kRalletsIPKey],
                       [ShadowsocksRunner configForKey:kRalletsPortKey]];
    
    NSString *base64String = [[parts dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
    NSString *urlString = [NSString stringWithFormat:@"ss://%@", base64String];
    return [NSURL URLWithString:urlString];
}

+ (void)saveConfigForKey:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

+ (NSString *)configForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (void)setUsingPublicServer:(BOOL)use {
    [[NSUserDefaults standardUserDefaults] setBool:use forKey:kRalletsUsePublicServer];
    
}

+ (BOOL)isUsingPublicServer {
    NSNumber *usePublicServer = [[NSUserDefaults standardUserDefaults] objectForKey:kRalletsUsePublicServer];
    if (usePublicServer != nil) {
        return [usePublicServer boolValue];
    } else {
        return YES;
    }
}

@end
