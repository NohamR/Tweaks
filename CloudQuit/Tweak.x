#import <substrate.h>
#import <Foundation/Foundation.h>

// iOS 16+ Crash Fix
%hook CKContainer
+ (id)defaultContainer {
    return nil;
}
+ (id)containerWithIdentifier:(id) arg1 {
    return nil;
}
%end