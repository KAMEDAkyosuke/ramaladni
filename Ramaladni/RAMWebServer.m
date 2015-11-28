//
//  RAMHTTPServer.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMWebServer.h"

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

#import "RAMConnectionProtocol.h"
#import "RAMHTTPConnection.h"
#import "RAMHTTPRequest.h"
#import "RAMHTTPHandler.h"
#import "RAMWebSocketConnection.h"

static void MyCFSocketAcceptCallBack(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info );

@interface RAMWebServer () < RAMConnectionDelegate, RAMHTTPConnectionDelegate, RAMWebSocketConnectionDelegate >
@property(nonatomic, assign) uint16_t port;
@property(nonatomic, weak) NSRunLoop *runLoop;

@property(nonatomic, assign) RAMWebServerStatus status;
@property(nonnull, nonatomic) dispatch_queue_t statusMutex;

@property(nonnull, nonatomic, strong) NSMutableArray< id<RAMConnectionProtocol> > *connections;

@end

@implementation RAMWebServer

+ (nonnull instancetype)serverWithPort:(uint16_t)port
{
    RAMWebServer *server = [self.class.alloc initWithPort:port];
    NSAssert(server != nil, @"initWithPort:... fail");
    return server;
}

+ (nonnull instancetype)serverWithPort:(uint16_t)port runLoop:(nonnull NSRunLoop*)runLoop
{
    RAMWebServer *server = [self.class.alloc initWithPort:port runLoop:runLoop];
    NSAssert(server != nil, @"initWithPort:runLoop:... fail");
    return server;
}

- (nonnull NSArray<RAMWebSocketConnection*>*)webSocketConnections
{
    NSPredicate *isWebSocketConnectionInstance
    = [NSPredicate predicateWithBlock:^BOOL(id<RAMConnectionProtocol> _Nonnull conn, NSDictionary<NSString *,id> * _Nullable bindings)
    {
        return [conn isKindOfClass:[RAMWebSocketConnection class]];
    }];
    return [self.connections filteredArrayUsingPredicate:isWebSocketConnectionInstance];
}

- (void)start
{
    __weak typeof(self) wself = self;
    __block BOOL alreadyStated;
    dispatch_sync(self.statusMutex, ^{
        alreadyStated = wself.status == RAMWebServerStatusStart;
        wself.status = RAMWebServerStatusStart;
    });
    if(alreadyStated){
        return;
    }
    
    CFSocketContext context = {
        .version = 0,
        .info = (__bridge void *)(self),
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };
    CFSocketRef myipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                                              PF_INET,
                                              SOCK_STREAM,
                                              IPPROTO_TCP,
                                              kCFSocketAcceptCallBack,
                                              MyCFSocketAcceptCallBack,
                                              &context);
    NSAssert(myipv4cfsock != NULL, @"CFSocketCreate fail:");
    
    CFSocketNativeHandle socketNativeHandle = CFSocketGetNative(myipv4cfsock);
    const int enable = 1;
    int r = setsockopt(socketNativeHandle, SOL_SOCKET, SO_REUSEPORT, &enable ,sizeof(enable));
    NSAssert(r == 0, @"setsockopt fail %s", strerror(errno));
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; /* Address family */
    sin.sin_port = htons(self.port); /* Or a specific port */
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault,
                                    (UInt8*)&sin,
                                    sizeof(sin));
    NSAssert(sincfd != NULL, @"CFDataCreate fail:");

    CFSocketError e;
    __darwin_time_t waitSec = 0;
    static const __darwin_time_t kMaxWaitSec = 64;
    NSLog(@"CFSocketSetAddress try");
    do {
        NSLog(@"waiting... %@sec", @(waitSec));
        struct timeval tv;
        tv.tv_sec  = waitSec;
        tv.tv_usec = 0;
        select(0, NULL, NULL, NULL, &tv);
        e = CFSocketSetAddress(myipv4cfsock, sincfd);
        // NSAssert(e == kCFSocketSuccess, @"CFSocketSetAddress fail: %@", @(e));
        waitSec = waitSec == 0 ? 1 : waitSec * 2;
        waitSec = kMaxWaitSec < waitSec ? kMaxWaitSec : waitSec;
    } while (e != kCFSocketSuccess);
    NSLog(@"CFSocketSetAddress done");
    
    CFRelease(sincfd);
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);
    CFRunLoopAddSource([self.runLoop getCFRunLoop],
                       socketsource,
                       kCFRunLoopDefaultMode);
    
    [self.delegate webServer:self updateStatus:self.status];
    __block RAMWebServerStatus status;
    while (true) {
        dispatch_sync(self.statusMutex, ^{
            status = wself.status;
        });
        if(status != RAMWebServerStatusStart){
            break;
        }
        @autoreleasepool {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0/60.0, false);
        }
    }
    CFRunLoopRemoveSource([self.runLoop getCFRunLoop],
                          socketsource,
                          kCFRunLoopDefaultMode);
    CFRelease(socketsource);
    CFRelease(myipv4cfsock);
    for(id<RAMConnectionProtocol> conn in self.connections){
        [conn close];
    }
    [self.delegate webServer:self updateStatus:self.status];
}

