//
//  RAMWebSocketConnection.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/13.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMWebSocketConnection.h"

#import "RAMHTTPConnection.h"
#import "RAMWebSocketFrameStreamParser.h"
#import "RAMWebSocketFrame.h"

@interface RAMWebSocketConnection () < NSStreamDelegate, RAMWebSocketFrameStreamParserDelegate >
@property(nonnull, nonatomic, strong) RAMWebSocketFrameStreamParser *parser;
@property(nullable, nonatomic, strong) NSData *data;
@end

@implementation RAMWebSocketConnection

+ (nonnull instancetype)upgradeProtocolFrom:(nonnull RAMHTTPConnection*)httpConnection
{
    RAMWebSocketConnection *conn = [self.class.alloc initWithHTTPConnection:httpConnection];
    return conn;
}

- (void)writeData:(nonnull NSData*)data
{
    if(NSStreamEventHasSpaceAvailable & self.outputStreamEvent){
        const uint8_t *bytes = data.bytes;
        NSInteger offset = 0;
        NSInteger len = data.length;
        while (YES) {
            NSInteger l = [self.outputStream write:bytes + offset maxLength:len];
            if(l == len){
                break;
            }
            offset += l;
            len -= l;
        }
    }
    else {
        self.data = data;
    }
}

#pragma mark - RAMConnectionProtocol
- (void)close
{
    [self.inputStream close];
    [self.outputStream close];
    [self.delegate connectionClose:self];
}

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSAssert(aStream == self.inputStream || aStream == self.outputStream, @"invalid stream : %@", aStream.debugDescription);
    
    if(aStream == self.inputStream){
        NSLog(@"input stream!!");
        if(eventCode == NSStreamEventNone){
            NSLog(@"NSStreamEventNone");
        }
        if(eventCode & NSStreamEventOpenCompleted){
            NSLog(@"NSStreamEventOpenCompleted");
        }
        if(eventCode & NSStreamEventHasBytesAvailable){
            NSLog(@"NSStreamEventHasBytesAvailable");
            static const NSUInteger kLength = 1024 * 8;
            uint8_t buf[kLength];
            NSInteger len = [self.inputStream read:buf maxLength:kLength];
            if(len == 0){    // EOF
                // TODO:
            }
            else if(len < 0){    // fail
                // TODO:
            }
            else {
                NSData *data = [NSData dataWithBytes:buf length:len];
                [self.parser appendData:data];
            }
        }
        if(eventCode & NSStreamEventHasSpaceAvailable){
            NSLog(@"NSStreamEventHasSpaceAvailable");
        }
        if(eventCode & NSStreamEventErrorOccurred){
            NSLog(@"NSStreamEventErrorOccurred");
            [self close];
        }
        if(eventCode & NSStreamEventEndEncountered){
            NSLog(@"NSStreamEventEndEncountered");
            [self close];
        }
    }
    else if(aStream == self.outputStream){
        NSLog(@"output stream!!");
        self.outputStreamEvent = eventCode;
        if(eventCode == NSStreamEventNone){
            NSLog(@"NSStreamEventNone");
        }
        if(eventCode & NSStreamEventOpenCompleted){
            NSLog(@"NSStreamEventOpenCompleted");
        }
        if(eventCode & NSStreamEventHasBytesAvailable){
            NSLog(@"NSStreamEventHasBytesAvailable");
        }
        if(eventCode & NSStreamEventHasSpaceAvailable){
            NSLog(@"NSStreamEventHasSpaceAvailable");
            if(self.data != nil){
                [self writeData:self.data];
                self.data = nil;
            }
        }
        if(eventCode & NSStreamEventErrorOccurred){
            NSLog(@"NSStreamEventErrorOccurred");
            [self close];
        }
        if(eventCode & NSStreamEventEndEncountered){
            NSLog(@"NSStreamEventEndEncountered");
            [self close];
        }
    }
}

#pragma mark - RAMWebSocketFrameStreamParserDelegate
- (void)parser:(nonnull RAMWebSocketFrameStreamParser*)parser parseFrame:(nonnull RAMWebSocketFrame*)frame
{
    switch (frame.opcode) {
        case RAMWebSocketOpcodeText: case RAMWebSocketOpcodeBinary:
        {
            [self.delegate connection:self frame:frame];
        }
            break;
        case RAMWebSocketOpcodeConnectionClose:
        {
            NSLog(@"close");
            [self close];
        }
            break;
        case RAMWebSocketOpcodePing:
        {
            NSLog(@"ping");
            frame.opcode = RAMWebSocketOpcodePong;
            frame.enableMask = NO;
            [self writeData:[frame data]];
        }
            break;
        default:
            NSAssert(NO, @"invalid opcode : %@", @(frame.opcode));
            break;
    }
}

#pragma mark - private
- (nullable instancetype)initWithHTTPConnection:(nonnull RAMHTTPConnection*)httpConnection
{
    self = [super init];
    if(self != nil){
        self.inputStream = httpConnection.inputStream;
        self.inputStream.delegate = self;
        httpConnection.inputStream = nil;
        self.outputStream = httpConnection.outputStream;
        self.outputStream.delegate = self;
        httpConnection.outputStream = nil;
        self.outputStreamEvent = httpConnection.outputStreamEvent;
        self.delegate = (id< RAMConnectionDelegate, RAMWebSocketConnectionDelegate >)httpConnection.delegate;
        httpConnection.delegate = nil;
        
        self.parser = [[RAMWebSocketFrameStreamParser alloc] init];
        self.parser.delegate = self;
    }
    return self;
}

@end
