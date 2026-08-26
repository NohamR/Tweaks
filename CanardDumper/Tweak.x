// log stream --predicate 'process == "LeCanardEnchaine" AND eventMessage contains "CanardDumper" ' --level default --style compact

#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - Constants

static NSString *const kCanardLogTag = @"[CanardDumper]";
static NSString *const kCanardDumpDirectoryName = @"CanardDumps";
static NSString *const kCanardReaderFirstOpenKey = @"READER_FIRST_OPEN";
static NSString *const kCanardFirebaseSessionsSettingsKey = @"firebase-sessions-settings";
static NSString *const kCanardCatalogManagerDefaultsDomain = @"com.immanens.datamanager.CatalogManager.default";

static NSString *const kCanardFirebaseCollectAnrsKey = @"collect_anrs";
static NSString *const kCanardFirebaseCollectBuildIdsKey = @"collect_build_ids";
static NSString *const kCanardFirebaseCollectLoggedExceptionsKey = @"collect_logged_exceptions";
static NSString *const kCanardFirebaseCollectReportsKey = @"collect_reports";
static NSString *const kCanardFirebaseSessionsEnabledKey = @"sessions_enabled";
static NSString *const kCanardCatalogLocalKey = @"local";

#pragma mark - State

static NSString *CanardArchivePassword;
static NSString *CanardCurrentArchivePath;
static NSString *CanardCurrentArchiveFileName;
static NSDictionary *CanardCurrentArchiveEntry;
static NSString *CanardLastSavedToken;

static NSDictionary *CanardForcedFirebaseSessionsSettings(NSDictionary *currentSettings) {
    NSMutableDictionary *settings = currentSettings ? [currentSettings mutableCopy] : [NSMutableDictionary dictionary];

    settings[kCanardFirebaseCollectAnrsKey] = @NO;
    settings[kCanardFirebaseCollectBuildIdsKey] = @NO;
    settings[kCanardFirebaseCollectLoggedExceptionsKey] = @NO;
    settings[kCanardFirebaseCollectReportsKey] = @NO;
    settings[kCanardFirebaseSessionsEnabledKey] = @NO;

    return settings;
}

static void CanardApplyForcedDefaults(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kCanardReaderFirstOpenKey];

    NSDictionary *existing = [defaults dictionaryForKey:kCanardFirebaseSessionsSettingsKey];
    NSDictionary *forced = CanardForcedFirebaseSessionsSettings(existing);
    [defaults setObject:forced forKey:kCanardFirebaseSessionsSettingsKey];
    [defaults synchronize];

    NSLog(@"%@ Forced defaults applied for %@ and %@", kCanardLogTag, kCanardReaderFirstOpenKey, kCanardFirebaseSessionsSettingsKey);
}

static NSArray *CanardCatalogLocalEntries(void) {
    NSDictionary *domainValues = [[NSUserDefaults standardUserDefaults]
        persistentDomainForName:kCanardCatalogManagerDefaultsDomain];
    id local = domainValues[kCanardCatalogLocalKey];
    if ([local isKindOfClass:[NSArray class]]) {
        return (NSArray *)local;
    }
    return @[];
}

static NSDictionary *CanardCatalogEntryForFileName(NSString *fileName) {
    if (fileName.length == 0) return nil;

    for (id item in CanardCatalogLocalEntries()) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        NSDictionary *entry = (NSDictionary *)item;
        NSString *entryFileName = entry[@"fileName"];
        if ([entryFileName isKindOfClass:[NSString class]] && [entryFileName isEqualToString:fileName]) {
            return entry;
        }
    }

    return nil;
}

static void CanardUpdateCurrentArchiveContext(NSString *archivePath) {
    CanardCurrentArchivePath = [archivePath copy];
    CanardCurrentArchiveFileName = [[archivePath lastPathComponent] copy];
    CanardCurrentArchiveEntry = CanardCatalogEntryForFileName(CanardCurrentArchiveFileName);
    CanardLastSavedToken = nil;

    NSLog(@"%@ Archive context file=%@ entryFound=%@", kCanardLogTag, CanardCurrentArchiveFileName, CanardCurrentArchiveEntry ? @"YES" : @"NO");
}

// #pragma mark - UI Helpers

// static UIViewController *CanardTopViewController(UIViewController *viewController) {
//     if (!viewController) return nil;
    
//     if (viewController.presentedViewController) {
//         return CanardTopViewController(viewController.presentedViewController);
//     }
//     if ([viewController isKindOfClass:[UINavigationController class]]) {
//         return CanardTopViewController([(UINavigationController *)viewController visibleViewController]);
//     }
//     if ([viewController isKindOfClass:[UITabBarController class]]) {
//         return CanardTopViewController([(UITabBarController *)viewController selectedViewController]);
//     }
//     return viewController;
// }

// static void CanardPresentShareSheet(NSString *filePath) {
//     dispatch_async(dispatch_get_main_queue(), ^{
//         UIWindow *keyWindow = nil;
//         for (UIWindow *window in [UIApplication sharedApplication].windows) {
//             if (window.isKeyWindow) {
//                 keyWindow = window;
//                 break;
//             }
//         }

