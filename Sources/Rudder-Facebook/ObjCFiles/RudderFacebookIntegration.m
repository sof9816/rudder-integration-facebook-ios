//
//  RudderFacebookIntegration.m
//  FBSnapshotTestCase
//
//  Created by Arnab Pal on 15/11/19.
//

#import "RudderFacebookIntegration.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@implementation RudderFacebookIntegration

- (instancetype)initWithConfig:(NSDictionary *)config withAnalytics:(RSClient *)client {
    self = [super init];
    if (self) {
        self.limitedDataUse = [config[@"limitedDataUse"] boolValue];
        self.dpoState = [config[@"dpoState"] intValue];
        if(self.dpoState != 0 && self.dpoState != 1000) {
            self.dpoState = 0;
        }
        self.dpoCountry = [config[@"dpoCountry"] intValue];
        if(self.dpoCountry != 0 && self.dpoCountry != 1) {
            self.dpoCountry = 0;
        }
        
        self->events = @[@"identify", @"track", @"screen"];
        self->trackReservedKeywords = [[NSArray alloc] initWithObjects:KeyProductId, KeyRating, @"name", KeyOrderId, KeyCurrency, @"description", KeyQuery, @"value", KeyPrice, KeyRevenue, nil];
        
        if (self.limitedDataUse) {
            [FBSDKSettings.sharedSettings setDataProcessingOptions:@[@"LDU"] country:self.dpoCountry state:self.dpoState];
            [RSLogger logDebug:[NSString stringWithFormat:@"[FBSDKSettings setDataProcessingOptions:[%@] country:%d state:%d]",@"LDU", self.dpoCountry, self.dpoState]];
        } else {
            [FBSDKSettings.sharedSettings setDataProcessingOptions:@[]];
            [RSLogger logDebug:@"[FBSDKSettings setDataProcessingOptions:[]"];
        }
    }
    return self;
}

