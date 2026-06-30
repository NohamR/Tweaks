#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <Foundation/Foundation.h>

#define TARGET_MODULE       "ServerCat"
#define IDA_BASE            0x100000000

/*
 * EDIT THE HOOK ADDRESS OFFSET ACCORDING TO THE APP VERSION USED:
 *
 * ServerCat 1.30.0 (latest)  -> 0x10009CD24
 * ServerCat 1.6.4  (legacy)  -> 0x100454D70
 *
 * Find the address of `isPremiumActive` in IDA and set it below.
 */
#define ADDR_IS_PREMIUM     0x10009CD24

static int (*orig_isPremiumActive)(void);

static int hook_isPremiumActive(void) {
    return 1;
}

%ctor {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, TARGET_MODULE)) {
            uintptr_t base = (uintptr_t)_dyld_get_image_header(i);
            uintptr_t addr = base + (ADDR_IS_PREMIUM - IDA_BASE);
            MSHookFunction((void *)addr, (void *)hook_isPremiumActive, (void **)&orig_isPremiumActive);
            NSLog(@"[ServerCatPremium] Hooked isPremiumActive at 0x%lx", addr);
            return;
        }
    }
}

// iOS 16+ Crash Fix
%hook CKContainer
+ (id)defaultContainer {
    return nil;
}
+ (id)containerWithIdentifier:(id) arg1 {
    return nil;
}
%end
