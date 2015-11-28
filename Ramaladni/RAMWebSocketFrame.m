//
//  RAMWebSocketFrame.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/14.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMWebSocketFrame.h"

@implementation RAMWebSocketFrame

- (void)dealloc
{
    free(self.maskingKey);
    self.maskingKey = NULL;
}

- (nonnull NSData*)data
{
    /*
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-------+-+-------------+-------------------------------+
     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
     | |1|2|3|       |K|             |                               |
     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
     |     Extended payload length continued, if payload len == 127  |
     + - - - - - - - - - - - - - - - +-------------------------------+
     |                               |Masking-key, if MASK set to 1  |
     +-------------------------------+-------------------------------+
     | Masking-key (continued)       |          Payload Data         |
     +-------------------------------- - - - - - - - - - - - - - - - +
     :                     Payload Data continued ...                :
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
     |                     Payload Data continued ...                |
     +---------------------------------------------------------------+
     */
    NSMutableData *data = [NSMutableData data];
    // FIN, RSV1, RSV2, RSV3 & opcode
    {
        uint8_t bytes = self.opcode;
        if(self.isFIN){
            bytes += 0b10000000;
        }
        if(self.enableRSV1){
            bytes += 0b01000000;
        }
        if(self.enableRSV2){
            bytes += 0b00100000;
        }
        if(self.enableRSV3){
            bytes += 0b00010000;
        }
        [data appendBytes:&bytes length:sizeof(bytes)];
    }
    // MASK & payload len
    {
        uint8_t bytes = 0;
        if(self.enableMask){
            bytes += 0b10000000;
        }
        if(self.payloadLength <= 125){
            bytes += self.payloadLength;
            [data appendBytes:&bytes length:sizeof(bytes)];
        }
        else if(125 < self.payloadLength && self.payloadLength <= UINT16_MAX){
            bytes += 126;
            [data appendBytes:&bytes length:sizeof(bytes)];
            uint16_t len = self.payloadLength;
            len = htons(len);
            [data appendBytes:&len length:sizeof(len)];
        }
        else if(UINT16_MAX < self.payloadLength && self.payloadLength <= UINT64_MAX){
            bytes += 127;
            [data appendBytes:&bytes length:sizeof(bytes)];
            uint64_t len = self.payloadLength;
            len = htonll(len);
            [data appendBytes:&len length:sizeof(len)];
        }
    }
    // Masking-Key
    {
        if(self.enableMask){
            [data appendBytes:self.maskingKey length:sizeof(uint8_t)*4];
        }
    }
    // Payload Data
    {
        uint8_t *payload = (uint8_t*)self.payload.bytes;
        NSUInteger len = self.payload.length;
        if(self.enableMask){
            for(NSUInteger i=0; i<len; ++i){
                payload[i] = payload[i] ^ self.maskingKey[i % 4];
            }
        }
        [data appendBytes:payload length:len];
    }
    return data;
}
@end
