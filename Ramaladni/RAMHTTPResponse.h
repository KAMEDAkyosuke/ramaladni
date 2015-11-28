//
//  RAMHTTPResponse.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/11.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RAMHTTPResponse : NSObject
@property(nonatomic, assign) uint16_t statusCode;
@property(nonatomic, assign) uint8_t httpMajor;
@property(nonatomic, assign) uint8_t httpMinor;
@property(nonnull, nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *header;
@property(nonnull, nonatomic, strong) NSData *body;

- (nonnull NSData*)data;
@end
