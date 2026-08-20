#import <substrate.h>
#import <Foundation/Foundation.h>

#define LOG(fmt, ...) NSLog(@"[NetworkLogger] " fmt, ##__VA_ARGS__)
#define MAX_BODY_LOG 2048

#pragma mark - Helpers

static int requestCount = 0;

static NSString *timestamp(void) {
    static NSDateFormatter *fmt;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fmt = [NSDateFormatter new];
        fmt.dateFormat = @"HH:mm:ss.SSS";
    });
    return [fmt stringFromDate:[NSDate date]];
}

static NSString *method(NSURLRequest *req) {
    return req.HTTPMethod.length ? req.HTTPMethod : @"GET";
}

static NSString *url(NSURLRequest *req) {
    return req.URL.absoluteString;
}

static NSString *formatHeaders(NSDictionary *hdrs) {
    if (!hdrs.count) return @"(none)";
    NSMutableString *s = [NSMutableString string];
    [hdrs enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *_) {
        [s appendFormat:@"\n    %@: %@", k, v];
    }];
    return s.copy;
}

static NSString *formatBody(NSData *data) {
    if (!data.length) return @"(empty)";
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str) return str.length > MAX_BODY_LOG ? [str substringToIndex:MAX_BODY_LOG] : str;
    return [NSString stringWithFormat:@"<binary %lu bytes>", (unsigned long)data.length];
}

static NSString *formatResponse(NSHTTPURLResponse *resp, NSData *body) {
    NSMutableString *s = [NSMutableString stringWithFormat:@"HTTP %ld", (long)resp.statusCode];
    [resp.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *_) {
        [s appendFormat:@"\n    %@: %@", k, v];
    }];
    if (body) [s appendFormat:@"\n    Body: %@", formatBody(body)];
    return s.copy;
}

static void logDataResponse(int num, NSURLRequest *req, NSData *data, NSURLResponse *resp, NSError *err) {
    if (err) {
        LOG(@"[%@] ◀ #%d %@ %@\n    Error: %@", timestamp(), num, method(req), url(req), err.localizedDescription);
    } else if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
        LOG(@"[%@] ◀ #%d %@ %@\n%@", timestamp(), num, method(req), url(req), formatResponse((NSHTTPURLResponse *)resp, data));
    } else {
        LOG(@"[%@] ◀ #%d %@ %@\n    (non-HTTP)", timestamp(), num, method(req), url(req));
    }
}

#define LOG_REQUEST(req, extra) \
    LOG(@"[%@] ▶ #%d %@ %@\n    Headers:%@%@", timestamp(), ++requestCount, method(req), url(req), formatHeaders(req.allHTTPHeaderFields), extra)

#define WRAP_DATA_HANDLER(orig, self, _cmd, req, handler, ...) \
    void (^wrapped)(NSData *, NSURLResponse *, NSError *) = ^(NSData *d, NSURLResponse *r, NSError *e) { \
        logDataResponse(requestCount, req, d, r, e); \
        if (handler) handler(d, r, e); \
    }; \
    return orig(self, _cmd, req, ##__VA_ARGS__, wrapped)

#pragma mark - NSURLSession Hooks

static NSURLSessionDataTask *(*orig_dataTaskReq)(NSURLSession *, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));

static NSURLSessionDataTask *hooked_dataTaskReq(NSURLSession *self, SEL _cmd, NSURLRequest *req, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *bodyLog = req.HTTPBody ? [NSString stringWithFormat:@"\n    Body: %@", formatBody(req.HTTPBody)] : @"";
    LOG_REQUEST(req, bodyLog);
    WRAP_DATA_HANDLER(orig_dataTaskReq, self, _cmd, req, handler);
}

static NSURLSessionDataTask *(*orig_dataTaskURL)(NSURLSession *, SEL, NSURL *, void (^)(NSData *, NSURLResponse *, NSError *));

static NSURLSessionDataTask *hooked_dataTaskURL(NSURLSession *self, SEL _cmd, NSURL *u, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    return hooked_dataTaskReq(self, _cmd, [NSURLRequest requestWithURL:u], handler);
}

