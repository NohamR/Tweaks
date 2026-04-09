// changes : FCInAppPurchaseServiceFreemium block deleted, FCTraktIAPManager block deleted, layoutSubviews -> awakeFromNib on FCVersionView, and the dead return %orig lines after return statements cleaned up (they were unreachable in the old version too)

#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook FCIAPGUIHelper
+(bool) isProAvailable {
    return TRUE;
}
+(bool) isSubscriptionBought {
    return TRUE;
}
%end

%hook FCInAppPurchaseServiceBase
- (bool)isFeaturePurchased:(long long)arg1 tillDate:(id*)arg2 {
    return 1;
}
- (bool)isFeaturePurchased:(long long)arg1 {
    return 1;
}
%end

%hook FCInAppPurchaseServiceDummy
- (bool)isFeaturePurchased:(long long)arg1 tillDate:(id*)arg2 {
    return 1;
}
%end

// REMOVED: FCInAppPurchaseServiceFreemium (class gone from binary, replaced by SK2)

// SK2 IAP backend
%hook _TtC6infuse31InAppPurchaseServiceFreemiumSK2
- (bool)isFeaturePurchased:(long long)arg1 tillDate:(id*)arg2 {
    return 1;
}
- (long long)iapVersionStatus {
    // FCUpgradeToProViewController.featureHasBought checks iapVersionStatus > 0
    return 1;
}
%end

%hook FCProductCollectionCell
-(bool) featurePurchased {
    return TRUE;
}
%end

// REMOVED: FCTraktIAPManager (class gone from binary)

%hook FCUpgradeToProViewController
-(bool) featureHasBought {
    return TRUE;
}
%end

// Add credits
@interface FCVersionView : UIView
@property (nonatomic, strong) UILabel *label;
@end

%hook FCVersionView
- (void)awakeFromNib {
    %orig;
    UILabel *label = (UILabel *)[self valueForKey:@"label"];
    if ([label.text containsString:@"Infuse Pro"] && ![label.text hasPrefix:@"Infuse Team •"]) {
        label.text = [NSString stringWithFormat:@"Infuse Team • %@", label.text];
    }
}
%end

// iOS 16 Crash Fix
%hook CKContainer
+ (id)defaultContainer {
    return nil;
}
+ (id)containerWithIdentifier:(id)arg1 {
    return nil;
}
%end