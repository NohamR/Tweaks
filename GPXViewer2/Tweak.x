#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CloudKit/CloudKit.h>
#import <mach-o/dyld.h>
#import <string.h>

%hook CKContainer
+ (id)defaultContainer { return nil; }
+ (id)containerWithIdentifier:(id)arg1 { return nil; }
%end

%ctor {
    @autoreleasepool {
        // Device UUID
        NSString *deviceUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (!deviceUUID) deviceUUID = @"<no-device-uuid>";

        // Compute SHA256 hashes for all product keys
        NSString *salt = @"-gpxviewerbyjg-";
        NSArray *productKeys = @[
            // @"family.gander.gpxviewer2.iap.nc.coffee",
            // @"family.gander.gpxviewer2.iap.nc.hikingsnack",
            @"family.gander.gpxviewer2.iap.nc.hikingmeal",
            // @"family.gander.gpxviewer2.easteregg.secret.access",
            // @"family.gander.gpxviewer2.iap.nc.level1",
            // @"family.gander.gpxviewer2.iap.nc.level2",
            // @"family.gander.gpxviewer2.iap.nc.level3",
        ];

        NSMutableArray *hashes = [NSMutableArray array];
        for (NSString *key in productKeys) {
            NSString *input = [NSString stringWithFormat:@"%@%@%@", deviceUUID, salt, key];
            const char *cstr = [input UTF8String];
            unsigned char digest[CC_SHA256_DIGEST_LENGTH];
            CC_SHA256(cstr, (CC_LONG)strlen(cstr), digest);
            NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
            for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
                [hex appendFormat:@"%02x", digest[i]];
            }
            [hashes addObject:hex];
        }

        // // empty hashes array
        // NSMutableArray *hashes = [NSMutableArray array];

        [[NSUserDefaults standardUserDefaults] setObject:hashes
                                                  forKey:@"proversionmanager.storage.purchasedproducts"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSLog(@"[GPXViewer2] Injected %lu product hashes", (unsigned long)[hashes count]);
    }
}
