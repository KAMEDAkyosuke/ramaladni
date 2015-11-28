//
//  RAMHTTPConnection.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RAMConnectionProtocol.h"
#import "RAMHTTPRequest.h"
#import "RAMHTTPResponse.h"

@class RAMHTTPConnection;
@protocol RAMHTTPConnectionDelegate <NSObject>
- (void)connection:(nonnull RAMHTTPConnection *)connection
           request:(nonnull RAMHTTPRequest *)request
          complete:(void(^ _Nonnull)(RAMHTTPResponse * _Nonnull response))complete;
- (void)connection:(nonnull RAMHTTPConnection *)connection
    upgradeRequest:(nonnull RAMHTTPRequest *)request
          response:(nonnull RAMHTTPResponse *)response;
@end

@interface RAMHTTPConnection : NSObject < RAMConnectionProtocol >

@property(nonatomic, weak)id<RAMConnectionDelegate, RAMHTTPConnectionDelegate> delegate;

+ (nonnull instancetype)connectionWithInputStream:(nonnull NSInputStream*)inputStream
                                     outputStream:(nonnull NSOutputStream*)outputStream
                                          runLoop:(nonnull NSRunLoop*)runLoop;
- (void)open;

#pragma mark - RAMConnectionProtocol
@property(nullable, nonatomic, strong) NSInputStream *inputStream;
@property(nullable, nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, assign) NSStreamEvent outputStreamEvent;

@end
