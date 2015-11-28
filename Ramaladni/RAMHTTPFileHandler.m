//
//  RAMHTTPFileHandler.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/11.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMHTTPFileHandler.h"

#import "RAMHTTPRequest.h"
#import "RAMHTTPResponse.h"

@interface RAMHTTPFileHandler ()
@property(nonnull, nonatomic, strong) NSRegularExpression *regexp;
@property(nonnull, nonatomic, copy) NSString *contentType;
@end

@implementation RAMHTTPFileHandler

+ (nonnull instancetype)handleWithPattern:(nonnull NSString*)pattern
                              contentType:(nonnull NSString*)contentType;
{
    RAMHTTPFileHandler *handler = [[self.class alloc] initWithPattern:pattern
                                                          contentType:contentType];
    NSAssert(handler != nil, @"initWithPattern:... fail");
    return handler;
}

#pragma mark - RAMHTTPHandlerProtocol
- (void)handleRequest:(nonnull RAMHTTPRequest *)request complere:(nonnull void(^)(RAMHTTPResponse * _Nonnull res))complete
{
    NSRange rangeOfFirstMatch = [self.regexp rangeOfFirstMatchInString:request.url
                                                               options:0
                                                                 range:NSMakeRange(0, [request.url length])];
    if(!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))){
        self.blocks(request, complete);
    }
    else {
        NSAssert(self.next != nil, @"self.next is nil!!");
        [self.next handleRequest:request complere:complete];
    }
}

#pragma mark - private
- (nullable instancetype)initWithPattern:(nonnull NSString*)pattern
                             contentType:(nonnull NSString*)contentType
{
    self = [super init];
    if(self != nil){
        NSError *error = nil;
        self.regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                options:0
                                                                  error:&error];
        NSAssert(error == nil, @"regularExpressionWithPattern:... fail:%@", [error debugDescription]);
        self.contentType = contentType;
        
        __weak typeof(self) wself = self;
        self.blocks = ^(RAMHTTPRequest * _Nonnull req, void (^ _Nonnull complete)(RAMHTTPResponse * _Nonnull res))
        {
            RAMHTTPResponse *res = [[RAMHTTPResponse alloc] init];
            res.header[@"content-type"] = wself.contentType;
            NSString *path = [[NSBundle mainBundle] pathForResource:req.url ofType:nil];
            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:&error];
            NSCAssert(error == nil, @"stringWithContentsOfFile:... fail: %@", error.debugDescription);
            res.body = data;
            complete(res);
        };
    }
    return self;
}

@end
