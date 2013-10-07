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

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if __has_feature(objc_arc)
#error This file does not support Objective-C Automatic Reference Counting (ARC)
#endif

#define kMinSupportedVersion    @"20120609"
#define kAuthorizeBaseURL       @"https://foursquare.com/oauth2/authorize"

@interface BZFoursquare ()
@property(nonatomic,copy,readwrite) NSString *clientID;
@property(nonatomic,copy,readwrite) NSString *callbackURL;
@end

@implementation BZFoursquare

- (id)init {
    return [self initWithClientID:nil callbackURL:nil];
}

- (id)initWithClientID:(NSString *)clientID callbackURL:(NSString *)callbackURL {
    NSParameterAssert(clientID != nil && callbackURL != nil);
    self = [super init];
    if (self) {
        self.clientID = clientID;
        self.callbackURL = callbackURL;
        self.version = kMinSupportedVersion;
    }
    return self;
}

- (void)dealloc {
    self.clientID = nil;
    self.callbackURL = nil;
    self.clientSecret = nil;
    self.version = nil;
    self.locale = nil;
    self.sessionDelegate = nil;
    self.accessToken = nil;
    [super dealloc];
}

- (BOOL)startAuthorization {
    NSMutableArray *pairs = [NSMutableArray array];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:_clientID, @"client_id", @"token", @"response_type", _callbackURL, @"redirect_uri", nil];
    for (NSString *key in parameters) {
        NSString *value = [parameters objectForKey:key];
        CFStringRef escapedValue = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, CFSTR("%:/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
        NSMutableString *pair = [[key mutableCopy] autorelease];
        [pair appendString:@"="];
        [pair appendString:(NSString *)escapedValue];
        [pairs addObject:pair];
        CFRelease(escapedValue);
    }
    NSString *URLString = kAuthorizeBaseURL;
    NSMutableString *mURLString = [[URLString mutableCopy] autorelease];
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
    if (!_callbackURL || [[url absoluteString] rangeOfString:_callbackURL options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].length == 0) {
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
    if (_accessToken) {
        if ([_sessionDelegate respondsToSelector:@selector(foursquareDidAuthorize:)]) {
            [_sessionDelegate foursquareDidAuthorize:self];
        }
    } else {
        if ([_sessionDelegate respondsToSelector:@selector(foursquareDidNotAuthorize:error:)]) {
            [_sessionDelegate foursquareDidNotAuthorize:self error:parameters];
        }
    }
    return YES;
}

- (void)invalidateSession {
    self.accessToken = nil;
}

- (BOOL)isSessionValid {
    return (_accessToken != nil);
}

- (BZFoursquareRequest *)requestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate {
    NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (_accessToken) {
        [mDict setObject:_accessToken forKey:@"oauth_token"];
    }
    if (_version) {
        [mDict setObject:_version forKey:@"v"];
    }
    if (_locale) {
        [mDict setObject:_locale forKey:@"locale"];
    }
    return [[[BZFoursquareRequest alloc] initWithPath:path HTTPMethod:HTTPMethod parameters:mDict delegate:delegate] autorelease];
}

- (BZFoursquareRequest *)userlessRequestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate {
    NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [mDict setObject:_clientID forKey:@"client_id"];
    if (_clientSecret) {
        [mDict setObject:_clientSecret forKey:@"client_secret"];
    }
    if (_version) {
        [mDict setObject:_version forKey:@"v"];
    }
    if (_locale) {
        [mDict setObject:_locale forKey:@"locale"];
    }
    return [[[BZFoursquareRequest alloc] initWithPath:path HTTPMethod:HTTPMethod parameters:mDict delegate:delegate] autorelease];
}

@end
