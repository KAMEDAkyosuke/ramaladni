//
//  RAMWebSocketStreamManager.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/13.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RAMConnectionProtocol.h"
#import "RAMWebSocketHandlerProtocol.h"

@class RAMWebSocketConnection;
@class RAMWebSocketFrame;
@protocol RAMWebSocketConnectionDelegate <NSObject>
- (void)connection:(nonnull RAMWebSocketConnection *)connection
             frame:(nonnull RAMWebSocketFrame *)frame;
@end

@class RAMHTTPConnection;
@interface RAMWebSocketConnection : NSObject < RAMConnectionProtocol >

@property(nonatomic, weak)id< RAMConnectionDelegate, RAMWebSocketConnectionDelegate > delegate;

+ (nonnull instancetype)upgradeProtocolFrom:(nonnull RAMHTTPConnection*)httpConnection;

- (void)writeData:(nonnull NSData*)data;

#pragma mark - RAMConnectionProtocol
@property(nullable, nonatomic, strong) NSInputStream *inputStream;
@property(nullable, nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, assign) NSStreamEvent outputStreamEvent;
@end
