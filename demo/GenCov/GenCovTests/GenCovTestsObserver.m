//
// GenCovTestsObserver.m
//
// Created by Liygem on 2013-12-03
//

#ifdef COVERAGE 

#import <XCTest/XCTest.h> 

@interface GenCovTestsObserver : XCTestObserver
@end 

@implementation GenCovTestsObserver 

+ (void)load
{
	[[NSUserDefaults standardUserDefaults] setValue:@"XCTestLog,GenCovTestsObserver" forKey:XCTestObserverClassKey];
} 

- (void)stopObserving
{
	[super stopObserving];
	UIApplication *application = [UIApplication sharedApplication];
	id<UIApplicationDelegate> delegate = [application delegate];
	[delegate applicationWillResignActive:application];
} 

@end 

#endif //COVERAGE
