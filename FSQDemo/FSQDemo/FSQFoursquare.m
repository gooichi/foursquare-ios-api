//
//  FSQFoursquare.m
//
//  Copyright 2011 Ba-Z Communication Inc. All rights reserved.
//

#import "BZSynthesizeSingleton.h"
#import "FSQFoursquare.h"

#define kClientID       FOURSQUARE_CLIENT_ID
#define kCallbackURL    FOURSQUARE_CALLBACK_URL

#define kFoursquareAccessTokenKey       @"FoursquareAccessToken"

@implementation FSQFoursquare

BZ_SYNTHESIZE_SINGLETON_FOR_CLASS(FSQ, Foursquare)

- (id)init {
    self = [self initWithClientID:kClientID callbackURL:kCallbackURL];
    if (self) {
        self.version = @"20111101";
        self.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.accessToken = [defaults stringForKey:kFoursquareAccessTokenKey];
    }
    return self;
}

#pragma mark -
#pragma mark BZFoursquare

- (BOOL)handleOpenURL:(NSURL *)url {
    BOOL result = [super handleOpenURL:url];
    if (result) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.accessToken forKey:kFoursquareAccessTokenKey];
    }
    return result;
}

- (void)invalidateSession {
    [super invalidateSession];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kFoursquareAccessTokenKey];
}

@end