- (void) processRuderEvent: (nonnull RSMessage *) message {
    int label = (int) [self->events indexOfObject:message.type];
    switch(label)
        {
            case 0:
            {
            [FBSDKAppEvents.shared setUserID:message.userId];
            NSDictionary *address = (NSDictionary*) message.context.traits[@"address"];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"email"]] forType:FBSDKAppEventEmail];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"firstName"]] forType:FBSDKAppEventFirstName];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"lastName"]] forType:FBSDKAppEventLastName];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"phone"]] forType:FBSDKAppEventPhone];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"birthday"]] forType:FBSDKAppEventDateOfBirth];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", message.context.traits[@"gender"]] forType:FBSDKAppEventGender];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", address[@"city"]] forType:FBSDKAppEventCity];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", address[@"state"]] forType:FBSDKAppEventState];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", address[@"postalcode"]] forType:FBSDKAppEventZip];
            [FBSDKAppEvents.shared setUserData:[[NSString alloc] initWithFormat:@"%@", address[@"country"]] forType:FBSDKAppEventCountry];
            break;
            }
            case 1:
            {
                // FB Event Names must be <= 40 characters
            NSString *truncatedEvent = [message.event substringToIndex: MIN(40, [message.event length])];
            NSString *eventName = [self getFacebookEvent: truncatedEvent];
 
            NSMutableDictionary<NSString *, id> *params = [[NSMutableDictionary alloc] init];
            [self handleCustomPropeties:message.properties params:params isScreenEvent:false];
            
                // Standard events, refer Facebook docs: https://developers.facebook.com/docs/app-events/reference#standard-events-2 for more info
            if ([eventName isEqualToString:FBSDKAppEventNameAddedToCart] || [eventName isEqualToString:FBSDKAppEventNameAddedToWishlist] || [eventName isEqualToString:FBSDKAppEventNameViewedContent]) {
                [self handleStandardProperties:message.properties params:params eventName:eventName];
                NSNumber *price = [self getValueToSumFromProperties:message.properties propertyKey:KeyPrice];
                if (price) {
                    [FBSDKAppEvents.shared logEvent:eventName valueToSum:[price doubleValue] parameters:params];
                }
            } else if ([eventName isEqualToString:FBSDKAppEventNameInitiatedCheckout] || [eventName isEqualToString:FBSDKAppEventNameSpentCredits]) {
                [self handleStandardProperties:message.properties params:params eventName:eventName];
                NSNumber *value = [self getValueToSumFromProperties:message.properties propertyKey:@"value"];
                if (value) {
                    [FBSDKAppEvents.shared logEvent:eventName valueToSum:[value doubleValue] parameters:params];
                }
            } else if ([eventName isEqualToString:ECommOrderCompleted]) {
                [self handleStandardProperties:message.properties params:params eventName:eventName];
                NSNumber *revenue = [self getValueToSumFromProperties:message.properties propertyKey:KeyRevenue];
                NSString *currency = [self extractCurrency:message.properties withKey:KeyCurrency];
                if (revenue) {
                    [FBSDKAppEvents.shared logPurchase:[revenue doubleValue] currency:currency parameters:params];
                }
            } else if ([eventName isEqualToString:FBSDKAppEventNameSearched] || [eventName isEqualToString:FBSDKAppEventNameAddedPaymentInfo] || [eventName isEqualToString:FBSDKAppEventNameCompletedRegistration] || [eventName isEqualToString:FBSDKAppEventNameAchievedLevel] || [eventName isEqualToString:FBSDKAppEventNameCompletedTutorial] || [eventName isEqualToString:FBSDKAppEventNameUnlockedAchievement] || [eventName isEqualToString:FBSDKAppEventNameSubscribe] || [eventName isEqualToString:FBSDKAppEventNameStartTrial] || [eventName isEqualToString:FBSDKAppEventNameAdClick] || [eventName isEqualToString:FBSDKAppEventNameAdImpression] || [eventName isEqualToString:FBSDKAppEventNameRated]) {
                [self handleStandardProperties:message.properties params:params eventName:eventName];
                [FBSDKAppEvents.shared logEvent:eventName parameters:params];
            } else {
                [FBSDKAppEvents.shared logEvent:eventName parameters:params];
            }
            break;
            }
            case 2:
            {
                // FB Event Names must be <= 40 characters
                // 'Viewed' and 'Screen' with spaces take up 14
            NSString *truncatedEvent = [message.event substringToIndex: MIN(26, [message.event length])];
            NSString *event = [[NSString alloc] initWithFormat:@"Viewed %@ Screen", truncatedEvent];
            NSMutableDictionary<NSString *, id> *params = [[NSMutableDictionary alloc] init];
            [self handleCustomPropeties:message.properties params:params isScreenEvent:true];
            [FBSDKAppEvents.shared logEvent:event parameters:params];
            break;
            }
            default:
            [RSLogger logWarn:@"MessageType is not supported"];
            break;
        }
}

- (void)dump:(nonnull RSMessage *)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self processRuderEvent:message];
    }];
    
}

- (void)reset {
    FBSDKAppEvents.shared.userID = nil;
    [FBSDKAppEvents.shared clearUserData];
}

- (void)flush {
    [RSLogger logDebug:@"Facebook App Events Factory doesn't support Flush Call"];
}

#pragma mark - Utils

- (NSString *)getFacebookEvent:(NSString *)event {
    if ([event isEqualToString:ECommProductsSearched]) {
        return FBSDKAppEventNameSearched;
    }
    if ([event isEqualToString:ECommProductViewed]) {
        return FBSDKAppEventNameViewedContent;
    }
    if ([event isEqualToString:ECommProductAdded]) {
        return FBSDKAppEventNameAddedToCart;
    }
    if ([event isEqualToString:ECommProductAddedToWishList]) {
        return FBSDKAppEventNameAddedToWishlist;
    }
    if ([event isEqualToString:ECommPaymentInfoEntered]) {
        return FBSDKAppEventNameAddedPaymentInfo;
    }
    if ([event isEqualToString:ECommCheckoutStarted]) {
        return FBSDKAppEventNameInitiatedCheckout;
    }
    if ([event isEqualToString:@"Complete Registration"]) {
        return FBSDKAppEventNameCompletedRegistration;
    }
    if ([event isEqualToString:@"Achieve Level"]) {
        return FBSDKAppEventNameAchievedLevel;
    }
    if ([event isEqualToString:@"Complete Tutorial"]) {
        return FBSDKAppEventNameCompletedTutorial;
    }
    if ([event isEqualToString:@"Unlock Achievement"]) {
        return FBSDKAppEventNameUnlockedAchievement;
    }
    if ([event isEqualToString:@"Subscribe"]) {
        return FBSDKAppEventNameSubscribe;
    }
    if ([event isEqualToString:@"Start Trial"]) {
        return FBSDKAppEventNameStartTrial;
    }
    if ([event isEqualToString:ECommPromotionClicked]) {
        return FBSDKAppEventNameAdClick;
    }
    if ([event isEqualToString:ECommPromotionViewed]) {
        return FBSDKAppEventNameAdImpression;
    }
    if ([event isEqualToString:@"Spend Credits"]) {
        return FBSDKAppEventNameSpentCredits;
    }
    if ([event isEqualToString:ECommProductReviewed]) {
        return FBSDKAppEventNameRated;
    }
    return event;
}

