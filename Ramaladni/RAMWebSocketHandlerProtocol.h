//
//  RAMWebSocketHandlerProtocol.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/16.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RAMWebServer;
@class RAMWebSocketConnection;
@class RAMWebSocketFrame;
typedef void (^RAMWebSocketHandlerBlocks)(RAMWebServer * _Nonnull server, RAMWebSocketConnection * _Nonnull conn, RAMWebSocketFrame * _Nonnull frame);

@protocol RAMWebSocketHandlerProtocol <NSObject>
@required
@property(nonnull, nonatomic, copy) RAMWebSocketHandlerBlocks blocks;
@end
