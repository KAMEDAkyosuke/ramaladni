//
//  RAMHTTPHandler.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/11.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMHTTPHandler.h"

#import "RAMHTTPRequest.h"

@interface RAMHTTPHandler ()
@property(nonnull, nonatomic, strong) NSRegularExpression *regexp;
@end

@implementation RAMHTTPHandler

+ (nonnull instancetype)handleWithPattern:(nonnull NSString*)pattern
                                   blocks:(nonnull RAMHTTPHandlerBlocks)blocks
{
    RAMHTTPHandler *handler = [[self.class alloc] initWithPattern:pattern
                                                           blocks:blocks];
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
        [self.next handleRequest:request complere:complete];
    }
}

#pragma mark - private
- (nullable instancetype)initWithPattern:(nonnull NSString*)pattern
                                  blocks:(nonnull RAMHTTPHandlerBlocks)blocks
{
    self = [super init];
    if(self != nil){
        self.blocks = blocks;
        NSError *error = nil;
        self.regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                options:0
                                                                  error:&error];
        NSAssert(error == nil, @"regularExpressionWithPattern:... fail:%@", [error debugDescription]);
    }
    return self;
}

@end
