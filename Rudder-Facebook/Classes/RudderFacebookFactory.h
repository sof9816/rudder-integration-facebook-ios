//
//  RudderFacebookFactory.h
//  FBSnapshotTestCase
//
//  Created by Arnab Pal on 15/11/19.
//

#import <Foundation/Foundation.h>
@import Rudder;

NS_ASSUME_NONNULL_BEGIN

@interface RudderFacebookFactory : NSObject<RSIntegrationFactory>

+ (instancetype) instance;

@end

NS_ASSUME_NONNULL_END
