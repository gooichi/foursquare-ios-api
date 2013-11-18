/*
 * Copyright (C) 2011-2013 Ba-Z Communication Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <MobileCoreServices/MobileCoreServices.h>
#import "BZFoursquareRequest.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if __has_feature(objc_arc)
#error This file does not support Objective-C Automatic Reference Counting (ARC)
#endif

#define kAPIv2BaseURL           @"https://api.foursquare.com/v2"
#define kTimeoutInterval        180.0

static NSString * _BZGetMIMETypeFromFilename(NSString *filename) {
    NSString *pathExtension = [filename pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)pathExtension, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return [NSMakeCollectable(MIMEType) autorelease];
}

static NSString * _BZGetMIMEBoundary() {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    [formatter setCalendar:[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease]];
    NSDate *date = [NSDate date];
    NSTimeInterval ti = [date timeIntervalSinceReferenceDate];
    NSInteger microSec = floor((ti - floor(ti)) * 1000000.0);
    return [NSString stringWithFormat:@"Multipart_%@%06ld", [formatter stringFromDate:date], (long)microSec];
}

@interface BZFoursquareRequest ()
@property(nonatomic,copy,readwrite) NSString *path;
@property(nonatomic,copy,readwrite) NSString *HTTPMethod;
@property(nonatomic,copy,readwrite) NSDictionary *parameters;
@property(nonatomic,retain,setter=_setDelegateQueue:) NSOperationQueue *_delegateQueue;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;
@property(nonatomic,copy,readwrite) NSDictionary *meta;
@property(nonatomic,copy,readwrite) NSArray *notifications;
@property(nonatomic,copy,readwrite) NSDictionary *response;
- (NSURLRequest *)requestForGETMethod;
- (NSURLRequest *)requestForPOSTMethod;
@end

@implementation BZFoursquareRequest

+ (NSURL *)baseURL {
    return [NSURL URLWithString:kAPIv2BaseURL];
}

- (id)init {
    return [self initWithPath:nil HTTPMethod:nil parameters:nil delegate:nil];
}

- (id)initWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate {
    self = [super init];
    if (self) {
        self.path = path;
        self.HTTPMethod = HTTPMethod ?: @"GET";
        self.parameters = parameters;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    self.path = nil;
    self.HTTPMethod = nil;
    self.parameters = nil;
    self.delegate = nil;
    self._delegateQueue = nil;
    self.connection = nil;
    self.responseData = nil;
    self.meta = nil;
    self.notifications = nil;
    self.response = nil;
    [super dealloc];
}

- (NSOperationQueue *)delegateQueue {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_5_1) {
        // 5.1.x or earlier
        // Note: NSURLConnection setDelegateQueue is broken on iOS 5.x.
        // See http://openradar.appspot.com/10529053.
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    } else {
        // 6.0 or later
        return __delegateQueue;
    }
}

- (void)setDelegateQueue:(NSOperationQueue *)delegateQueue {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_5_1) {
        // 5.1.x or earlier
        // Note: NSURLConnection setDelegateQueue is broken on iOS 5.x.
        // See http://openradar.appspot.com/10529053.
        [self doesNotRecognizeSelector:_cmd];
    } else {
        // 6.0 or later
        self._delegateQueue = delegateQueue;
    }
}

- (void)start {
    [self cancel];
    self.meta = nil;
    self.notifications = nil;
    self.response = nil;
    NSURLRequest *request;
    if ([_HTTPMethod isEqualToString:@"GET"]) {
        request = [self requestForGETMethod];
    } else if ([_HTTPMethod isEqualToString:@"POST"]) {
        request = [self requestForPOSTMethod];
    } else {
        NSAssert2(NO, @"*** %s: HTTP %@ method not supported", __PRETTY_FUNCTION__, _HTTPMethod);
        request = nil;
    }
    self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
    NSAssert1(_connection != nil, @"*** %s: connection is nil", __PRETTY_FUNCTION__);
    if (__delegateQueue) {
        [_connection setDelegateQueue:__delegateQueue];
    }
    [_connection start];
}

- (void)cancel {
    if (_connection) {
        [_connection cancel];
        self.connection = nil;
        self.responseData = nil;
    }
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
    if ([_delegate respondsToSelector:@selector(requestDidStartLoading:)]) {
        [_delegate requestDidStartLoading:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseString = [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];
    NSError *error = nil;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (!response) {
        goto bye;
    }
    self.meta = response[@"meta"];
    self.notifications = response[@"notifications"];
    self.response = response[@"response"];
    NSInteger code = [_meta[@"code"] integerValue];
    if (code / 100 != 2) {
        error = [NSError errorWithDomain:BZFoursquareErrorDomain code:code userInfo:_meta];
    }
bye:
    if (error) {
        if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
            [_delegate request:self didFailWithError:error];
        }
    } else {
        if ([_delegate respondsToSelector:@selector(requestDidFinishLoading:)]) {
            [_delegate requestDidFinishLoading:self];
        }
    }
    self.connection = nil;
    self.responseData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [_delegate request:self didFailWithError:error];
    }
    self.connection = nil;
    self.responseData = nil;
}

#pragma mark -
#pragma mark Anonymous category

- (NSURLRequest *)requestForGETMethod {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in _parameters) {
        NSString *value = _parameters[key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            } else {
                continue;
            }
        }
        CFStringRef escapedValue = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, CFSTR("%:/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
        NSMutableString *pair = [[key mutableCopy] autorelease];
        [pair appendString:@"="];
        [pair appendString:(NSString *)escapedValue];
        [pairs addObject:pair];
        CFRelease(escapedValue);
    }
    NSString *URLString = [kAPIv2BaseURL stringByAppendingPathComponent:_path];
    NSMutableString *mURLString = [[URLString mutableCopy] autorelease];
    [mURLString appendString:@"?"];
    [mURLString appendString:[pairs componentsJoinedByString:@"&"]];
    NSURL *URL = [NSURL URLWithString:mURLString];
    return [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kTimeoutInterval];
}

- (NSURLRequest *)requestForPOSTMethod {
    NSString *URLString = [kAPIv2BaseURL stringByAppendingPathComponent:_path];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kTimeoutInterval];
    [request setHTTPMethod:@"POST"];
    NSString *boundary = _BZGetMIMEBoundary();
    // header
    {
        NSString *value = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        NSString *field = @"Content-Type";
        [request setValue:value forHTTPHeaderField:field];
    }
    // body
    NSMutableData *body = [NSMutableData data];
    NSMutableDictionary *datas = [NSMutableDictionary dictionary];
    NSString *dashBoundary = [NSString stringWithFormat:@"--%@", boundary];
    NSData *dashBoundaryData = [dashBoundary dataUsingEncoding:NSUTF8StringEncoding];
    NSData *crlfData = [NSData dataWithBytes:"\r\n" length:2];
    for (NSString *key in _parameters) {
        NSString *value = _parameters[key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            } else {
                if ([value isKindOfClass:[NSData class]]) {
                    datas[key] = value;
                }
                continue;
            }
        }
        // dash-boundary CRLF
        [body appendData:dashBoundaryData];
        [body appendData:crlfData];
        // Content-Disposition header CRLF
        NSString *header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
        [body appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlfData];
        // Content-Type header CRLF
        header = @"Content-Type: text/plain; charset=utf-8";
        [body appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlfData];
        // empty line
        [body appendData:crlfData];
        // content
        NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
        [body appendData:valueData];
        // CRLF
        [body appendData:crlfData];
    }
    for (NSString *key in datas) {
        // dash-boundary CRLF
        [body appendData:dashBoundaryData];
        [body appendData:crlfData];
        // Content-Disposition header CRLF
        NSString *header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",[key stringByDeletingPathExtension], key];
        [body appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlfData];
        // Content-Type header CRLF
        header = [NSString stringWithFormat:@"Content-Type: %@", _BZGetMIMETypeFromFilename(key)];
        [body appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlfData];
        // Content-Transfer-Encoding header CRLF
        header = @"Content-Transfer-Encoding: binary";
        [body appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:crlfData];
        // empty line
        [body appendData:crlfData];
        // content
        [body appendData:datas[key]];
        // CRLF
        [body appendData:crlfData];
    }
    // dash-boundary "--" CRLF
    [body appendData:dashBoundaryData];
    [body appendBytes:"--" length:2];
    [body appendData:crlfData];
    [request setHTTPBody:body];
    return request;
}

@end

NSString * const BZFoursquareErrorDomain = @"BZFoursquareErrorDomain";
