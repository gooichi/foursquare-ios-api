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

#import "BZFoursquareRequest.h"

#define kAPIv2BaseURL           @"https://api.foursquare.com/v2"
#define kDefaultTimeoutInterval	180.0

NSString *isFinishedKey = @"isFinished";
NSString *isExecutingKey = @"isExecuting";

static NSString * _BZGetMIMEBoundary();
static NSString * _BZGetMIMETypeFromFilename(NSString *filename);

@interface BZFoursquareRequest ()
@property (nonatomic) BOOL isExecuting, isFinished;

- (NSURLRequest *)requestForGETMethod;
- (NSURLRequest *)requestForPOSTMethod;
@end

@implementation BZFoursquareRequest {
	BOOL _isExecuting, _isFinished;
}
@dynamic isFinished;
@dynamic isExecuting;

+ (NSURL *)baseURL {
    return [NSURL URLWithString:kAPIv2BaseURL];
}

- (id)init {
	self = [super init];
	if (self) {
		_interval = kDefaultTimeoutInterval;
	}
	return self;
}

- (id)initWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters {
    self = [self init];
    if (self) {
        _path = path;
        _HTTPMethod = HTTPMethod ?: @"GET";
        _parameters = parameters;
    }
    return self;
}

#pragma mark -
#pragma mark NSOperation

- (void)start {
	_isExecuting = YES;
	
	dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(q, ^{
		NSURLRequest *request = nil;
		
		if ([self.HTTPMethod isEqualToString:@"GET"]) {
			request = [self requestForGETMethod];
		} else if ([self.HTTPMethod isEqualToString:@"POST"]) {
			request = [self requestForPOSTMethod];
		} else {
			NSAssert2(NO, @"*** %s: HTTP %@ method not supported", __PRETTY_FUNCTION__, self.HTTPMethod);
		}
		
		NSError *error = nil;
		
		_responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
		
		_error = error;
		
		self.isExecuting = NO;
		self.isFinished = YES;
	});
}

#pragma mark -
#pragma mark Properties

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return _isExecuting;
}

- (void)setIsExecuting:(BOOL)executing {
	[self willChangeValueForKey:isExecutingKey];
	_isExecuting = executing;
	[self didChangeValueForKey:isExecutingKey];
}

- (BOOL)isFinished {
	return _isFinished;
}

- (void)setIsFinished:(BOOL)finished {
	[self willChangeValueForKey:isFinishedKey];
	_isFinished = finished;
	[self didChangeValueForKey:isFinishedKey];
}

#pragma mark -
#pragma mark Anonymous category

- (NSURLRequest *)requestForGETMethod {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in self.parameters) {
        NSString *value = [self.parameters objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            } else {
                continue;
            }
        }
        NSString *escapedValue = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, CFSTR("%:/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8));
        NSMutableString *pair = [key mutableCopy];
        [pair appendString:@"="];
        [pair appendString:escapedValue];
        [pairs addObject:pair];
    }
	
    NSString *URLString = [kAPIv2BaseURL stringByAppendingPathComponent:self.path];
    NSMutableString *mURLString = [URLString mutableCopy];
    [mURLString appendString:@"?"];
    [mURLString appendString:[pairs componentsJoinedByString:@"&"]];
    NSURL *URL = [NSURL URLWithString:mURLString];
    return [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.interval];
}

- (NSURLRequest *)requestForPOSTMethod {
    NSString *URLString = [kAPIv2BaseURL stringByAppendingPathComponent:self.path];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.interval];
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
    for (NSString *key in self.parameters) {
        NSString *value = [self.parameters objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            } else {
                if ([value isKindOfClass:[NSData class]]) {
                    [datas setObject:value forKey:key];
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
        [body appendData:[datas objectForKey:key]];
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


static NSString * _BZGetMIMETypeFromFilename(NSString *filename) {
    NSString *pathExtension = [filename pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
    NSString *MIMEType = (__bridge NSString *)(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    CFRelease(UTI);
    return MIMEType;
}

static NSString * _BZGetMIMEBoundary() {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    [formatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
    NSDate *date = [NSDate date];
    NSTimeInterval ti = [date timeIntervalSinceReferenceDate];
    NSInteger microSec = floor((ti - floor(ti)) * 1000000.0);
    return [NSString stringWithFormat:@"Multipart_%@%06ld", [formatter stringFromDate:date], (long)microSec];
}
