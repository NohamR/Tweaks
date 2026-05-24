#import <substrate.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <string.h>
#include <stdint.h>

#define TAG @"[OQAdsLogger]"

%hook IMAAdsRequest
- (instancetype)initWithAdsResponse:(NSString *)adsResponse
                 adDisplayContainer:(id)adDisplayContainer
              avPlayerVideoDisplay:(id)avPlayerVideoDisplay
             pictureInPictureProxy:(id)pipProxy
                       userContext:(id)userContext {

    NSLog(@"%@-[IMAAdsRequest init] [PiP path]", TAG);
    NSLog(@"%@    adDisplayContainer    = %@", TAG, adDisplayContainer);
    NSLog(@"%@    avPlayerVideoDisplay  = %@", TAG, avPlayerVideoDisplay);
    NSLog(@"%@    pictureInPictureProxy = %@", TAG, pipProxy);
    NSLog(@"%@    VMAP payload (%lu bytes):\n%@",
          TAG, (unsigned long)adsResponse.length, adsResponse);

    id result = %orig;
    NSLog(@"%@    -> IMAAdsRequest = %p", TAG, result);
    return result;
}

- (instancetype)initWithAdsResponse:(NSString *)adsResponse
                 adDisplayContainer:(id)adDisplayContainer
                    contentPlayhead:(id)contentPlayhead
                       userContext:(id)userContext {
    // Replace the VMAP with an empty document
    NSString *emptyVMAP = @"<?xml version='1.0' encoding='utf-8'?>"
                           @"<vmap:VMAP xmlns:vmap=\"http://www.iab.net/vmap-1.0\" version=\"1.0\"/>";
    NSLog(@"%@ Replaced VMAP (%lu bytes) with empty document", TAG, adsResponse.length);
    return %orig(emptyVMAP, adDisplayContainer, contentPlayhead, userContext);
}
%end

// IMAAdsLoader — confirms dispatch to IMA SDK
//
// Called from OQPlayerAdsLoader.requestAds(_:loader:) (sub_10008FC08)
// after Swift dynamic-cast guards pass. This is the point of no return —
// the IMA SDK takes ownership of the request and starts network I/O.

%hook IMAAdsLoader
- (void)requestAdsWithRequest:(id)request {
    NSLog(@"%@ -[IMAAdsLoader requestAdsWithRequest:]", TAG);
    NSLog(@"%@    loader  = %@", TAG, self);
    NSLog(@"%@    request = %@", TAG, [request debugDescription]);
    %orig;
    NSLog(@"%@    requestAdsWithRequest dispatched ✓", TAG);
}
%end

// IMAAdsManager — SDK parsed the VMAP, breaks are scheduled
//
// Called from the IMAAdsLoaderDelegate callback in OQImaManager
// At this point the IMA SDK has parsed the VMAP and knows all ad break
// positions. Passing nil for renderingSettings means OQEE uses defaults.

%hook IMAAdsManager
- (void)initializeWithAdsRenderingSettings:(id)renderingSettings {
    NSLog(@"%@ -[IMAAdsManager initializeWithAdsRenderingSettings:]", TAG);
    NSLog(@"%@    adsManager        = %@", TAG, self);
    NSLog(@"%@    renderingSettings = %@", TAG, renderingSettings ?: @"(nil — default)");
    %orig;
    NSLog(@"%@    VMAP parsed, ad breaks scheduled ✓", TAG);
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

%ctor {
    // activate dev mode
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"tv.oqee.devModeEnabled"];
}