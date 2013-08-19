//
//  BZFoursquareLogicTests.m
//  BZFoursquareLogicTests
//

#import "BZFoursquareLogicTests.h"

#ifndef NSFoundationVersionNumber_iOS_5_1
#define NSFoundationVersionNumber_iOS_5_1  890.1
#endif

@interface BZFoursquareLogicTests ()
@property(nonatomic,retain) NSConditionLock *lock;
@end

@implementation BZFoursquareLogicTests

- (void)setUp {
    [super setUp];
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    [super tearDown];
}

- (void)testThatMakesSureWeDontFinishTooFast {
    // Avoid "Tests did not finish" warning
    [NSThread sleepForTimeInterval:1];
}

- (void)testDelegateQueue {
    BZFoursquareRequest *request = [[BZFoursquareRequest alloc] initWithPath:@"venues/search" HTTPMethod:@"GET" parameters:@{@"ll": @"40.7,-74"} delegate:self];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_5_1) {
        STAssertThrows(request.delegateQueue = [[NSOperationQueue alloc] init], @"");
    } else {
        STAssertNoThrow(request.delegateQueue = [[NSOperationQueue alloc] init], @"");
        self.lock = [[NSConditionLock alloc] initWithCondition:0];
        [request start];
        [self.lock lockWhenCondition:1];
        [self.lock unlock];
        self.lock = nil;
    }
}

#pragma mark - BZFoursquareRequestDelegate

- (void)requestDidStartLoading:(BZFoursquareRequest *)request {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.lock lock];
    [self.lock unlockWithCondition:1];
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
    [self.lock lock];
    [self.lock unlockWithCondition:1];
}

@end
