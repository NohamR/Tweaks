// log stream --predicate 'process == "HatchDragons" AND eventMessage contains "HGH" ' --level default --style compact

#import <substrate.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

#define LOG(fmt, ...) NSLog(@"[HGH] " fmt, ##__VA_ARGS__)

#pragma mark - IL2CPP String Layout

#define IL2CPP_STRING_LENGTH_OFFSET  0x10
#define IL2CPP_STRING_CHARS_OFFSET   0x14
#define IL2CPP_DICT_ENTRIES_OFFSET   0x18
#define IL2CPP_DICT_COUNT_OFFSET     0x20
#define IL2CPP_ARRAY_CAPACITY_OFFSET 0x18
#define IL2CPP_ARRAY_DATA_OFFSET     0x20
#define IL2CPP_DICT_ENTRY_SIZE       24
#define IL2CPP_STRING_MAX_LENGTH     (1 << 16)

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
    static NSDateFormatter *fmt;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss.SSS";
    });
    return [fmt stringFromDate:[NSDate date]];
}

static NSString *il2cppString(void *str) {
    if (!str) return nil;
    uint32_t len = *(uint32_t *)((char *)str + IL2CPP_STRING_LENGTH_OFFSET);
    if (len == 0 || len > IL2CPP_STRING_MAX_LENGTH) return @"(empty?)";
    NSString *s = [[NSString alloc] initWithBytes:((char *)str + IL2CPP_STRING_CHARS_OFFSET)
                                           length:len * 2
                                         encoding:NSUTF16LittleEndianStringEncoding];
    return s ?: @"(unparseable)";
}

static NSString *il2cppHeaders(void *dict) {
    if (!dict) return @"(nil)";

    void *entriesArr = *(void **)((char *)dict + IL2CPP_DICT_ENTRIES_OFFSET);
    if (!entriesArr) return @"(empty)";

    uint64_t cap = *(uint64_t *)((char *)entriesArr + IL2CPP_ARRAY_CAPACITY_OFFSET);
    if (cap == 0) return @"(empty)";

    NSMutableString *out = [NSMutableString string];
    uint32_t used = 0;
    char *data = (char *)entriesArr + IL2CPP_ARRAY_DATA_OFFSET;

    for (uint64_t i = 0; i < cap; i++) {
        char *e = data + i * IL2CPP_DICT_ENTRY_SIZE;
        int32_t hashCode = *(int32_t *)e;
        void *key = *(void **)(e + 8);
        void *value = *(void **)(e + 16);

        if (hashCode < 0 || !key) continue;
        [out appendFormat:@"\n        %@: %@", il2cppString(key),
         value ? il2cppString(value) : @"(null)"];
        used++;
    }

    return used ? out : @"(empty)";
}

static void logRequest(NSString *method, void *self, NSString *body) {
    requestCount++;
    NSString *uri = il2cppString(*(void **)((char *)self + 0x10));
    NSString *platform = il2cppString(*(void **)((char *)self + 0x20));
    void *hdrs = *(void **)((char *)self + 0x18);

    NSMutableString *msg = [NSMutableString stringWithFormat:
        @"[%@] ▶ %@ #%d self=%p\n    URI: %@\n    Headers:%@\n    Platform: %@",
        timestampString(), method, requestCount, self, uri, il2cppHeaders(hdrs), platform];

    if (body) {
        [msg appendFormat:@"\n    Body: %@", body];
    }

    LOG(@"%@", msg);
}

#pragma mark - CI.HttpClient.RequestHandler Hooks

static void (*orig_performGet)(void *, void *);
static void (*orig_postJson)(void *, void *, void *);

static void hooked_performGet(void *self, void *handler) {
    logRequest(@"CI.GET", self, nil);
    orig_performGet(self, handler);
}

static void hooked_postJson(void *self, void *payload, void *handler) {
    logRequest(@"CI.POST", self, payload ? il2cppString(payload) : nil);
    orig_postJson(self, payload, handler);
}

#pragma mark - PlayerInventory Currency Hooks

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

#pragma mark - Hook Installation

#define HOOK(base, rva, hook, orig) \
    MSHookFunction((void *)((base) + (rva)), (void *)(hook), (void **)&(orig))

%ctor {
    uintptr_t base = getImageBase();
    if (!base) {
        LOG(@"UnityFramework not found, aborting");
        return;
    }

    LOG(@"UnityFramework base = 0x%lx", (unsigned long)base);

    HOOK(base, 0x58FE798, hooked_performGet, orig_performGet);
    HOOK(base, 0x58FED8C, hooked_postJson,  orig_postJson);
    HOOK(base, 0x57DC6EC, hooked_modifyHC,  orig_modifyHC);
    HOOK(base, 0x57E4978, hooked_modifySC,  orig_modifySC);

    LOG(@"All hooks installed");
}