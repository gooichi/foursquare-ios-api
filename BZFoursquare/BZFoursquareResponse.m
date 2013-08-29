//
//  BZFoursquareResponse.m
//  test-anim
//
//  Created by kernel on 29/08/2013.
//  Copyright (c) 2013 kernel@realm. All rights reserved.
//

#import "BZFoursquareResponse.h"
#import "BZFoursquareResponse+Private.h"

#if BZ_USE_JSONKIT
#import "JSONKit.h"
#elif BZ_USE_SBJSON
#import "SBJson.h"
#endif

@implementation BZFoursquareResponse

- (NSError *)loadResponseData:(NSData *)data {
	NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
    NSDictionary *response = nil;
    NSError *error = nil;
#if defined(__IPHONE_5_0) && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
    response = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
#elif defined(__IPHONE_5_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0
    if ([NSJSONSerialization class]) {
        response = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    } else {
#if BZ_USE_JSONKIT
        JSONDecoder *decoder = [JSONDecoder decoder];
        response = [decoder objectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
#elif BZ_USE_SBJSON
        SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
        response = [parser objectWithString:responseString];
        if (!response) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:parser.error forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"org.brautaset.SBJsonParser.ErrorDomain" code:0 userInfo:userInfo];
        }
#else
#error BZ_USE_* must be defined
#endif
    }
#else
#if BZ_USE_JSONKIT
    JSONDecoder *decoder = [JSONDecoder decoder];
    response = [decoder objectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
#elif BZ_USE_SBJSON
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    response = [parser objectWithString:responseString];
    if (!response) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:parser.error forKey:NSLocalizedDescriptionKey];
        error = [NSError errorWithDomain:@"org.brautaset.SBJsonParser.ErrorDomain" code:0 userInfo:userInfo];
    }
#else
#error BZ_USE_* must be defined
#endif
#endif
    if (!response) {
		return nil;
    }
	
	self.meta = [response objectForKey:@"meta"];
    self.notifications = [response objectForKey:@"notifications"];
    self.response = [response objectForKey:@"response"];
	
    NSInteger code = [[self.meta objectForKey:@"code"] integerValue];
    if (code / 100 != 2) {
        error = [NSError errorWithDomain:BZFoursquareErrorDomain code:code userInfo:self.meta];
		return error;
    }
	
	return nil;
}

@end


NSString * const BZFoursquareErrorDomain = @"BZFoursquareErrorDomain";
