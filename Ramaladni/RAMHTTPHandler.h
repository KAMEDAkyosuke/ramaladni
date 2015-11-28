//
//  RAMHTTPHandler.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/11.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RAMHTTPHandlerProtocol.h"

@interface RAMHTTPHandler : NSObject < RAMHTTPHandlerProtocol >

+ (nonnull instancetype)handleWithPattern:(nonnull NSString*)pattern
                                   blocks:(nonnull RAMHTTPHandlerBlocks)blocks;

#pragma mark - RAMHTTPHandlerProtocol
@property(nonnull, nonatomic, copy) RAMHTTPHandlerBlocks blocks;
@property(nullable, nonatomic, strong) id<RAMHTTPHandlerProtocol> next;

@end
