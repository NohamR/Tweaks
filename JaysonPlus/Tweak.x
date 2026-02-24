#import <substrate.h>

%hook UnlockEverythingManager
- (BOOL)haveUnlockedEverything {
	return TRUE;
}

- (void)setHaveUnlockedEverything:(BOOL)unlocked {
	%orig(YES);
}
%end
