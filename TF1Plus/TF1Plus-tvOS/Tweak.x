#import <Foundation/Foundation.h>

%hook FWRequestConfiguration
- (id)initWithServerURL:(id)arg1 playerProfile:(id)arg2 {
    return self;
}
%end
