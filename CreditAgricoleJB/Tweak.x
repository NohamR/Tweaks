#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <Foundation/Foundation.h>

#define TARGET_MODULE       "nmb_prod"
#define IDA_BASE            0x100000000
#define ADDR_JB_DETECT     0x10055F914  // Address of target function in IDA (adjust if needed)

static void *(*original_sub)(void);

static void *hooked_sub(void) {
    return 0;
}

%ctor {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, TARGET_MODULE)) {
            uintptr_t base = (uintptr_t)_dyld_get_image_header(i);
            uintptr_t addr = base + (ADDR_JB_DETECT - IDA_BASE);
            MSHookFunction((void *)addr, (void *)hooked_sub, (void **)&original_sub);
            NSLog(@"[CreditAgricoleTweak] Hooked function at 0x%lx", addr);
            return;
        }
    }
}