- (void) handleCustomPropeties: (NSDictionary *)properties params: (NSMutableDictionary<NSString *, id> *)params isScreenEvent: (BOOL)isScreenEvent {
    for (NSString *key in properties) {
        NSString *value = [properties objectForKey:key];
        if (!isScreenEvent && [self->trackReservedKeywords containsObject:key]) {
            continue;
        }
        if ([value isKindOfClass:[NSNumber class]]) {
            params[key] = value;
        } else {
            params[key] = [NSString stringWithFormat:@"%@", value];
        }
    }
}

- (void) handleStandardProperties:(NSDictionary *)properties params: (NSMutableDictionary<NSString *, id> *)params eventName: (NSString *)eventName {
    NSString *productId = [NSString stringWithFormat:@"%@", properties[KeyProductId]];
    if (productId) {
        params[FBSDKAppEventParameterNameContentID] = productId;
    }
    
    NSNumber *rating = properties[KeyRating];
    if (rating) {
        params[FBSDKAppEventParameterNameMaxRatingValue] = rating;
    }
    
    NSString *name = [NSString stringWithFormat:@"%@", properties[@"name"]];
    if (name) {
        params[FBSDKAppEventParameterNameAdType] = name;
    }
    
    NSString *orderId = [NSString stringWithFormat:@"%@", properties[KeyOrderId]];
    if (orderId) {
        params[FBSDKAppEventParameterNameOrderID] = orderId;
    }
    
    // For `Purchase` event we're directly handling the `currency` properties
    if (![eventName isEqualToString:ECommOrderCompleted]) {
        params[FBSDKAppEventParameterNameCurrency] = [self extractCurrency:properties withKey:KeyCurrency];
    }
    
    NSString *description = [NSString stringWithFormat:@"%@", properties[@"description"]];
    if (description) {
        params[FBSDKAppEventParameterNameDescription] = description;
    }
    
    NSString *query = [NSString stringWithFormat:@"%@", properties[KeyQuery]];
    if (query) {
        params[FBSDKAppEventParameterNameSearchString] = query;
    }
}

- (NSNumber *)getValueToSumFromProperties:(NSDictionary *)properties propertyKey:(NSString *)propertyKey {
    if (properties != nil) {
        id value = [properties objectForKey:propertyKey];
        if (value != nil) {
            if ([value isKindOfClass:[NSNumber class]]) {
                return value;
            } else if ([value isKindOfClass:[NSString class]]) {
                return [NSNumber numberWithDouble:[value doubleValue]];
            }
        }
    }
    return nil;
}

- (NSString *)extractCurrency:(NSDictionary *)dictionary withKey:(NSString *)currencyKey
{
    id currencyProperty = nil;
    for (NSString *key in dictionary.allKeys) {
        if ([key caseInsensitiveCompare:currencyKey] == NSOrderedSame) {
            currencyProperty = dictionary[key];
            return currencyProperty;
        }
    }
    return @"USD";
}

#pragma mark - Callbacks for app state changes

- (void)applicationDidBecomeActive
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[FBSDKAppEvents alloc] activateApp];
    }];
}

@end
