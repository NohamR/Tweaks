#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <Foundation/Foundation.h>

#define TARGET_MODULE   "Volkswagen"
#define IDA_BASE        0x100000000

// sysctl P_TRACED check : always return 0 (no debugger)
#define ADDR_SYSCTL_DEBUG_CHECK     0x10081D5A4

// ptrace(PT_DENY_ATTACH) + FishHook installer : NOP the whole thing
#define ADDR_PTRACE_FISHHOOK        0x10081D704

// JailbreakDetection orchestrator (8 checks) : always return 1 (clean)
#define ADDR_JB_ORCHESTRATOR        0x100824E9C

// Individual JB sub-checks : each returns 1 (no jailbreak found)
#define ADDR_JB_FILE_EXIST          0x100823E38   // type 1: stat/access
#define ADDR_JB_FILE_READABLE       0x100824238   // type 2: fopen/isReadable
#define ADDR_JB_SANDBOX_ESCAPE      0x1008245FC   // type 3: write test + fork
#define ADDR_JB_SYMLINK             0x100824A14   // type 5: symlink resolve
#define ADDR_JB_DYLIB_NAMES         0x100824C7C   // type 6: _dyld_get_image_name scan

#define ADDR_SECURITY_CHECK_BFC     0x100828BFC   // sub_100828BFC(v10) & 1
#define ADDR_SECURITY_CHECK_D20     0x100828D20   // sub_100828D20() & 1
#define ADDR_SECURITY_CHECK_CD4     0x100828CD4   // sub_100828CD4() : bool


static void *(*orig_sysctl_debug)(void);
static void *hooked_sysctl_debug(void) { NSLog(@"[VWTweak] hooked_sysctl_debug called"); return 0; }

static void (*orig_ptrace_fishhook)(void);
static void hooked_ptrace_fishhook(void) { NSLog(@"[VWTweak] hooked_ptrace_fishhook called"); return; }

static uint64_t (*orig_jb_orchestrator)(void);
static uint64_t hooked_jb_orchestrator(void) { NSLog(@"[VWTweak] hooked_jb_orchestrator called"); return 1; }

// static uint64_t (*orig_jb_file_exist)(void);
// static uint64_t hooked_jb_file_exist(void) { NSLog(@"[VWTweak] hooked_jb_file_exist called"); return 1; }

// static uint64_t (*orig_jb_file_readable)(void);
// static uint64_t hooked_jb_file_readable(void) { NSLog(@"[VWTweak] hooked_jb_file_readable called"); return 1; }

// static uint64_t (*orig_jb_sandbox_escape)(void);
// static uint64_t hooked_jb_sandbox_escape(void) { NSLog(@"[VWTweak] hooked_jb_sandbox_escape called"); return 1; }

// static uint64_t (*orig_jb_symlink)(void);
// static uint64_t hooked_jb_symlink(void) { NSLog(@"[VWTweak] hooked_jb_symlink called"); return 1; }

// static uint64_t (*orig_jb_dylib_names)(void);
// static uint64_t hooked_jb_dylib_names(void) { NSLog(@"[VWTweak] hooked_jb_dylib_names called"); return 1; }

static uint64_t (*orig_security_check_bfc)(uint64_t);
static uint64_t hooked_security_check_bfc(uint64_t arg) { NSLog(@"[VWTweak] hooked_security_check_bfc(%llu) called", arg); return 0; }

static uint64_t (*orig_security_check_d20)(void);
static uint64_t hooked_security_check_d20(void) { NSLog(@"[VWTweak] hooked_security_check_d20 called"); return 0; }

static uint64_t (*orig_security_check_cd4)(void);
static uint64_t hooked_security_check_cd4(void) { NSLog(@"[VWTweak] hooked_security_check_cd4 called"); return 0; }


static void hookAt(uintptr_t base, uintptr_t ida_addr, void *hook, void **orig) {
    uintptr_t real = base + (ida_addr - IDA_BASE);
    MSHookFunction((void *)real, hook, orig);
    NSLog(@"[VWTweak] Hooked 0x%lx (slide base 0x%lx)", real, base);
}

%ctor {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name || !strstr(name, TARGET_MODULE))
            continue;

        uintptr_t base = (uintptr_t)_dyld_get_image_header(i);
        NSLog(@"[VWTweak] Found %s at base 0x%lx", name, base);

        hookAt(base, ADDR_SYSCTL_DEBUG_CHECK,  (void *)hooked_sysctl_debug,    (void **)&orig_sysctl_debug);
        hookAt(base, ADDR_PTRACE_FISHHOOK,     (void *)hooked_ptrace_fishhook, (void **)&orig_ptrace_fishhook);

        hookAt(base, ADDR_JB_ORCHESTRATOR,     (void *)hooked_jb_orchestrator, (void **)&orig_jb_orchestrator);

        // hookAt(base, ADDR_JB_FILE_EXIST,       (void *)hooked_jb_file_exist,    (void **)&orig_jb_file_exist);
        // hookAt(base, ADDR_JB_FILE_READABLE,    (void *)hooked_jb_file_readable, (void **)&orig_jb_file_readable);
        // hookAt(base, ADDR_JB_SANDBOX_ESCAPE,   (void *)hooked_jb_sandbox_escape,(void **)&orig_jb_sandbox_escape);
        // hookAt(base, ADDR_JB_SYMLINK,          (void *)hooked_jb_symlink,       (void **)&orig_jb_symlink);
        // hookAt(base, ADDR_JB_DYLIB_NAMES,      (void *)hooked_jb_dylib_names,   (void **)&orig_jb_dylib_names);

        hookAt(base, ADDR_SECURITY_CHECK_BFC,  (void *)hooked_security_check_bfc,(void **)&orig_security_check_bfc);
        hookAt(base, ADDR_SECURITY_CHECK_D20,  (void *)hooked_security_check_d20,(void **)&orig_security_check_d20);
        hookAt(base, ADDR_SECURITY_CHECK_CD4,  (void *)hooked_security_check_cd4,(void **)&orig_security_check_cd4);

        return;
    }

    NSLog(@"[VWTweak] Target module '%s' not found in dyld image list", TARGET_MODULE);
}