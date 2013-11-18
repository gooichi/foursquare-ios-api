//
//  BZFoursquareTests.m
//  BZFoursquareTests
//

#import <SenTestingKit/SenTestingKit.h>
#import "BZFoursquareRequest.h"

#ifndef NSFoundationVersionNumber_iOS_5_1
#define NSFoundationVersionNumber_iOS_5_1  890.1
#endif

@interface BZFoursquareTests : SenTestCase <BZFoursquareRequestDelegate>

@property(nonatomic,strong) NSConditionLock *lock;

@end

@implementation BZFoursquareTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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
