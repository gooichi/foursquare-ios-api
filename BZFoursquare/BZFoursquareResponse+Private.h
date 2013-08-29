//
//  BSFoursquareResponse+Private.h
//  FSQDemo
//
//  Created by kernel on 29/08/2013.
//
//

#import "BZFoursquareResponse.h"

@interface BZFoursquareResponse ()
- (NSError *)loadResponseData:(NSData *)response;

@property(nonatomic,strong,readwrite) NSDictionary *meta;
@property(nonatomic,strong,readwrite) NSArray *notifications;
@property(nonatomic,strong,readwrite) NSDictionary *response;
@end
