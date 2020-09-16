/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI38_0_0RCTAppearance.h"

#import <ABI38_0_0FBReactNativeSpec/ABI38_0_0FBReactNativeSpec.h>
#import <ABI38_0_0React/ABI38_0_0RCTConstants.h>
#import <ABI38_0_0React/ABI38_0_0RCTEventEmitter.h>

#import "ABI38_0_0CoreModulesPlugins.h"

using namespace ABI38_0_0facebook::ABI38_0_0React;

NSString *const ABI38_0_0RCTAppearanceColorSchemeLight = @"light";
NSString *const ABI38_0_0RCTAppearanceColorSchemeDark = @"dark";

static BOOL sAppearancePreferenceEnabled = YES;
void ABI38_0_0RCTEnableAppearancePreference(BOOL enabled) {
  sAppearancePreferenceEnabled = enabled;
}

static NSString *ABI38_0_0RCTColorSchemePreference(UITraitCollection *traitCollection)
{
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
  if (@available(iOS 13.0, *)) {
    static NSDictionary *appearances;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      appearances = @{
                      @(UIUserInterfaceStyleLight): ABI38_0_0RCTAppearanceColorSchemeLight,
                      @(UIUserInterfaceStyleDark): ABI38_0_0RCTAppearanceColorSchemeDark
                      };
    });

    if (!sAppearancePreferenceEnabled) {
      // Return the default if the app doesn't allow different color schemes.
      return ABI38_0_0RCTAppearanceColorSchemeLight;
    }

    traitCollection = traitCollection ?: [UITraitCollection currentTraitCollection];
    return appearances[@(traitCollection.userInterfaceStyle)] ?: ABI38_0_0RCTAppearanceColorSchemeLight;
  }
#endif

  // Default to light on older OS version - same behavior as Android.
  return ABI38_0_0RCTAppearanceColorSchemeLight;
}

@interface ABI38_0_0RCTAppearance () <ABI38_0_0NativeAppearanceSpec>
@end

@implementation ABI38_0_0RCTAppearance
{
  NSString *_currentColorScheme;
}

ABI38_0_0RCT_EXPORT_MODULE(Appearance)

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (std::shared_ptr<TurboModule>)getTurboModuleWithJsInvoker:(std::shared_ptr<CallInvoker>)jsInvoker
{
  return std::make_shared<NativeAppearanceSpecJSI>(self, jsInvoker);
}

ABI38_0_0RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSString *, getColorScheme)
{
  _currentColorScheme =  ABI38_0_0RCTColorSchemePreference(nil);
  return _currentColorScheme;
}

- (void)appearanceChanged:(NSNotification *)notification
{
  NSDictionary *userInfo = [notification userInfo];
  UITraitCollection *traitCollection = nil;
  if (userInfo) {
    traitCollection = userInfo[ABI38_0_0RCTUserInterfaceStyleDidChangeNotificationTraitCollectionKey];
  }
  NSString *newColorScheme = ABI38_0_0RCTColorSchemePreference(traitCollection);
  if (![_currentColorScheme isEqualToString:newColorScheme]) {
    _currentColorScheme = newColorScheme;
    [self sendEventWithName:@"appearanceChanged" body:@{@"colorScheme": newColorScheme}];
  }
}

#pragma mark - ABI38_0_0RCTEventEmitter

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"appearanceChanged"];
}

- (void)startObserving
{
  if (@available(iOS 13.0, *)) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appearanceChanged:)
                                                 name:ABI38_0_0RCTUserInterfaceStyleDidChangeNotification
                                               object:nil];
  }
}

- (void)stopObserving
{
  if (@available(iOS 13.0, *)) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

@end

Class ABI38_0_0RCTAppearanceCls(void) {
  return ABI38_0_0RCTAppearance.class;
}
