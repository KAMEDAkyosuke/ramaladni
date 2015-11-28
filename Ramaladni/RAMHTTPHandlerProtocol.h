//
//  RAMHTTPHandlerProtocol.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/14.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RAMHTTPRequest;
@class RAMHTTPResponse;
typedef void (^RAMHTTPHandlerBlocks)(RAMHTTPRequest * _Nonnull req, void(^ _Nonnull complete)(RAMHTTPResponse * _Nonnull res));

@class RAMHTTPHandler;
@protocol RAMHTTPHandlerProtocol <NSObject>
@required
@property(nonnull, nonatomic, copy) RAMHTTPHandlerBlocks blocks;
@property(nullable, nonatomic, strong) id<RAMHTTPHandlerProtocol> next; // Chain of Responsibility パターン
- (void)handleRequest:(nonnull RAMHTTPRequest *)request complere:(nonnull void(^)(RAMHTTPResponse * _Nonnull res))complete;
@end
