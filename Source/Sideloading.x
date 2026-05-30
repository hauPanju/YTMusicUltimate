#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <rootless.h>
#import "Source/Headers/YTAlertView.h"
#import "Source/Headers/Localization.h"

#define YT_BUNDLE_ID @"com.google.ios.youtubemusic"
#define YT_BUNDLE_NAME @"YouTubeMusic"
#define YT_NAME @"YouTube Music"

@interface SSOConfiguration : NSObject
@end

static NSString *accessGroupID() {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
        if (status != errSecSuccess) {
            return nil;
        }
    }
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    return accessGroup;
}

// Force enable safari sign-in
%hook SSOConfiguration
- (BOOL)shouldEnableSafariSignIn { return YES; }
- (BOOL)temporarilyDisableSafariSignIn { return NO; }
- (void)setTemporarilyDisableSafariSignIn:(BOOL)arg1 { return %orig(NO); }
%end

%hook SSOKeychainHelper
+ (id)accessGroup { return accessGroupID(); }
+ (id)sharedAccessGroup { return accessGroupID(); }
%end

%hook SSOFolsomKeychainUtils
- (id)sharedAccessGroup { return accessGroupID(); }
%end

%hook GULKeychainStorage
- (void)getObjectForKey:(id)key objectClass:(Class)objectClass accessGroup:(id)accessGroup completionHandler:(id)handler {
    accessGroup = accessGroupID();
    %orig;
}
- (void)setObject:(id)object forKey:(id)key accessGroup:(id)accessGroup completionHandler:(id)handler {
    accessGroup = accessGroupID();
    %orig;
}
- (void)removeObjectForKey:(id)key accessGroup:(id)accessGroup completionHandler:(id)handler {
    accessGroup = accessGroupID();
    %orig;
}
- (void)getObjectFromKeychainForKey:(id)key objectClass:(Class)objectClass accessGroup:(id)accessGroup completionHandler:(id)handler {
    accessGroup = accessGroupID();
    %orig;
}
- (id)keychainQueryWithKey:(id)key accessGroup:(id)accessGroup {
    accessGroup = accessGroupID();
    return %orig(key, accessGroup);
}
%end

%hook SSOKeychainCore
+ (id)accessGroup { return accessGroupID(); }
+ (id)sharedAccessGroup { return accessGroupID(); }
%end

%hook SSOBundleIdServiceImpl
- (id)bundleId { return YT_BUNDLE_ID; }
%end

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    if (groupIdentifier != nil) {
        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        return [documentsURL URLByAppendingPathComponent:@"AppGroup"];
    }
    return %orig(groupIdentifier);
}
%end

#pragma mark - Thanks PoomSmart for the following hooks
/* IAmYouTube + Extra hooks for ytmusic */
%hook YTVersionUtils
- (id)appName { return YT_NAME; }
- (id)appID { return YT_BUNDLE_ID; }
%end

%hook CHRAppState
- (id)appName { return YT_NAME; }
%end

%hook GCKBUtils
- (id)appIdentifier { return YT_BUNDLE_ID; }
%end

%hook FIRInstallationsIIDTokenStore
- (id)IIDAppIdentifier { return YT_BUNDLE_ID; }
%end

%hook GPCDeviceInfo
- (id)bundleId { return YT_BUNDLE_ID; }
%end

%hook OGLBundle
- (id)shortAppName { return YT_NAME; }
%end

%hook GVROverlayView
- (id)appName { return YT_NAME; }
%end

%hook OGLGM2AccountSelectorViewController
- (id)shortAppName { return YT_NAME; }
%end

%hook OGLPhenotypeFlagServiceImpl
- (NSString *)bundleId { return YT_BUNDLE_ID; }
%end

%hook APMAEU
- (BOOL)isFAS { return YES; }
%end

%hook ASWApp
- (id)bundleIdentifier { return YT_BUNDLE_ID; }
- (id)exp_productionBundleIdentifier { return YT_BUNDLE_ID; }
%end

%hook GULAppEnvironmentUtil
- (BOOL)isFromAppStore { return YES; }
%end

%hook APMIdentity
- (BOOL)isFromAppStore { return YES; }
%end

