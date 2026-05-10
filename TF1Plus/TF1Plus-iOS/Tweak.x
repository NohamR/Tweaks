#import <Foundation/Foundation.h>

%hook FWRequestConfiguration
- (id)initWithServerURL:(id)arg1 playerProfile:(id)arg2 {
    return self;
}
%end

%hook VSSubscriptionRegistrationCenter
- (void)setCurrentSubscription:(id)subscription
{
    NSLog(@"Blocked VSSubscriptionRegistrationCenter");
    NSLog(@"Subscription: %@", subscription);
    return;
}
%end