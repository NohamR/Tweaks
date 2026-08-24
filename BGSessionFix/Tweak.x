#import <Foundation/Foundation.h>

%hook NSURLSessionConfiguration

+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithIdentifier:(NSString *)identifier {
    NSLog(@"[BGSessionFix] Redirecting background session '%@' to a default (foreground) config", identifier);
    return [NSURLSessionConfiguration defaultSessionConfiguration];
}

// // Deprecated pre-iOS8 entry point
// + (NSURLSessionConfiguration *)backgroundSessionConfiguration:(NSString *)identifier {
//     NSLog(@"[BGSessionFix] backgroundSessionConfiguration:'%@' (deprecated API) -> forcing default config", identifier);
//     return [NSURLSessionConfiguration defaultSessionConfiguration];
// }

%end