static NSURLSessionUploadTask *(*orig_uploadTask)(NSURLSession *, SEL, NSURLRequest *, NSData *, void (^)(NSData *, NSURLResponse *, NSError *));

static NSURLSessionUploadTask *hooked_uploadTask(NSURLSession *self, SEL _cmd, NSURLRequest *req, NSData *body, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    LOG_REQUEST(req, [NSString stringWithFormat:@"\n    Body: %@", formatBody(body)]);
    WRAP_DATA_HANDLER(orig_uploadTask, self, _cmd, req, handler, body);
}

static NSURLSessionDownloadTask *(*orig_downloadTask)(NSURLSession *, SEL, NSURLRequest *, void (^)(NSURL *, NSURLResponse *, NSError *));

static NSURLSessionDownloadTask *hooked_downloadTask(NSURLSession *self, SEL _cmd, NSURLRequest *req, void (^handler)(NSURL *, NSURLResponse *, NSError *)) {
    LOG_REQUEST(req, @"");
    int num = requestCount;
    void (^wrapped)(NSURL *, NSURLResponse *, NSError *) = ^(NSURL *loc, NSURLResponse *resp, NSError *err) {
        if (err) {
            LOG(@"[%@] ◀ #%d %@ %@\n    Error: %@", timestamp(), num, method(req), url(req), err.localizedDescription);
        } else if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
            LOG(@"[%@] ◀ #%d %@ %@\n    (saved to %@)\n%@", timestamp(), num, method(req), url(req), loc.path, formatResponse((NSHTTPURLResponse *)resp, nil));
        }
        if (handler) handler(loc, resp, err);
    };
    return orig_downloadTask(self, _cmd, req, wrapped);
}

static void (*orig_resume)(NSURLSessionTask *, SEL);

static void hooked_resume(NSURLSessionTask *self, SEL _cmd) {
    LOG(@"[%@] ▶ RESUME %@ %@", timestamp(), method(self.currentRequest), url(self.currentRequest));
    orig_resume(self, _cmd);
}

#pragma mark - NSURLConnection (Legacy)

static void (*orig_asyncSend)(NSURLConnection *, SEL, NSURLRequest *, NSOperationQueue *, void (^)(NSURLResponse *, NSData *, NSError *));

static void hooked_asyncSend(NSURLConnection *self, SEL _cmd, NSURLRequest *req, NSOperationQueue *queue, void (^handler)(NSURLResponse *, NSData *, NSError *)) {
    LOG_REQUEST(req, @" (legacy)");
    void (^wrapped)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *r, NSData *d, NSError *e) {
        logDataResponse(requestCount, req, d, r, e);
        if (handler) handler(r, d, e);
    };
    orig_asyncSend(self, _cmd, req, queue, wrapped);
}

#pragma mark - Constructor

#define HOOK_MSG(cls, sel, hook, orig) \
    MSHookMessageEx(cls, @selector(sel), (IMP)hook, (IMP *)&orig)

%ctor {
    LOG(@"=== tweak loaded ===");

    Class session = NSClassFromString(@"NSURLSession");
    if (session) {
        HOOK_MSG(session, dataTaskWithRequest:completionHandler:, hooked_dataTaskReq, orig_dataTaskReq);
        HOOK_MSG(session, dataTaskWithURL:completionHandler:, hooked_dataTaskURL, orig_dataTaskURL);
        HOOK_MSG(session, uploadTaskWithRequest:fromData:completionHandler:, hooked_uploadTask, orig_uploadTask);
        HOOK_MSG(session, downloadTaskWithRequest:completionHandler:, hooked_downloadTask, orig_downloadTask);
    }

    Class task = NSClassFromString(@"__NSCFLocalDataTask") ?: NSClassFromString(@"NSURLSessionDataTask");
    if (task) HOOK_MSG(task, resume, hooked_resume, orig_resume);

    Class conn = NSClassFromString(@"NSURLConnection");
    if (conn) HOOK_MSG(conn, sendAsynchronousRequest:queue:completionHandler:, hooked_asyncSend, orig_asyncSend);

    LOG(@"=== all hooks installed ===");
}