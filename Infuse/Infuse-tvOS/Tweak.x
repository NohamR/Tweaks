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
@interface FCTVSettingsController : UITableViewController
- (UITableView *)tableView;
@end

%hook FCTVSettingsController
- (void)setUpAppVersionLabel {
    %orig;

    UITableView *tv = [self tableView];
    UILabel *footer = (UILabel *)tv.tableFooterView;

    // Guard: footer is nil/not a UILabel
    if (![footer isKindOfClass:[UILabel class]]) return;

    NSAttributedString *current = footer.attributedText;
    if (!current.length) return;

    // Handles repeated calls
    if ([current.string hasPrefix:@"Infuse Team  •"]) return;

    NSDictionary *attrs = [current attributesAtIndex:0 effectiveRange:nil];
    NSMutableAttributedString *mas = [current mutableCopy];
    NSAttributedString *prefix = [[NSAttributedString alloc]
        initWithString:@"Infuse Team  • "
            attributes:attrs];
    [mas insertAttributedString:prefix atIndex:0];
    footer.attributedText = mas;
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

%hook NSPersistentCloudKitContainerOptions
- (id)initWithContainerIdentifier:(id)arg1 {
    return nil;
}
%end

%hook CKRecordID
- (id)initWithRecordName:(id)arg1 {
    return nil;
}
- (id)initWithRecordName:(id)arg1 zoneID:(id)arg2 {
    return nil;
}
%end

%hook CKSystemSharingUIObserver
- (id)initWithContainer:(id)arg1 {
    return nil;
}
%end

%hook NSFileManager
- (id)ubiquityIdentityToken {
    return nil;
}
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [docPath stringByAppendingPathComponent:groupIdentifier];
    NSURL *url = [NSURL fileURLWithPath:path];

    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return url;
}
%end