#import <substrate.h>
#import <mach-o/dyld.h>

%hook JailbreakDetection
- (bool)jailbroken {
    return FALSE;
}
%end