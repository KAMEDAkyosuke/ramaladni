//
//  RAMHTTPParser.h
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RAMHTTPRequest : NSObject
@property(nonnull, nonatomic, copy, readonly) NSString *method;
@property(nonatomic, assign, readonly) unsigned int status;
@property(nonnull, nonatomic, copy, readonly) NSString *url;
@property(nonnull, nonatomic, strong, readonly) NSDictionary<NSString*, NSString*> *header;
@property(nonnull, nonatomic, copy, readonly) NSString *body;

@property(nonatomic, assign, readonly) unsigned int errorNumber;
@property(nullable, nonatomic, copy, readonly) NSString *errorName;
@property(nullable, nonatomic, copy, readonly) NSString *errorDescription;

@property(nonatomic, assign, readonly)unsigned int upgrade;

+ (nonnull instancetype)parserWithData:(nullable const char*)data length:(size_t)length;

@end