- (void)stop
{
    dispatch_sync(self.statusMutex, ^{
        self.status = RAMWebServerStatusStop;
    });
}

#pragma mark - RAMHTTPConnectionDelegate
- (void)connection:(nonnull RAMHTTPConnection *)connection
           request:(nonnull RAMHTTPRequest *)request
          complete:(void(^ _Nonnull)(RAMHTTPResponse * _Nonnull response))complete;
{
    id<RAMHTTPHandlerProtocol> handler = self.httpHandler;
    [handler handleRequest:request complere:complete];
}

- (void)connection:(nonnull RAMHTTPConnection *)connection
    upgradeRequest:(nonnull RAMHTTPRequest *)request
          response:(nonnull RAMHTTPResponse *)response
{
    NSString *protocol = request.header[@"upgrade"];
    NSAssert([@"websocket" isEqualToString:protocol],
             @"protocol expect : `websocket`\n"
             @"protocol actual : `%@`", protocol);
    if([@"websocket" isEqualToString:protocol]){
        RAMWebSocketConnection *sm = [RAMWebSocketConnection upgradeProtocolFrom:connection];
        [self.connections removeObject:connection];
        [self.connections addObject:sm];
        [sm writeData:[response data]];
    }
}

#pragma mark - RAMWebSocketConnectionDelegate
- (void)connection:(RAMWebSocketConnection *)connection frame:(RAMWebSocketFrame *)frame
{
    self.webSocketHandler.blocks(self, connection, frame);
}

#pragma mark - RAMConnectionDelegate
- (void)connectionClose:(nonnull id<RAMConnectionProtocol>)connection
{
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    [self.connections removeObject:connection];
}

#pragma mark - private
- (nullable instancetype)initWithPort:(uint16_t)port
{
    self = [super init];
    if(self != nil){
        [self commonInitWithPort:port runLoop:[NSRunLoop mainRunLoop]];
    }
    return self;
}

- (nullable instancetype)initWithPort:(uint16_t)port runLoop:(nonnull NSRunLoop*)runLoop
{
    self = [super init];
    if(self != nil){
        [self commonInitWithPort:port runLoop:runLoop];
    }
    return self;
}

- (void)commonInitWithPort:(uint16_t)port runLoop:(nonnull NSRunLoop*)runLoop
{
    self.port = port;
    self.runLoop = runLoop;
    self.status = RAMWebServerStatusNone;
    self.statusMutex = dispatch_queue_create("org.organlounge.Ramaladni.RAMWebServer.statusMutex", DISPATCH_QUEUE_SERIAL);
    self.connections = [NSMutableArray array];
}

@end

static void MyCFSocketAcceptCallBack(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info )
{
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSCAssert(CFSocketIsValid(s), @"CFSocketIsValid == NO");
    
    switch (callbackType) {
        case kCFSocketAcceptCallBack:
        {
            NSLog(@"kCFSocketAcceptCallBack!!");
            RAMWebServer *obj = (__bridge RAMWebServer *)(info);
            NSLog(@"obj = %@", obj.debugDescription);
            CFSocketNativeHandle handle = *(CFSocketNativeHandle*)data;
            NSLog(@"accepted. (s = %p, handle=%d)", socket, handle);
            
            int flags;
            flags = fcntl(handle,F_GETFL);
            int r = fcntl(handle, F_SETFL, flags | O_NONBLOCK);
            NSCAssert(r == 0, @"fcntl fail %s", strerror(errno));
            
            CFReadStreamRef readStream = NULL;
            CFWriteStreamRef writeStream = NULL;
            
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &readStream, &writeStream);
            
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            
            NSInputStream *inputStream = (__bridge NSInputStream *)readStream;
            NSOutputStream *outputStream = (__bridge NSOutputStream *)writeStream;
            RAMHTTPConnection *connection = [RAMHTTPConnection connectionWithInputStream:inputStream
                                                                            outputStream:outputStream
                                                                                 runLoop:obj.runLoop];
            connection.delegate = obj;
            [obj.connections addObject:connection];
            [connection open];
            CFRelease(readStream);
            CFRelease(writeStream);
            break;
        }
        default:
            NSCAssert(NO, @"invalid callbackType : %@", @(callbackType));
            break;
    }
}

