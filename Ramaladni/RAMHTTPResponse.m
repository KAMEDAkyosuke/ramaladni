//
//  RAMHTTPResponse.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/11.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMHTTPResponse.h"

@implementation RAMHTTPResponse

- (nullable instancetype)init
{
    self = [super init];
    if(self != nil){
        self.statusCode = 200;
        self.httpMajor = 1;
        self.httpMinor = 1;
        self.header = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nonnull NSData*)data
{
    NSString *s = [NSString stringWithFormat:
                   @"HTTP/%@.%@ %@ %@\r\n"    // HTTP/1.1 200 OK
                   @"%@"                      // text/html; charset=UTF-8 とかとか
                   @"\r\n",                   // body との改行
                   @(self.httpMajor), @(self.httpMinor), @(self.statusCode), [self statusCodeString:self.statusCode],
                   [self headerString:self.header]];
    
    NSMutableData *data = [NSMutableData dataWithData:[s dataUsingEncoding:NSUTF8StringEncoding]];
    if(self.body != nil){
        [data appendData:self.body];
    }
    return data;
}

#pragma mark - private
- (nonnull NSString*)statusCodeString:(uint16_t)statusCode
{
    NSString *str = nil;
    switch (statusCode) {
        case 101:
            str = @"Switching Protocols"; break;
        case 200:
            str = @"OK"; break;
        case 404:
            str = @"Not Found"; break;
        default:
            NSAssert(NO, @"invalid statusCode : %@", @(statusCode));
            break;
    }
    return str;
}

- (nonnull NSString*)headerString:(NSDictionary*)header
{
    NSMutableString *s = [NSMutableString string];
    
    for(NSString *key in header){
        [s appendFormat:@"%@: %@\r\n", key, header[key]];
    }
    return s;
}

@end
