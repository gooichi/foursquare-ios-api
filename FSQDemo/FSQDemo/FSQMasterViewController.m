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

#import "FSQJSONObjectViewController.h"
#import "FSQMasterViewController.h"

#define kClientID       FOURSQUARE_CLIENT_ID
#define kCallbackURL    FOURSQUARE_CALLBACK_URL

@interface FSQMasterViewController ()
@property(nonatomic,readwrite,strong) BZFoursquare *foursquare;
@property(nonatomic,strong) BZFoursquareRequest *request;
@property(nonatomic,copy) NSDictionary *meta;
@property(nonatomic,copy) NSArray *notifications;
@property(nonatomic,copy) NSDictionary *response;
- (void)updateView;
- (void)cancelRequest;
- (void)prepareForRequest;
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

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:kClientID callbackURL:kCallbackURL];
        _foursquare.version = @"20120609";
        _foursquare.locale = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        _foursquare.sessionDelegate = self;
    }
    return self;
}

- (void)dealloc {
    _foursquare.sessionDelegate = nil;
    [self cancelRequest];
}

#pragma mark -
#pragma mark View lifecycle

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
    case kAuthenticationSection:
        if (![_foursquare isSessionValid]) {
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
                collection = _meta;
                break;
            case kNotificationsRow:
                collection = _notifications;
                break;
            case kResponseRow:
                collection = _response;
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
        if (![_foursquare isSessionValid]) {
            [_foursquare startAuthorization];
        } else {
            [_foursquare invalidateSession];
            NSArray *indexPaths = @[indexPath];
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
                JSONObject = _meta;
                break;
            case kNotificationsRow:
                JSONObject = _notifications;
                break;
            case kResponseRow:
                JSONObject = _response;
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
#pragma mark BZFoursquareRequestDelegate

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request {
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error userInfo][@"errorDetail"] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:kAccessTokenRow inSection:kAuthenticationSection];
    NSArray *indexPaths = @[indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorInfo);
}

#pragma mark -
#pragma mark Anonymous category

- (void)updateView {
    if ([self isViewLoaded]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView reloadData];
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (void)cancelRequest {
    if (_request) {
        _request.delegate = nil;
        [_request cancel];
        self.request = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)prepareForRequest {
    [self cancelRequest];
    self.meta = nil;
    self.notifications = nil;
    self.response = nil;
}

- (void)searchVenues {
    [self prepareForRequest];
    NSDictionary *parameters = @{@"ll": @"40.7,-74"};
    self.request = [_foursquare requestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [_request start];
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)checkin {
    [self prepareForRequest];
    NSDictionary *parameters = @{@"venueId": @"4d341a00306160fcf0fc6a88", @"broadcast": @"public"};
    self.request = [_foursquare requestWithPath:@"checkins/add" HTTPMethod:@"POST" parameters:parameters delegate:self];
    [_request start];
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)addPhoto {
    [self prepareForRequest];
    NSURL *photoURL = [[NSBundle mainBundle] URLForResource:@"TokyoBa-Z" withExtension:@"jpg"];
    NSData *photoData = [NSData dataWithContentsOfURL:photoURL];
    NSDictionary *parameters = @{@"photo.jpg": photoData, @"venueId": @"4d341a00306160fcf0fc6a88"};
    self.request = [_foursquare requestWithPath:@"photos/add" HTTPMethod:@"POST" parameters:parameters delegate:self];
    [_request start];
    [self updateView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

@end
