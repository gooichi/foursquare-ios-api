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

@interface FSQJSONObjectViewController ()
@property(nonatomic,readwrite,copy) id JSONObject;
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer;
- (void)menuControllerWillHideMenu:(NSNotification *)notification;
- (void)copy:(id)sender;
@end

@implementation FSQJSONObjectViewController

- (id)initWithJSONObject:(id)JSONObject {
    self = [self initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.JSONObject = JSONObject;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:)) {
        return YES;
    }
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([_JSONObject isKindOfClass:[NSArray class]]
        || [_JSONObject isKindOfClass:[NSDictionary class]]) {
        return [_JSONObject count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.gestureRecognizers = nil;
    }
    id value;
    if ([_JSONObject isKindOfClass:[NSNull class]]) {
        value = _JSONObject;
    } else if ([_JSONObject isKindOfClass:[NSDictionary class]]) {
        id key = [[_JSONObject allKeys] sortedArrayUsingSelector:@selector(compare:)][indexPath.row];
        cell.textLabel.text = [key description];
        value = _JSONObject[key];
    } else if ([_JSONObject isKindOfClass:[NSArray class]]) {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Item %ld", @""), indexPath.row];
        value = _JSONObject[indexPath.row];
    } else {
        value = _JSONObject;
    }
    if ([value isKindOfClass:[NSNull class]]) {
        cell.detailTextLabel.text = @"null";
        cell.detailTextLabel.textColor = [UIColor redColor];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressRecognizer];
    } else if ([value isKindOfClass:[NSDictionary class]]
               || [value isKindOfClass:[NSArray class]]) {
        NSUInteger count = [value count];
        NSString *format;
        if (count == 1) {
            format = NSLocalizedString(@"(%lu item)", @"");
        } else {
            format = NSLocalizedString(@"(%lu items)", @"");
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:format, count];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            cell.detailTextLabel.text = [value boolValue] ? NSLocalizedString(@"true", @"") : NSLocalizedString(@"false", @"");;
        } else {
            cell.detailTextLabel.text = [value description];
        }
        cell.detailTextLabel.textColor = [UIColor blueColor];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressRecognizer];
    } else if ([value isKindOfClass:[NSString class]]) {
        cell.detailTextLabel.text = value;
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [cell addGestureRecognizer:longPressRecognizer];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _JSONObject ? 1 : 0;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return nil;
    } else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id value = nil;
    if ([_JSONObject isKindOfClass:[NSDictionary class]]) {
        id key = [[_JSONObject allKeys] sortedArrayUsingSelector:@selector(compare:)][indexPath.row];
        value = _JSONObject[key];
    } else if ([_JSONObject isKindOfClass:[NSArray class]]) {
        value = _JSONObject[indexPath.row];
    }
    if ([value isKindOfClass:[NSDictionary class]]
        || [value isKindOfClass:[NSArray class]]) {
        FSQJSONObjectViewController *JSONObjectViewController = [[FSQJSONObjectViewController alloc] initWithJSONObject:value];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        JSONObjectViewController.title = cell.textLabel.text;
        [self.navigationController pushViewController:JSONObjectViewController animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Anonymous category

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer {
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        UITableView *tableView = self.tableView;
        NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:[longPressRecognizer locationInView:tableView]];
        if (indexPath) {
            [self becomeFirstResponder];
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            CGRect targetRect = [tableView rectForRowAtIndexPath:indexPath];
            [menuController setTargetRect:targetRect inView:tableView];
            [menuController setMenuVisible:YES animated:YES];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerWillHideMenu:) name:UIMenuControllerWillHideMenuNotification object:menuController];
        }
    }
}

- (void)menuControllerWillHideMenu:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillHideMenuNotification object:[notification object]];
    [self resignFirstResponder];
    UITableView *tableView = self.tableView;
    NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)copy:(id)sender {
    UITableView *tableView = self.tableView;
    NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [UIPasteboard generalPasteboard].string = cell.detailTextLabel.text;
}

@end
