#import <Foundation/Foundation.h>

// GoodnotesPro — BadNotes port (c22dev)
// https://github.com/c22dev/badnotes

#pragma mark - Helpers

static NSString *randomTransactionID(void) {
    static NSString *cached = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableString *s = [NSMutableString stringWithFormat:@"%u", arc4random_uniform(9) + 1];
        for (int i = 0; i < 14; i++) [s appendFormat:@"%u", arc4random_uniform(10)];
        cached = [s copy];
    });
    return cached;
}

static NSString *subscriberUID(NSString *url) {
    if (!url) return nil;
    NSRange r = [url rangeOfString:@"/v1/subscribers/"];
    if (r.location == NSNotFound) return nil;
    NSString *tail = [url substringFromIndex:r.location + r.length];
    NSRange q = [tail rangeOfString:@"?"];
    if (q.location != NSNotFound) tail = [tail substringToIndex:q.location];
    if (tail.length == 0 || [tail rangeOfString:@"/"].location != NSNotFound) return nil;
    return tail;
}

static NSData *injectEntitlements(NSData *original, NSString *uid) {
    static NSString *farFuture = @"2099-12-31T23:59:59Z";
    static NSString *past = @"2025-01-01T00:00:00Z";

    NSString *productId = @"com.goodnotes.pro_7dt_1y_3599";
    NSString *lifetimeId = @"com.goodnotes.gn6_one_time_unlock_3999";

    NSMutableDictionary *root = nil;
    if (original.length) {
        id parsed = [NSJSONSerialization JSONObjectWithData:original options:0 error:nil];
        if ([parsed isKindOfClass:[NSDictionary class]]) root = [parsed mutableCopy];
    }
    if (!root) root = [NSMutableDictionary dictionary];

    NSMutableDictionary *sub = [root[@"subscriber"] isKindOfClass:[NSDictionary class]]
        ? [root[@"subscriber"] mutableCopy]
        : [NSMutableDictionary dictionary];

    if (!sub[@"original_app_user_id"]) sub[@"original_app_user_id"] = uid ?: @"app_user";
    if (!sub[@"first_seen"]) sub[@"first_seen"] = past;
    sub[@"last_seen"] = @"2025-01-02T13:37:37Z";
    if (!sub[@"non_subscriptions"]) sub[@"non_subscriptions"] = @{};
    if (!sub[@"other_purchases"]) sub[@"other_purchases"] = @{};
    if (!sub[@"original_application_version"]) sub[@"original_application_version"] = @"7";
    if (!sub[@"original_purchase_date"]) sub[@"original_purchase_date"] = past;

    NSDictionary *access = @{
        @"expires_date": farFuture,
        @"grace_period_expires_date": [NSNull null],
        @"product_identifier": productId,
        @"purchase_date": past,
        @"original_purchase_date": past,
        @"plan_key": @"pro",
    };

    sub[@"entitlements"] = @{
        @"apple_access": access,
        @"crossplatform_access": access,
    };

    sub[@"current_plans"] = @{
        @"base": @{@"product_identifier": productId, @"type": @"subscription", @"plan_key": @"pro"},
        @"ai": [NSNull null],
    };

    NSDictionary *subscription = @{
        @"is_sandbox": @NO,
        @"ownership_type": @"PURCHASED",
        @"expires_date": farFuture,
        @"original_purchase_date": past,
        @"period_type": @"normal",
        @"purchase_date": past,
        @"store": @"app_store",
        @"store_transaction_id": randomTransactionID(),
        @"unsubscribe_detected_at": [NSNull null],
        @"grace_period_expires_date": [NSNull null],
        @"billing_issues_detected_at": [NSNull null],
        @"refunded_at": [NSNull null],
        @"auto_resume_date": [NSNull null],
        @"plan_key": @"pro",
        @"pending_product_id": productId,
        @"pending_product_plan_key": @"pro",
        @"pending_subscription_period": @"P1Y",
        @"quotas": @{@"ai": @{@"quota": @525, @"period": @"P1M"}},
        @"management_url": @"https://apps.apple.com/account/subscriptions",
        @"renewal_type": @"auto",
        @"subscription_period": @"P1Y",
        @"app_type": @"ios",
    };

    sub[@"subscriptions"] = @{
        productId: subscription,
        lifetimeId: @{
            @"expires_date": farFuture,
            @"original_purchase_date": past,
            @"purchase_date": past,
            @"ownership_type": @"PURCHASED",
            @"store": @"app_store",
        },
    };

    sub[@"quotas"] = @{@"ai": @{@"quota": @525, @"period": @"P1M"}};
    sub[@"management_url"] = @"https://apps.apple.com/account/subscriptions";

    root[@"subscriber"] = sub;
    root[@"request_date"] = @"2025-01-01T13:37:37Z";
    root[@"request_date_ms"] = @1735732800000;

    NSData *out = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
    return out ?: original;
}

#pragma mark - Hooks

%hook NSBundle
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    static NSDictionary *overrides = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        overrides = @{
            @"subscription_billing_period_yearly": @"BadNotes",
            @"subscription_details_subtitle_pro": @"Cracked by Constantin Clerc (c22dev) :)",
        };
    });
    NSString *override = overrides[key];
    return override ?: %orig;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    BOOL isOfferings = [url containsString:@"offerings"];
    NSString *uid = isOfferings ? nil : subscriberUID(url);
    if (!uid && !isOfferings && [url containsString:@"receipt"]) uid = @"app_user";

    NSURLRequest *reqToUse = request;
    if (uid) {
        NSMutableURLRequest *mr = [request mutableCopy];
        [mr setValue:nil forHTTPHeaderField:@"If-None-Match"];
        [mr setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
        [mr setValue:nil forHTTPHeaderField:@"X-RevenueCat-ETag"];
        mr.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        reqToUse = mr;
    }

    void (^wrapped)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (uid && !err) {
            NSData *newData = injectEntitlements([data isKindOfClass:[NSData class]] ? data : nil, uid);
            NSURLResponse *respToUse = resp;
            if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *hr = (NSHTTPURLResponse *)resp;
                NSMutableDictionary *hdrs = [[hr allHeaderFields] mutableCopy] ?: [NSMutableDictionary dictionary];
                for (NSString *k in hdrs.allKeys)
                    if ([k caseInsensitiveCompare:@"ETag"] == NSOrderedSame) [hdrs removeObjectForKey:k];
                hdrs[@"Content-Type"] = @"application/json";
                hdrs[@"Content-Length"] = @(newData.length).stringValue;
                respToUse = [[NSHTTPURLResponse alloc] initWithURL:hr.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:hdrs];
            }
            if (completionHandler) completionHandler(newData, respToUse, err);
            return;
        }
        if (completionHandler) completionHandler(data, resp, err);
    };

    return %orig(reqToUse, wrapped);
}
%end

%ctor {
    NSLog(@"[GoodnotesPro] Loaded — BadNotes port by c22dev");
}
