//
//  Util.h
//  shadowsocks
//
//  Created by Jie Feng on 6/19/16.
//  Copyright © 2016 clowwindy. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface Util : NSObject
+ (NSString*)currentVersion;
+ (BOOL)isRemoteVersionNewer:(NSString*) remoteVersion;
+ (NSString*) shortVersionStr;
+ (void) showStackTrace;
+ (NSColor *)colorFromHexString:(NSString *)hexString;
+ (void) openUrl:(NSString *)url;
+ (NSDictionary*) dictFromJsonString:(NSString *)jsonString;
+ (NSString*) base64Encode:(NSString*)str;
+ (void) logFileHandler:(NSPipe*)file;
@end
