//
//  RAMConnectionProtocol.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/13.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RAMConnectionProtocol <NSObject>
@property(nullable, nonatomic, strong) NSInputStream *inputStream;
@property(nullable, nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, assign) NSStreamEvent outputStreamEvent;

- (void)close;
@end

@protocol RAMConnectionDelegate <NSObject>
@required
- (void)connectionClose:(nonnull id<RAMConnectionProtocol>)connection;
@end
