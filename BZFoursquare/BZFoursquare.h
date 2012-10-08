/*
 * Copyright (C) 2011-2012 Ba-Z Communication Inc. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "BZFoursquareRequest.h"

@protocol BZFoursquareSessionDelegate;

@interface BZFoursquare : NSObject  {
    NSString    *clientID_;
    NSString    *callbackURL_;
    NSString    *clientSecret_;
    NSString    *version_;
    NSString    *locale_;
    id<BZFoursquareSessionDelegate> sessionDelegate_;
    NSString    *accessToken_;
}
@property(nonatomic,copy,readonly) NSString *clientID;
@property(nonatomic,copy,readonly) NSString *callbackURL;
@property(nonatomic,copy) NSString *clientSecret; // for userless access
@property(nonatomic,copy) NSString *version; // YYYYMMDD
@property(nonatomic,copy) NSString *locale;  // en (default), fr, de, it, etc.
@property(nonatomic,assign) id<BZFoursquareSessionDelegate> sessionDelegate;
@property(nonatomic,copy) NSString *accessToken;

- (id)initWithClientID:(NSString *)clientID callbackURL:(NSString *)callbackURL;

- (BOOL)startAuthorization;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)invalidateSession;
- (BOOL)isSessionValid;

- (BZFoursquareRequest *)requestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate;
- (BZFoursquareRequest *)userlessRequestWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate;

@end

@protocol BZFoursquareSessionDelegate <NSObject>
@optional
- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare;
- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo;
@end
