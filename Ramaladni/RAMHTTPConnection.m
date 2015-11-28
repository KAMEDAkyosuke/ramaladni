//
//  RAMHTTPConnection.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMHTTPConnection.h"

#import "RAMHTTPRequest.h"
#import "RAMHTTPResponse.h"

@interface RAMHTTPConnection () < NSStreamDelegate >
@property(nullable, nonatomic, weak) NSRunLoop *runLoop;
@property(nullable, nonatomic, strong) NSData *data;
@end

@implementation RAMHTTPConnection

- (void)dealloc
{
    self.inputStream.delegate = nil;
    [self.inputStream close];
    [self.outputStream close];
}

+ (nonnull instancetype)connectionWithInputStream:(nonnull NSInputStream*)inputStream
                                     outputStream:(nonnull NSOutputStream*)outputStream
                                          runLoop:(nonnull NSRunLoop *)runLoop
{
    RAMHTTPConnection *conn = [self.class.alloc initWithInputStream:inputStream
                                                       outputStream:outputStream
                                                            runLoop:runLoop];
    NSAssert(conn != nil, @"initWithInputStream:outputStream:runloop: fail");
    return conn;
}

- (void)open
{
    [self.inputStream scheduleInRunLoop:self.runLoop
                                forMode:NSRunLoopCommonModes];
    [self.inputStream open];
    [self.outputStream scheduleInRunLoop:self.runLoop
                                 forMode:NSRunLoopCommonModes];
    [self.outputStream open];
}

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
                __weak typeof(self) wself = self;
                RAMHTTPRequest *req = [RAMHTTPRequest parserWithData:(char*)buf length:len];
                [self.delegate connection:self
                                  request:req
                                 complete:^(RAMHTTPResponse * _Nonnull res)
                 {
                     if([@"Upgrade" isEqualToString:res.header[@"Connection"]]){
                         [wself.delegate connection:self upgradeRequest:req response:res];
                     }
                     else {
                         if(NSStreamEventHasSpaceAvailable & self.outputStreamEvent){
                             [wself writeData:[res data]];
                             [wself close];
                         }
                         else {
                             wself.data = [res data];
                         }
                     }
                 }];
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
                [self close];
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

#pragma mark - private
- (nullable instancetype)initWithInputStream:(nonnull NSInputStream*)inputStream
                                outputStream:(nonnull NSOutputStream*)outputStream
                                     runLoop:(nonnull NSRunLoop*)runLoop
{
    self = [super init];
    if(self != nil){
        self.inputStream = inputStream;
        self.inputStream.delegate = self;
        self.outputStream = outputStream;
        self.outputStream.delegate = self;
        self.runLoop = runLoop;
    }
    return self;
}

- (void)writeData:(nonnull NSData*)data
{
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

@end
