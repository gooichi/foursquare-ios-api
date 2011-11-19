/*
 * Copyright (C) 2011 Ba-Z Communication Inc. All rights reserved.
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

@protocol BZFoursquareRequestDelegate;

@interface BZFoursquareRequest : NSObject {
    NSString            *path_;
    NSString            *HTTPMethod_;
    NSDictionary        *parameters_;
    id<BZFoursquareRequestDelegate> delegate_;
    NSURLConnection     *connection_;
    NSMutableData       *responseData_;
    NSDictionary        *meta_;
    NSArray             *notifications_;
    NSDictionary        *response_;
}
@property(nonatomic,copy,readonly) NSString *path;
@property(nonatomic,copy,readonly) NSString *HTTPMethod;
@property(nonatomic,copy,readonly) NSDictionary *parameters;
@property(nonatomic,assign) id<BZFoursquareRequestDelegate> delegate;
// responses
@property(nonatomic,copy,readonly) NSDictionary *meta;
@property(nonatomic,copy,readonly) NSArray *notifications;
@property(nonatomic,copy,readonly) NSDictionary *response;

+ (NSURL *)baseURL;

- (id)initWithPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters delegate:(id<BZFoursquareRequestDelegate>)delegate;

- (void)start;
- (void)cancel;

@end

@protocol BZFoursquareRequestDelegate <NSObject>
@optional
- (void)requestDidStartLoading:(BZFoursquareRequest *)request;
- (void)requestDidFinishLoading:(BZFoursquareRequest *)request;
- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error;
@end

FOUNDATION_EXPORT NSString * const BZFoursquareErrorDomain;
