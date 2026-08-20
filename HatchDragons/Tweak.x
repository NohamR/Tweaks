// log stream --predicate 'process == "HatchDragons" AND eventMessage contains "HGH" ' --level default --style compact

#import <substrate.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

#define LOG(fmt, ...) NSLog(@"[HGH] " fmt, ##__VA_ARGS__)

#pragma mark - Helpers

static uintptr_t getImageBase(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

static int requestCount = 0;

static NSString *timestampString(void) {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss.SSS";
    return [fmt stringFromDate:[NSDate date]];
}

// Read a System.String via its native layout (NOT ARC / Obj-C casts).
// struct System.String { klass; monitor; int32_t _stringLength(utf16 code units); uint16_t chars[]; }
static NSString *il2cppString(void *str) {
    if (!str) return nil;
    uint32_t len = *(uint32_t *)((char *)str + 0x10);   // UTF-16 code units
    if (len == 0 || len > 1 << 16) return @"(empty?)";
    NSString *s = [[NSString alloc] initWithBytes:((char *)str + 0x14)
                                           length:len * 2     // byte length
                                         encoding:NSUTF16LittleEndianStringEncoding];
    return s ?: @"(unparseable)";
}

// Render a System.Collections.Generic.Dictionary<string,string> via its native
// layout. Fields: _buckets@0x10, _entries@0x18 (Entry array), _count@0x20.
// Entry = { int32 hashCode; int32 next; void* key; void* value; }  (24 bytes).
// Array: obj(16) + bounds(8) + max_length(8) => data at +0x20, capacity at +0x18.
static NSString *il2cppHeaders(void *dict) {
    if (!dict) return @"(nil)";
    void *entriesArr = *(void **)((char *)dict + 0x18);
    uint64_t cap = entriesArr ? *(uint64_t *)((char *)entriesArr + 0x18) : 0;
    if (!entriesArr || cap == 0) return @"(empty)";

    NSMutableString *out = [NSMutableString string];
    uint32_t used = 0;
    char *data = (char *)entriesArr + 0x20;
    for (uint64_t i = 0; i < cap; i++) {
        char *e = data + i * 24;
        int32_t hashCode = *(int32_t *)e;
        void *key = *(void **)(e + 8);
        void *value = *(void **)(e + 16);
        if (hashCode < 0 || !key) continue;               // free slot
        [out appendFormat:@"\n        %@: %@", il2cppString(key),
         value ? il2cppString(value) : @"(null)"];
        used++;
    }
    return used ? out : @"(empty)";
}

#pragma mark - CI.HttpClient.RequestHandler hooks

// IDA virtual addresses (before ASLR slide), relative to UnityFramework image:
//   PerformGet(ProcessDataDelegateString)  = 0x58FE798
//   PostJson(string, ProcessDataDelegateBytes) = 0x58FED8C

static void (*orig_performGet)(void *, void *);
static void (*orig_postJson)(void *, void *, void *);

// NOTE: self / handler / payload are il2cpp objects — type them as void* so ARC
// never objc_retain/objc_msgSends them. il2cpp methods take NO SEL; the arg
// list here must match the raw signature (self, ...) exactly.
static void hooked_performGet(void *self, void *handler) {
    requestCount++;
    NSString *uri = il2cppString(*(void **)((char *)self + 0x10));
    NSString *platform = il2cppString(*(void **)((char *)self + 0x20));
    void *hdrs = *(void **)((char *)self + 0x18);

    LOG(@"[%@] ▶ CI.GET #%d self=%p\n    URI: %@\n    Headers:%@\n    Platform: %@",
        timestampString(), requestCount, self,
        uri, il2cppHeaders(hdrs), platform);

    // Pass the ORIGINAL handler through unchanged. We do NOT retain/wrap it:
    // il2cpp expects a MulticastDelegate, and ARC must never retain il2cpp objs.
    orig_performGet(self, handler);
}

static void hooked_postJson(void *self, void *payload, void *handler) {
    requestCount++;
    NSString *uri = il2cppString(*(void **)((char *)self + 0x10));
    NSString *platform = il2cppString(*(void **)((char *)self + 0x20));
    void *hdrs = *(void **)((char *)self + 0x18);
    NSString *body = payload ? il2cppString(payload) : @"(none)";

    LOG(@"[%@] ▶ CI.POST #%d self=%p\n    URI: %@\n    Headers:%@\n    Platform: %@\n    Body: %@",
        timestampString(), requestCount, self,
        uri, il2cppHeaders(hdrs), platform, body);

    orig_postJson(self, payload, handler);
}

#pragma mark - PlayerInventory currency hooks

// NurtureGamePlatform.Managers.PlayerInventory
//   ModifyHC(long value, string information = "", int quantity = 1)  IDA RVA: 0x57DC6EC
//   ModifySC(long value, string information = "")                    IDA RVA: 0x57E4978
//
// Negate negative amounts so every spend becomes a gain (cheat).

static void (*orig_modifyHC)(void *, long, void *, int);
static void (*orig_modifySC)(void *, long, void *);

static void hooked_modifyHC(void *self, long amount, void *info, int quantity) {
    if (amount < 0) {
        LOG(@"ModifyHC %ld → %ld (negated)", amount, -amount);
        amount = -amount;
    }
    orig_modifyHC(self, amount, info, quantity);
}

static void hooked_modifySC(void *self, long amount, void *info) {
    if (amount < 0) {
        LOG(@"ModifySC %ld → %ld (negated)", amount, -amount);
        amount = -amount;
    }
    orig_modifySC(self, amount, info);
}

#pragma mark - Constructor

%ctor {
    LOG(@"=== tweak loaded ===");

    uintptr_t base = getImageBase();
    if (!base) {
        LOG(@"UnityFramework image not found, skipping CI hooks");
        return;
    }
    LOG(@"UnityFramework base = 0x%lx", (unsigned long)base);

    // PerformGet(ProcessDataDelegateString) - IDA RVA: 0x58FE798
    {
        void *addr = (void *)(base + 0x58FE798);
        LOG(@"hooking PerformGet(string) at 0x%lx", (unsigned long)addr);
        MSHookFunction(addr, (void *)hooked_performGet, (void **)&orig_performGet);
        LOG(@"hooked PerformGet(string) — orig=%p", orig_performGet);
    }

    // PostJson(string payload, ProcessDataDelegateBytes handler) - IDA RVA: 0x58FED8C
    {
        void *addr = (void *)(base + 0x58FED8C);
        LOG(@"hooking PostJson at 0x%lx", (unsigned long)addr);
        MSHookFunction(addr, (void *)hooked_postJson, (void **)&orig_postJson);
        LOG(@"hooked PostJson — orig=%p", orig_postJson);
    }

    // ModifyHC(long, string, int) - IDA RVA: 0x57DC6EC
    {
        void *addr = (void *)(base + 0x57DC6EC);
        LOG(@"hooking ModifyHC at 0x%lx", (unsigned long)addr);
        MSHookFunction(addr, (void *)hooked_modifyHC, (void **)&orig_modifyHC);
        LOG(@"hooked ModifyHC — orig=%p", orig_modifyHC);
    }

    // ModifySC(long, string) - IDA RVA: 0x57E4978
    {
        void *addr = (void *)(base + 0x57E4978);
        LOG(@"hooking ModifySC at 0x%lx", (unsigned long)addr);
        MSHookFunction(addr, (void *)hooked_modifySC, (void **)&orig_modifySC);
        LOG(@"hooked ModifySC — orig=%p", orig_modifySC);
    }

    LOG(@"=== all hooks installed ===");
}