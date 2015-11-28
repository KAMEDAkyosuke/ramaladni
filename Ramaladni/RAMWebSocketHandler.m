//
//  RAMWebSocketHandler.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/16.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMWebSocketHandler.h"

@implementation RAMWebSocketHandler 

+ (nonnull instancetype)handleWithBlocks:(nonnull RAMWebSocketHandlerBlocks)blocks
{
    RAMWebSocketHandler *handler = [[self.class alloc] initWithBlocks:blocks];
    NSAssert(handler != nil, @"initWithBlocks:... fail");
    return handler;
}

#pragma mark - private

- (nullable instancetype)initWithBlocks:(nonnull RAMWebSocketHandlerBlocks)blocks
{
    self = [super init];
    if(self != nil){
        self.blocks = blocks;
    }
    return self;
}

@end
