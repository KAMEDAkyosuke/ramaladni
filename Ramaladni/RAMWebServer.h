//
//  RAMHTTPServer.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RAMHTTPHandler.h"
#import "RAMWebSocketHandlerProtocol.h"
#import "RAMConnectionProtocol.h"

typedef NS_ENUM(uint8_t, RAMWebServerStatus){
    RAMWebServerStatusNone = 0,
    RAMWebServerStatusStart,
    RAMWebServerStatusStop,
};

@class RAMWebServer;
@protocol RAMWebServerDelegate <NSObject>
@required
-(void)webServer:(nonnull RAMWebServer*)server updateStatus:(RAMWebServerStatus)status;
@end

@class RAMWebSocketConnection;
@interface RAMWebServer : NSObject
@property(nullable, nonatomic, weak)id<RAMWebServerDelegate> delegate;
@property(nullable, nonatomic, strong)id<RAMHTTPHandlerProtocol> httpHandler;
@property(nullable, nonatomic, strong)id<RAMWebSocketHandlerProtocol> webSocketHandler;

+ (nonnull instancetype)serverWithPort:(uint16_t)port;
+ (nonnull instancetype)serverWithPort:(uint16_t)port runLoop:(nonnull NSRunLoop*)runLoop;

- (nonnull NSArray<RAMWebSocketConnection*>*)webSocketConnections;
- (void)start;
- (void)stop;

@end
