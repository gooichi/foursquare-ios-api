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

#import "FSQJSONObjectViewController.h"
#import "FSQMasterViewController.h"

#define kClientID       FOURSQUARE_CLIENT_ID
#define kCallbackURL    FOURSQUARE_CALLBACK_URL

@interface FSQMasterViewController ()
@property(nonatomic,readwrite,strong) BZFoursquare *foursquare;
@property(nonatomic,strong) BZFoursquareResponse *response;

- (void)updateView;
- (void)searchVenues;
- (void)checkin;
- (void)addPhoto;
@end

enum {
    kAuthenticationSection = 0,
    kEndpointsSection,
    kResponsesSection,
    kSectionCount
};

enum {
    kAccessTokenRow = 0,
    kAuthenticationRowCount
};

enum {
    kSearchVenuesRow = 0,
    kCheckInRow,
    kAddPhotoRow,
    kEndpointsRowCount
};

enum {
    kMetaRow = 0,
    kNotificationsRow,
    kResponseRow,
    kResponsesRowCount
};

@implementation FSQMasterViewController

@synthesize foursquare = foursquare_;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:kClientID callbackURL:kCallbackURL];
        foursquare_.version = @"20111119";
        foursquare_.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        foursquare_.sessionDelegate = self;
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
    case kAuthenticationSection:
        if (![foursquare_ isSessionValid]) {
            cell.textLabel.text = NSLocalizedString(@"Obtain Access Token", @"");
        } else {
            cell.textLabel.text = NSLocalizedString(@"Forget Access Token", @"");
        }
        break;
    case kResponsesSection:
        {
            id collection = nil;
            switch (indexPath.row) {
            case kMetaRow:
                collection = self.response.meta;
                break;
            case kNotificationsRow:
                collection = self.response.notifications;
                break;
            case kResponseRow:
                collection = self.response.response;
                break;
            }
            if (!collection) {
                cell.textLabel.enabled = NO;
                cell.detailTextLabel.text = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.enabled = YES;
                NSUInteger count = [collection count];
                NSString *format = (count == 1) ? NSLocalizedString(@"(%lu item)", @"") : NSLocalizedString(@"(%lu items)", @"");
                cell.detailTextLabel.text = [NSString stringWithFormat:format, count];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
        }
        break;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
    case kAuthenticationSection:
        if (![foursquare_ isSessionValid]) {
            [foursquare_ startAuthorization];
        } else {
            [foursquare_ invalidateSession];
            NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
            [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        break;
    case kEndpointsSection:
        switch (indexPath.row) {
        case kSearchVenuesRow:
            [self searchVenues];
            break;
        case kCheckInRow:
            [self checkin];
            break;
        case kAddPhotoRow:
            [self addPhoto];
            break;
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        break;
    case kResponsesSection:
        {
            id JSONObject = nil;
            switch (indexPath.row) {
            case kMetaRow:
                JSONObject = self.response.meta;
                break;
            case kNotificationsRow:
                JSONObject = self.response.notifications;
                break;
            case kResponseRow:
                JSONObject = self.response.response;
                break;
            }
            FSQJSONObjectViewController *JSONObjectViewController = [[FSQJSONObjectViewController alloc] initWithJSONObject:JSONObject];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            JSONObjectViewController.title = cell.textLabel.text;
            [self.navigationController pushViewController:JSONObjectViewController animated:YES];
        }
        break;
    }
}

#pragma mark -
#pragma mark BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kAccessTokenRow inSection:kAuthenticationSection];
    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorInfo);
}

#pragma mark -
#pragma mark Anonymous category

- (void)showErrorAlertWithMessage:(NSString *)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Foursquare error" message:message delegate:nil cancelButtonTitle:@"Ok :(" otherButtonTitles:nil];
	[alert show];
}

- (void)updateView {
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
		
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (void)searchVenues {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"40.7,-74", @"ll", nil];
	
	[foursquare_ requestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters completionHandler:^(NSError *err, BZFoursquareResponse *response) {
		[self handlerResponse:response error:err];
	}];
	
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)checkin {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"4d341a00306160fcf0fc6a88", @"venueId", @"public", @"broadcast", nil];
	
	[foursquare_ requestWithPath:@"checkins/add" HTTPMethod:@"POST" parameters:parameters completionHandler:^(NSError *err, BZFoursquareResponse *response) {
		[self handlerResponse:response error:err];
	}];
	
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)addPhoto {
    NSURL *photoURL = [[NSBundle mainBundle] URLForResource:@"TokyoBa-Z" withExtension:@"jpg"];
    NSData *photoData = [NSData dataWithContentsOfURL:photoURL];
	
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:photoData, @"photo.jpg", @"4d341a00306160fcf0fc6a88", @"venueId", nil];
	
	[foursquare_ requestWithPath:@"photos/add" HTTPMethod:@"POST" parameters:parameters completionHandler:^(NSError *err, BZFoursquareResponse *response) {
		[self handlerResponse:response error:err];
	}];
	
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)handlerResponse:(BZFoursquareResponse *)response error:(NSError *)err {
	if (err) {
		[self showErrorAlertWithMessage:err.localizedDescription];
		return;
	}
	
	self.response = response;
	
	[self updateView];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
