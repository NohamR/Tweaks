#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <Foundation/Foundation.h>

%hook TextasticStore
- (bool)textasticProActive {
    return TRUE;
}
- (bool)isVPPReceipt {
    return FALSE;
}
- (bool)isLegacyPurchase {
    return TRUE;
}
- (bool)isLegacyPurchaseOrProActive {
    return TRUE;
}
- (bool)isLegacyPurchaseOrProActiveOrTestFlight {
    return TRUE;
}
%end

// iOS 16 Crash Fix
%hook CKContainer
+ (id)defaultContainer {
    return nil;
}
+ (id)containerWithIdentifier:(id) arg1 {
    return nil;
}
%end