//
//  BZFoursquareResponse.h
//  test-anim
//
//  Created by kernel on 29/08/2013.
//  Copyright (c) 2013 kernel@realm. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const BZFoursquareErrorDomain;

@interface BZFoursquareResponse : NSObject
@property(nonatomic,strong,readonly) NSDictionary *meta;
@property(nonatomic,strong,readonly) NSArray *notifications;
@property(nonatomic,strong,readonly) NSDictionary *response;
@end