//         UIViewController *topVC = CanardTopViewController(keyWindow.rootViewController);
//         if (!topVC) {
//             NSLog(@"%@ Unable to present share sheet", kCanardLogTag);
//             return;
//         }

//         NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//         UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
//         shareController.popoverPresentationController.sourceView = topVC.view;
//         shareController.popoverPresentationController.sourceRect = CGRectMake(
//             CGRectGetMidX(topVC.view.bounds),
//             CGRectGetMidY(topVC.view.bounds),
//             0, 0
//         );
//         [topVC presentViewController:shareController animated:YES completion:nil];
//     });
// }

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

    NSString *docStem = [[CanardCurrentArchiveFileName stringByDeletingPathExtension] copy];
    if (docStem.length == 0) {
        docStem = @"unknown_doc";
    }

    NSString *safeDocStem = CanardSanitizedFilename(docStem);
    NSString *safePassword = CanardSanitizedFilename(password);
    NSString *baseName = [NSString stringWithFormat:@"%@_%@", safeDocStem, safePassword];

    NSString *pdfPath = [dumpDir stringByAppendingPathComponent:[baseName stringByAppendingString:@".pdf"]];
    NSString *jsonPath = [dumpDir stringByAppendingPathComponent:[baseName stringByAppendingString:@".json"]];

    if (![data writeToFile:pdfPath atomically:YES]) {
        NSLog(@"%@ Failed to save to %@", kCanardLogTag, pdfPath);
        return NO;
    }

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"archive_path"] = CanardCurrentArchivePath ?: @"";
    payload[@"file_name"] = CanardCurrentArchiveFileName ?: @"";
    payload[@"password"] = password ?: @"";
    payload[@"saved_at"] = [[NSDate date] description];
    payload[@"domain"] = kCanardCatalogManagerDefaultsDomain;

    if ([CanardCurrentArchiveEntry isKindOfClass:[NSDictionary class]]) {
        payload[@"catalog_entry"] = CanardCurrentArchiveEntry;
    }

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    if (jsonData) {
        [jsonData writeToFile:jsonPath atomically:YES];
    } else {
        NSLog(@"%@ Failed to build metadata JSON: %@", kCanardLogTag, jsonError);
    }

    NSLog(@"%@ Saved PDF %@ (%lu bytes)", kCanardLogTag, pdfPath, (unsigned long)data.length);
    NSLog(@"%@ Saved metadata %@", kCanardLogTag, jsonPath);
    
    // Present share sheet for the saved PDF
    // CanardPresentShareSheet(pdfPath);
    return YES;
}

#pragma mark - DlyArchiveReader Hooks

%hook DlyArchiveReader

// - (bool)setUpArchiveError:(id *)error {
//     NSLog(@"%@ setUpArchiveError: %p", kCanardLogTag, error);
//     return %orig;
// }

- (NSString *)password {
    NSString *pwd = %orig;
    CanardArchivePassword = [pwd copy];
    NSLog(@"%@ password: %@", kCanardLogTag, pwd);
    return pwd;
}

// - (int)getDocumentSize {
//     int size = %orig;
//     NSLog(@"%@ getDocumentSize: %d", kCanardLogTag, size);
//     return size;
// }

- (NSData *)readDataAt:(int)offset withSize:(int)size {
    NSData *data = %orig;
    NSString *token = [NSString stringWithFormat:@"%@:%d", CanardCurrentArchiveFileName ?: @"unknown", size];
    if (data.length > 0 && ![CanardLastSavedToken isEqualToString:token]) {
        NSLog(@"%@ readDataAt: offset=%d size=%d", kCanardLogTag, offset, size);
        // NSLog(@"%@ %@", kCanardLogTag, [[NSThread callStackSymbols] componentsJoinedByString:@"\n"]);
        CanardLastSavedToken = token;
        CanardSaveData(data, CanardArchivePassword);
    }

    return data;
}

%end

#pragma mark - DlyCoreArchive Hooks

%hook DlyCoreArchive

- (instancetype)initWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"%@ initWithArchivePath: %@ error:%p", kCanardLogTag, path, error);
    CanardUpdateCurrentArchiveContext(path);
    return %orig;
}

+ (instancetype)newWithArchivePath:(NSString *)path error:(NSError **)error {
    NSLog(@"%@ newWithArchivePath: %@ error:%p", kCanardLogTag, path, error);
    CanardUpdateCurrentArchiveContext(path);
    return %orig;
}

// - (bool)openArchiveWithType:(NSUInteger)type error:(id *)error {
//     NSLog(@"%@ openArchiveWithType: %lu error:%p", kCanardLogTag, (unsigned long)type, error);
//     return %orig;
// }

%end


# pragma mark - NSURLSessionConfiguration Hooks to prevent background sessions (not available in simulator)
%hook NSURLSessionConfiguration

+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithIdentifier:(NSString *)identifier {
    NSLog(@"%@ backgroundSessionConfigurationWithIdentifier:'%@' -> forcing default config", kCanardLogTag, identifier);
    return [NSURLSessionConfiguration defaultSessionConfiguration];
}

%end


# pragma mark - Apply privacy defaults on tweak load

%ctor {
    CanardApplyForcedDefaults();
}