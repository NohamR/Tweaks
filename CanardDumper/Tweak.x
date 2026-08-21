#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <string>

static UIViewController *CanardTopViewController(UIViewController *viewController) {
    if (viewController.presentedViewController) {
        return CanardTopViewController(viewController.presentedViewController);
    }
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return CanardTopViewController([(UINavigationController *)viewController visibleViewController]);
    }
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return CanardTopViewController([(UITabBarController *)viewController selectedViewController]);
    }
    return viewController;
}

static void CanardPresentShareSheet(NSString *filePath) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *application = [UIApplication sharedApplication];
        UIWindow *window = application.keyWindow;
        if (!window) {
            for (UIWindow *candidate in application.windows) {
                if (candidate.isKeyWindow) {
                    window = candidate;
                    break;
                }
            }
        }

        UIViewController *viewController = CanardTopViewController(window.rootViewController);
        if (!viewController) {
            NSLog(@"[CanardDumper] Unable to present file share sheet");
            return;
        }

        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        UIPopoverPresentationController *popover = shareController.popoverPresentationController;
        popover.sourceView = viewController.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(viewController.view.bounds), CGRectGetMidY(viewController.view.bounds), 0, 0);
        [viewController presentViewController:shareController animated:YES completion:nil];
    });
}

static NSString *CanardArchivePassword;
static int CanardLastSavedReadSize = -1;

static NSString *CanardPasswordFileComponent(NSString *password) {
    if (password.length == 0) {
        return @"unknown";
    }

    NSCharacterSet *invalidCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/:\\?%*|\"<>\n\r\t"];
    NSString *safePassword = [[password componentsSeparatedByCharactersInSet:invalidCharacters] componentsJoinedByString:@"_"];
    return safePassword.length > 0 ? safePassword : @"unknown";
}

%hook DlyArchiveReader

-(BOOL)setUpArchiveError:(id *)error {
    NSLog(@"[CanardDumper] DlyArchiveReader setUpArchiveError: error=%p", error);
    return %orig;
}

-(NSString *)password {
    NSString *pwd = %orig;
    CanardArchivePassword = [pwd copy];
    NSLog(@"[CanardDumper] DlyArchiveReader password: %@", pwd);
    return pwd;
}

-(int)getDocumentSize {
    int size = %orig;
    NSLog(@"[CanardDumper] DlyArchiveReader getDocumentSize: %d", size);
    return size;
}

-(NSData *)readDataAt:(int)offset withSize:(int)size {
    NSLog(@"[CanardDumper] DlyArchiveReader readDataAt: offset=%d withSize=%d", offset, size);
    NSArray<NSString *> *callStack = [NSThread callStackSymbols];
    NSLog(@"[CanardDumper] Backtrace:\n%@", [callStack componentsJoinedByString:@"\n"]);
    NSData *data = %orig;
    if (data.length > 0 && size != CanardLastSavedReadSize) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dumpDir = [docsPath stringByAppendingPathComponent:@"CanardDumps"];
        if (![fm fileExistsAtPath:dumpDir]) {
            [fm createDirectoryAtPath:dumpDir withIntermediateDirectories:YES attributes:nil error:nil];
        }

        NSString *passwordComponent = CanardPasswordFileComponent(CanardArchivePassword);
        NSString *fileName = [NSString stringWithFormat:@"file_%@.pdf", passwordComponent];
        NSString *filePath = [dumpDir stringByAppendingPathComponent:fileName];
        if ([data writeToFile:filePath atomically:YES]) {
            CanardLastSavedReadSize = size;
            NSLog(@"[CanardDumper] Saved readDataAt data to %@ (%lu bytes)", filePath, (unsigned long)data.length);
            CanardPresentShareSheet(filePath);
        } else {
            NSLog(@"[CanardDumper] Failed to save readDataAt data to %@", filePath);
        }
    }
    return data;
}

%end

%hook DlyCoreArchive

-(instancetype)initWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"[CanardDumper] DlyCoreArchive initWithArchivePath: %@ error=%p", path, error);
    return %orig;
}

+(instancetype)newWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"[CanardDumper] DlyCoreArchive newWithArchivePath: %@ error=%p", path, error);
    return %orig;
}

-(BOOL)openArchiveWithType:(NSUInteger)type error:(id *)error {
    NSLog(@"[CanardDumper] DlyCoreArchive openArchiveWithType: %lu error=%p", (unsigned long)type, error);
    return %orig;
}

%end