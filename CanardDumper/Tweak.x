#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - Constants

static NSString *const kCanardLogTag = @"[CanardDumper]";
static NSString *const kCanardDumpDirectoryName = @"CanardDumps";

#pragma mark - State

static NSString *CanardArchivePassword;
static int CanardLastSavedReadSize = -1;

#pragma mark - UI Helpers

static UIViewController *CanardTopViewController(UIViewController *viewController) {
    if (!viewController) return nil;
    
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
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }

        UIViewController *topVC = CanardTopViewController(keyWindow.rootViewController);
        if (!topVC) {
            NSLog(@"%@ Unable to present share sheet", kCanardLogTag);
            return;
        }

        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        shareController.popoverPresentationController.sourceView = topVC.view;
        shareController.popoverPresentationController.sourceRect = CGRectMake(
            CGRectGetMidX(topVC.view.bounds),
            CGRectGetMidY(topVC.view.bounds),
            0, 0
        );
        [topVC presentViewController:shareController animated:YES completion:nil];
    });
}

#pragma mark - File Helpers

static NSString *CanardSanitizedFilename(NSString *password) {
    if (password.length == 0) return @"unknown";

    NSCharacterSet *invalidChars = [NSCharacterSet characterSetWithCharactersInString:@"/:\\?%*|\"<>\n\r\t"];
    NSString *sanitized = [[password componentsSeparatedByCharactersInSet:invalidChars] componentsJoinedByString:@"_"];
    return sanitized.length > 0 ? sanitized : @"unknown";
}

static NSString *CanardDumpDirectory() {
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsPath stringByAppendingPathComponent:kCanardDumpDirectoryName];
}

static bool CanardSaveData(NSData *data, NSString *password) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dumpDir = CanardDumpDirectory();

    if (![fm fileExistsAtPath:dumpDir]) {
        [fm createDirectoryAtPath:dumpDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *fileName = [NSString stringWithFormat:@"file_%@.pdf", CanardSanitizedFilename(password)];
    NSString *filePath = [dumpDir stringByAppendingPathComponent:fileName];

    if ([data writeToFile:filePath atomically:YES]) {
        NSLog(@"%@ Saved to %@ (%lu bytes)", kCanardLogTag, filePath, (unsigned long)data.length);
        CanardPresentShareSheet(filePath);
        return YES;
    }

    NSLog(@"%@ Failed to save to %@", kCanardLogTag, filePath);
    return NO;
}

#pragma mark - DlyArchiveReader Hooks

%hook DlyArchiveReader

- (bool)setUpArchiveError:(id *)error {
    NSLog(@"%@ setUpArchiveError: %p", kCanardLogTag, error);
    return %orig;
}

- (NSString *)password {
    NSString *pwd = %orig;
    CanardArchivePassword = [pwd copy];
    NSLog(@"%@ password: %@", kCanardLogTag, pwd);
    return pwd;
}

- (int)getDocumentSize {
    int size = %orig;
    NSLog(@"%@ getDocumentSize: %d", kCanardLogTag, size);
    return size;
}

- (NSData *)readDataAt:(int)offset withSize:(int)size {
    NSLog(@"%@ readDataAt: offset=%d size=%d", kCanardLogTag, offset, size);
    NSLog(@"%@ %@", kCanardLogTag, [[NSThread callStackSymbols] componentsJoinedByString:@"\n"]);

    NSData *data = %orig;

    if (data.length > 0 && size != CanardLastSavedReadSize) {
        CanardLastSavedReadSize = size;
        CanardSaveData(data, CanardArchivePassword);
    }

    return data;
}

%end

#pragma mark - DlyCoreArchive Hooks

%hook DlyCoreArchive

- (instancetype)initWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"%@ initWithArchivePath: %@ error:%p", kCanardLogTag, path, error);
    return %orig;
}

+ (instancetype)newWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"%@ newWithArchivePath: %@ error:%p", kCanardLogTag, path, error);
    return %orig;
}

- (bool)openArchiveWithType:(NSUInteger)type error:(id *)error {
    NSLog(@"%@ openArchiveWithType: %lu error:%p", kCanardLogTag, (unsigned long)type, error);
    return %orig;
}

%end