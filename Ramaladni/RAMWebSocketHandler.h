//
//  RAMWebSocketHandler.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/16.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RAMWebSocketHandlerProtocol.h"

@interface RAMWebSocketHandler : NSObject < RAMWebSocketHandlerProtocol >

+ (nonnull instancetype)handleWithBlocks:(nonnull RAMWebSocketHandlerBlocks)blocks;

#pragma mark - RAMWebSocketHandlerProtocol
@property(nonnull, nonatomic, copy) RAMWebSocketHandlerBlocks blocks;

@end
