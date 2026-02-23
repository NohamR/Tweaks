#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <Foundation/Foundation.h>

#define TARGET_MODULE       "ServerCat"
#define IDA_BASE            0x100000000
#define ADDR_IS_PREMIUM     0x10009CD24  // Address of "isPremiumActive" in IDA (adjust if needed)

static int (*orig_isPremiumActive)();
static int hook_isPremiumActive() { 
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

// iOS 16 Crash Fix
%hook CKContainer
+ (id)defaultContainer {
    return nil;
}

+ (id)containerWithIdentifier:(id)arg1 {
    arg1 = nil;
    return nil;
    return %orig;
}
%end