//
//  RAMHTTPParser.m
//  Ramaladni
//
//  Created by KamedaKyosuke on 2015/11/10.
//  Copyright © 2015年 KamedaKyosuke. All rights reserved.
//

#import "RAMHTTPRequest.h"

#import "nodejs/http-parser/http_parser.h"

static int on_message_begin(http_parser *p);
static int on_url(http_parser *p, const char *at, size_t length);
static int on_status(http_parser *p, const char *at, size_t length);
static int on_header_field(http_parser *p, const char *at, size_t length);
static int on_header_value(http_parser *p, const char *at, size_t length);
static int on_headers_complete(http_parser *p);
static int on_body(http_parser *p, const char *at, size_t length);
static int on_message_complete(http_parser *p);
static int on_chunk_header(http_parser *p);
static int on_chunk_complete(http_parser *p);

static http_parser_settings settings = {
    .on_message_begin = on_message_begin,
    .on_url = on_url,
    .on_status = on_status,
    .on_header_field = on_header_field,
    .on_header_value = on_header_value,
    .on_headers_complete = on_headers_complete,
    .on_body = on_body,
    .on_message_complete = on_message_complete,
    /* When on_chunk_header is called, the current chunk length is stored
     * in parser->content_length.
     */
    .on_chunk_header = on_chunk_header,
    .on_chunk_complete = on_chunk_complete
};

@interface RAMHTTPRequest ()
@property(nonnull, nonatomic, copy, readwrite) NSString *method;
@property(nonatomic, assign, readwrite) unsigned int status;
@property(nonnull, nonatomic, copy, readwrite) NSString *url;
@property(nonnull, nonatomic, strong, readwrite) NSDictionary<NSString*, NSString*> *header;
@property(nonnull, nonatomic, copy, readwrite) NSString *body;

@property(nonatomic, assign, readwrite) unsigned int errorNumber;
@property(nullable, nonatomic, copy, readwrite) NSString *errorName;
@property(nullable, nonatomic, copy, readwrite) NSString *errorDescription;

@property(nonatomic, assign, readwrite)unsigned int upgrade;

// private
@property(nullable, nonatomic, strong) NSMutableArray<NSString*> *headerValue;
@property(nullable, nonatomic, strong) NSMutableArray<NSString*> *headerField;
@end

@implementation RAMHTTPRequest

+ (nonnull instancetype)parserWithData:(const char*)data length:(size_t)length
{
    RAMHTTPRequest *parser = [[RAMHTTPRequest alloc] init];;
    NSAssert(parser != nil, @"init: fail");
    [parser parse:data length:length];
    return parser;
}

#pragma mark - private
- (nullable instancetype)init
{
    self = [super init];
    if(self != nil){
        self.method = @"";
        self.url = @"";
        self.header = [NSMutableDictionary dictionary];
        self.body = @"";
        self.headerValue = [NSMutableArray array];
        self.headerField = [NSMutableArray array];
    }
    return self;
}

- (void)parse:(const char*)data length:(size_t)data_len;
{
    http_parser parser;
    parser.data = (__bridge void *)(self);
    http_parser_init(&parser, HTTP_REQUEST);
    http_parser_execute(&parser, &settings, data, data_len);
    self.status = parser.state;
    self.method = [[NSString alloc] initWithUTF8String:http_method_str(parser.method)];
    
    // error
    self.errorNumber = parser.http_errno;
    self.errorName = [[NSString alloc] initWithUTF8String:http_errno_name(self.errorNumber)];
    self.errorDescription = [[NSString alloc] initWithUTF8String:http_errno_description(self.errorNumber)];
    
    // upgrade
    self.upgrade = parser.upgrade;
}

@end

static int on_message_begin(http_parser *p)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return 0;
}

static int on_url(http_parser *p, const char *at, size_t length)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    RAMHTTPRequest *obj = (__bridge RAMHTTPRequest *)(p->data);
    obj.url = [[NSString alloc] initWithBytes:at length:length encoding:NSUTF8StringEncoding];
    return 0;
}
static int on_status(http_parser *p, const char *at, size_t length)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return 0;
}
static int on_header_field(http_parser *p, const char *at, size_t length)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    RAMHTTPRequest *obj = (__bridge RAMHTTPRequest *)(p->data);
    NSString *s = [[NSString alloc] initWithBytes:at length:length encoding:NSUTF8StringEncoding];
    [obj.headerValue addObject:[s lowercaseString]];
    return 0;
}
static int on_header_value(http_parser *p, const char *at, size_t length)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    RAMHTTPRequest *obj = (__bridge RAMHTTPRequest *)(p->data);
    [obj.headerField addObject:[[NSString alloc] initWithBytes:at length:length encoding:NSUTF8StringEncoding]];
    return 0;
}
static int on_headers_complete(http_parser *p)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    RAMHTTPRequest *obj = (__bridge RAMHTTPRequest *)(p->data);
    obj.header = [NSDictionary dictionaryWithObjects:obj.headerField forKeys:obj.headerValue];
    
    // 早めに解放しておこう。
    obj.headerField = nil;
    obj.headerValue = nil;
    return 0;
}
static int on_body(http_parser *p, const char *at, size_t length)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    RAMHTTPRequest *obj = (__bridge RAMHTTPRequest *)(p->data);
    obj.body = [[NSString alloc] initWithBytes:at length:length encoding:NSUTF8StringEncoding];
    return 0;
}
static int on_message_complete(http_parser *p)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return 0;
}
static int on_chunk_header(http_parser *p)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return 0;
}
static int on_chunk_complete(http_parser *p)
{
    // NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return 0;
}
