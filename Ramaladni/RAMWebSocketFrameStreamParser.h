//
//  RAMWebSocketFrameStreamParser.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/14.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RAMWebSocketFrameStreamParser;
@class RAMWebSocketFrame;
@protocol RAMWebSocketFrameStreamParserDelegate <NSObject>
@required
- (void)parser:(nonnull RAMWebSocketFrameStreamParser*)parser parseFrame:(nonnull RAMWebSocketFrame*)frame;
@end

@interface RAMWebSocketFrameStreamParser : NSObject
@property (nullable, nonatomic, weak) id<RAMWebSocketFrameStreamParserDelegate> delegate;
- (void)appendData:(nonnull NSData*)data;
@end
