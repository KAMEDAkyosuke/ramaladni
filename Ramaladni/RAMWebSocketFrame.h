//
//  RAMWebSocketFrame.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/14.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, RAMWebSocketOpcode){
    RAMWebSocketOpcodeContinuation    = 0x0,
    RAMWebSocketOpcodeText            = 0x1,
    RAMWebSocketOpcodeBinary          = 0x2,
    // 0x3 - 0x7 reserved for further
    RAMWebSocketOpcodeConnectionClose = 0x8,
    RAMWebSocketOpcodePing            = 0x9,
    RAMWebSocketOpcodePong            = 0xA,
    // 0xB - 0xF reserved for further
};

@interface RAMWebSocketFrame : NSObject
@property(nonatomic, assign) BOOL isFIN;
@property(nonatomic, assign) BOOL enableRSV1;    // not support yet
@property(nonatomic, assign) BOOL enableRSV2;    // not support yet
@property(nonatomic, assign) BOOL enableRSV3;    // not support yet
@property(nonatomic, assign) RAMWebSocketOpcode opcode;
@property(nonatomic, assign) BOOL enableMask;
@property(nonatomic, assign) uint64_t payloadLength;
@property(nullable, nonatomic, assign) uint8_t *maskingKey;    // uint8_t[4]
@property(nullable, nonatomic, strong) NSData *payload;

- (nonnull NSData*)data;
@end
