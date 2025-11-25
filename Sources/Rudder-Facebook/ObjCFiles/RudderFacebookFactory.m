//
//  RudderFacebookFactory.m
//  FBSnapshotTestCase
//
//  Created by Arnab Pal on 15/11/19.
//

#import "RudderFacebookFactory.h"
#import "RudderFacebookIntegration.h"

@implementation RudderFacebookFactory

+ (instancetype)instance {
    static RudderFacebookFactory *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (nonnull NSString *)key {
    return @"Facebook App Events";
}

- (nonnull id<RSIntegration>)initiate:(nonnull NSDictionary *)config client:(nonnull RSClient *)client rudderConfig:(nonnull RSConfig *)rudderConfig {
    return [[RudderFacebookIntegration alloc] initWithConfig:config withAnalytics:client];
}


@end
