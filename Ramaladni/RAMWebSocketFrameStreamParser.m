//
//  RAMWebSocketFrameStreamParser.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/14.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMWebSocketFrameStreamParser.h"

#import "RAMWebSocketFrame.h"

@interface RAMWebSocketFrameStreamParser ()
@property(nonnull, nonatomic, strong) NSMutableData *data;
@end

@implementation RAMWebSocketFrameStreamParser

- (void)appendData:(nonnull NSData*)data
{
    [self.data appendData:data];
    uint8_t *bytes = (uint8_t*)self.data.bytes;
    NSUInteger len = self.data.length;
    NSUInteger pos = 0;
    for(;;){
        NSUInteger write = 0;
        RAMWebSocketFrame *frame = [self parseBytes:bytes + pos
                                             length:len - pos
                                              write:&write];
        if(frame != nil){
            [self.delegate parser:self parseFrame:frame];
            pos += write;
        } else {
            break;
        }
    }
    self.data = [NSMutableData dataWithBytes:bytes+pos length:len-pos];
}

#pragma mark - private
- (nullable instancetype)init
{
    self = [super init];
    if(self != nil){
        self.data = [NSMutableData data];
    }
    return self;
}

- (nullable RAMWebSocketFrame*)parseBytes:(uint8_t*)bytes length:(NSUInteger)length write:(NSUInteger*)write
{
    RAMWebSocketFrame *frame = [[RAMWebSocketFrame alloc] init];
    
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
    uint8_t *ptr = bytes;
    if(length - (ptr - bytes) < sizeof(uint8_t)){
        NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
        *write = 0;
        return nil;
    }
    
    frame.isFIN      = (*ptr & 0b10000000) != 0;
    frame.enableRSV1 = (*ptr & 0b01000000) != 0;
    frame.enableRSV2 = (*ptr & 0b00100000) != 0;
    frame.enableRSV3 = (*ptr & 0b00010000) != 0;
    frame.opcode     =  *ptr & 0b00001111;
    ptr++;
    
    if(length - (ptr - bytes) < sizeof(uint8_t)){
        NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
        *write = 0;
        return nil;
    }
    frame.enableMask       = (*ptr & 0b10000000) != 0;
    uint8_t payloadLength =  *ptr & 0b01111111;
    ptr++;
    if(payloadLength <= 125){
        frame.payloadLength = payloadLength;
    }
    else if(payloadLength == 126){
        if(length - (ptr - bytes) < sizeof(uint16_t)){
            NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
            *write = 0;
            return nil;
        }
        uint16_t *p = (uint16_t*)ptr;
        frame.payloadLength = ntohs(*p);
        ptr += 2;
    }
    else {    // payloadLength == 127 の場合
        if(length - (ptr - bytes) < sizeof(uint64_t)){
            NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
            *write = 0;
            return nil;
        }
        uint64_t *p = (uint64_t*)ptr;
        frame.payloadLength = ntohll(*p);
        ptr += 8;
    }
    
    frame.maskingKey = NULL;
    if(frame.enableMask){
        if(length - (ptr - bytes) < sizeof(uint8_t) * 4){
            NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
            *write = 0;
            return nil;
        }
        frame.maskingKey = malloc(sizeof(uint8_t)*4);
        frame.maskingKey[0] = *ptr; ++ptr;
        frame.maskingKey[1] = *ptr; ++ptr;
        frame.maskingKey[2] = *ptr; ++ptr;
        frame.maskingKey[3] = *ptr; ++ptr;
    }
    if(length - (ptr - bytes) < frame.payloadLength){
        NSLog(@"%s:%d, bytes not enough length", __FUNCTION__, __LINE__);
        *write = 0;
        return nil;
    }
    uint8_t *payload = ptr;
    if(frame.enableMask){
        for(int i=0; i<frame.payloadLength; ++i){
            payload[i] = payload[i] ^ frame.maskingKey[i % 4];
        }
    }
    frame.payload = [NSData dataWithBytes:payload length:frame.payloadLength];
    *write = frame.payloadLength + (payload - bytes);
    return frame;
}

@end
