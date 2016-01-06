//
//  Util.m
//  shadowsocks
//
//  Created by Jie Feng on 6/19/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//

#import "Util.h"

@implementation Util
+ (NSString*)currentVersion {
    static NSString* _currentVersion = nil;
    if (!_currentVersion) _currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return _currentVersion;
}
+ (BOOL)isRemoteVersionNewer:(NSString*) remoteVersion {
    if (!remoteVersion || (NSNull *)remoteVersion == [NSNull null]) {
        return false;
    }
    return [remoteVersion compare:[self currentVersion] options:NSNumericSearch] == NSOrderedDescending;
}
+ (NSString*) shortVersionStr {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (void) showStackTrace {
    NSLog(@"%@",[NSThread callStackSymbols]);
}

+ (NSColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    float red = ((rgbValue & 0xFF0000) >> 16)/255.0;
    float green = ((rgbValue & 0xFF00) >> 8)/255.0;
    float blue = (rgbValue & 0xFF)/255.0;
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0f];
}

+ (void) openUrl:(NSString *)url {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(url, nil)]];
}
+ (NSDictionary*) dictFromJsonString:(NSString *)jsonString {
    return [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
}
+ (NSString*) base64Encode:(NSString*)str {
    return [[str dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
}
+ (void) logFileHandler:(NSPipe*)pipe {
    NSFileHandle* file  = [pipe fileHandleForReading];
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"\n\
------------------------------logFileHandler---Begin\n\
%@\n\
------------------------------logFileHandler---End\n", string);
    }
}
@end