%hook SSOConfiguration
- (id)initWithClientID:(id)clientID supportedAccountServices:(id)supportedAccountServices {
    self = %orig;
    [self setValue:YT_NAME forKey:@"_shortAppName"];
    [self setValue:YT_BUNDLE_ID forKey:@"_applicationIdentifier"];
    return self;
}
- (void)setShortAppName:(id)appName { %orig(YT_NAME); }
%end

%hook NSBundle
- (NSString *)bundleIdentifier {
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    if (dladdr((void *)[address[2] longLongValue], &info) == 0)
        return %orig;
    NSString *path = [NSString stringWithUTF8String:info.dli_fname];
    if ([path hasPrefix:NSBundle.mainBundle.bundlePath])
        return YT_BUNDLE_ID;
    return %orig;
}
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key isEqualToString:@"CFBundleIdentifier"])
        return YT_BUNDLE_ID;
    if ([key isEqualToString:@"CFBundleDisplayName"])
        return YT_NAME;
    if ([key isEqualToString:@"CFBundleName"])
        return YT_BUNDLE_NAME;
    return %orig;
}
%end
/* IAmYouTube end */

%hook ASWUtilities
- (id)productionBundleIdentifier { return YT_BUNDLE_ID; }
- (id)lowercaseProductionBundleIdentifier { return YT_BUNDLE_ID; }
%end

%hook EXPApp
- (id)bundleIdentifier { return YT_BUNDLE_ID; }
%end

%hook CHRInfoPlistUtil
- (id)mainAppBundleID { return YT_BUNDLE_ID; }
%end

%hook FIROptions
- (id)bundleID { return YT_BUNDLE_ID; }
%end

%hook FIRApp
- (id)actualBundleID { return YT_BUNDLE_ID; }
%end

%hook GAZAppInfo
- (id)currentBundleIdentifier { return YT_BUNDLE_ID; }
%end

// --- infoDictionary patch ---
static BOOL patchApplied = NO;

NSDictionary *(*orig_infoDictionary)(id self, SEL _cmd);
NSDictionary *replaceInfoDict(id self, SEL _cmd) {
    NSDictionary *originalInfoDictionary = orig_infoDictionary(self, _cmd);
    NSString *bundleIdentifier = originalInfoDictionary[@"CFBundleIdentifier"];
    if (![bundleIdentifier isEqualToString:YT_BUNDLE_ID]) {
        NSMutableDictionary *newInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:originalInfoDictionary];
        [newInfoDictionary setValue:YT_BUNDLE_ID forKey:@"CFBundleIdentifier"];
        return newInfoDictionary;
    }
    return originalInfoDictionary;
}

static void applyInfoDictPatch() {
    if (!patchApplied) {
        MSHookMessageEx(objc_getClass("NSBundle"), @selector(infoDictionary), (IMP)replaceInfoDict, (IMP *)&orig_infoDictionary);
        patchApplied = YES;
    }
}

// --- Sign-in screen: inject Fix Sign In button ---
%hook YTMFirstTimeSignInViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Apply the infoDictionary patch immediately on screen appear
    applyInfoDictPatch();

    // Don't add the button twice if view reappears
    if ([self.view viewWithTag:0xBEEF]) return;

    UIButton *fixButton = [UIButton buttonWithType:UIButtonTypeSystem];
    fixButton.tag = 0xBEEF;
    fixButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.85];
    [fixButton setTitle:@"Fix Sign In" forState:UIControlStateNormal];
    [fixButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    fixButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    fixButton.layer.cornerRadius = 8;
    fixButton.clipsToBounds = YES;
    fixButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:fixButton];

    [NSLayoutConstraint activateConstraints:@[
        [fixButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [fixButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24],
        [fixButton.widthAnchor constraintEqualToConstant:200],
        [fixButton.heightAnchor constraintEqualToConstant:44]
    ]];

    [fixButton addTarget:self action:@selector(ytmu_fixSignInTapped) forControlEvents:UIControlEventTouchUpInside];
}

%new
- (void)ytmu_fixSignInTapped {
    applyInfoDictPatch();

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Sign In Fix Applied"
        message:@"Patch applied. Please try signing in now. If it still fails, tap the button again and retry."
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidDisappear:(BOOL)arg1 {
    %orig;
    YTAlertView *alertView = [%c(YTAlertView) infoDialog];
    alertView.title = LOC(@"WARNING");
    alertView.subtitle = LOC(@"LOGIN_INFO");
    [alertView show];
}

%end
