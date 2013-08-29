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

#import "BZFoursquare.h"
#import "BZFoursquareResponse+Private.h"

#define kAuthorizeBaseURL       @"https://foursquare.com/oauth2/authorize"

@implementation BZFoursquare

- (id)init {
	self = [super init];
	if (self) {
		_requestQueue = NSOperationQueue.new;
		self.requestQueue.maxConcurrentOperationCount = 1;
	}
	return self;
}

- (id)initWithClientID:(NSString *)clientID callbackURL:(NSString *)callbackURL {
    NSParameterAssert(clientID != nil && callbackURL != nil);
    self = [self init];
    if (self) {
        _clientID = clientID;
        _callbackURL = callbackURL;
    }
    return self;
}

- (void)dealloc {
    self.sessionDelegate = nil;
}

- (BOOL)startAuthorization {
    NSMutableArray *pairs = [NSMutableArray array];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:self.clientID, @"client_id", @"token", @"response_type", self.callbackURL, @"redirect_uri", nil];
	
    for (NSString *key in parameters) {
        NSString *value = [parameters objectForKey:key];
        NSString *escapedValue = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, CFSTR("%:/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8));
		
        NSMutableString *pair = [key mutableCopy];
        [pair appendString:@"="];
        [pair appendString:escapedValue];
        [pairs addObject:pair];
    }
    NSString *URLString = kAuthorizeBaseURL;
    NSMutableString *mURLString = [URLString mutableCopy];
    [mURLString appendString:@"?"];
    [mURLString appendString:[pairs componentsJoinedByString:@"&"]];
    NSURL *URL = [NSURL URLWithString:mURLString];
    BOOL result = [[UIApplication sharedApplication] openURL:URL];
    if (!result) {
        NSLog(@"*** %s: cannot open url \"%@\"", __PRETTY_FUNCTION__, URL);
    }
    return result;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if (!self.callbackURL || [[url absoluteString] rangeOfString:self.callbackURL options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].length == 0) {
        return NO;
    }
    NSString *fragment = [url fragment];
    NSArray *pairs = [fragment componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *key = [kv objectAtIndex:0];
        NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [parameters setObject:val forKey:key];
    }
	
    self.accessToken = [parameters objectForKey:@"access_token"];
    if (self.accessToken) {
        if ([self.sessionDelegate respondsToSelector:@selector(foursquareDidAuthorize:)]) {
            [self.sessionDelegate foursquareDidAuthorize:self];
        }
    } else {
        if ([self.sessionDelegate respondsToSelector:@selector(foursquareDidNotAuthorize:error:)]) {
            [self.sessionDelegate foursquareDidNotAuthorize:self error:parameters];
        }
    }
    return YES;
}

- (void)invalidateSession {
    self.accessToken = nil;
}

- (BOOL)isSessionValid {
    return (self.accessToken != nil);
}

- (BZFoursquareRequest *)requestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters completionHandler:(ResponseHandler)handler {
	
    NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if ([self isSessionValid]) {
        [mDict setObject:self.accessToken forKey:@"oauth_token"];
    }
    if (self.version) {
        [mDict setObject:self.version forKey:@"v"];
    }
    if (self.locale) {
        [mDict setObject:self.locale forKey:@"locale"];
    }
	
	BZFoursquareRequest *request = [[BZFoursquareRequest alloc] initWithPath:path HTTPMethod:HTTPMethod parameters:mDict];
	
	__weak BZFoursquareRequest *localRequest = request;
	request.completionBlock = ^{
		[self handleResponseForRequest:localRequest clientHandler:handler];
	};
	
	[self.requestQueue addOperation:request];
	
    return request;
}

- (BZFoursquareRequest *)userlessRequestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters completionHandler:(ResponseHandler)handler {
	
    NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [mDict setObject:self.clientID forKey:@"client_id"];
	
    if (self.clientSecret) {
        [mDict setObject:self.clientSecret forKey:@"client_secret"];
    }
    if (self.version) {
        [mDict setObject:self.version forKey:@"v"];
    }
    if (self.locale) {
        [mDict setObject:self.locale forKey:@"locale"];
    }
	
    BZFoursquareRequest *request = [[BZFoursquareRequest alloc] initWithPath:path HTTPMethod:HTTPMethod parameters:mDict];
	
	__weak BZFoursquareRequest *localRequest = request;
	request.completionBlock = ^{
		[self handleResponseForRequest:localRequest clientHandler:handler];
	};
	
	[self.requestQueue addOperation:request];
	
	return request;
}

#pragma mark -
#pragma mark Internal

- (void)handleResponseForRequest:(BZFoursquareRequest *)request clientHandler:(ResponseHandler)handler {
	
	ResponseHandler notifyClient = ^(NSError *err, BZFoursquareResponse *response){
		dispatch_async(dispatch_get_main_queue(), ^{
			handler(err, response);
		});
	};
	
	if (request.error) {
		notifyClient(request.error, nil);
	} else {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			BZFoursquareResponse *response = BZFoursquareResponse.new;
			NSError *err = [response loadResponseData:request.responseData];
			
			notifyClient(err, response);
		});
	}
}

@end
