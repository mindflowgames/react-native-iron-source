#import "RNIronSourceRewardedVideo.h"

#import "RCTUtils.h"

NSString *const kIronSourceRewardedVideoAvailable = @"ironSourceRewardedVideoAvailable";
NSString *const kIronSourceRewardedVideoUnavailable = @"ironSourceRewardedVideoUnavailable";
NSString *const kIronSourceRewardedVideoAdRewarded = @"ironSourceRewardedVideoAdRewarded";
NSString *const kIronSourceRewardedVideoClosedByError = @"ironSourceRewardedVideoClosedByError";
NSString *const kIronSourceRewardedVideoClosedByUser = @"ironSourceRewardedVideoClosedByUser";
NSString *const kIronSourceRewardedVideoDidStart = @"ironSourceRewardedVideoDidStart";
NSString *const kIronSourceRewardedVideoDidOpen = @"ironSourceRewardedVideoDidOpen";
NSString *const kIronSourceRewardedVideoAdStarted = @"ironSourceRewardedVideoAdStarted";
NSString *const kIronSourceRewardedVideoAdEnded = @"ironSourceRewardedVideoAdEnded";
NSString *const kIronSourceRewardedVideoClicked = @"ironSourceRewardedVideoClicked";

@implementation RNIronSourceRewardedVideo {
    RCTResponseSenderBlock _requestRewardedVideoCallback;
    bool initialized;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents {
    return @[kIronSourceRewardedVideoAvailable,
             kIronSourceRewardedVideoUnavailable,
             kIronSourceRewardedVideoAdRewarded,
             kIronSourceRewardedVideoClosedByError,
             kIronSourceRewardedVideoClosedByUser,
             kIronSourceRewardedVideoDidStart,
             kIronSourceRewardedVideoDidOpen,
             kIronSourceRewardedVideoAdStarted,
             kIronSourceRewardedVideoAdEnded,
             kIronSourceRewardedVideoClicked
             ];
}

// Initialize IronSource before showing the Rewarded Video
RCT_EXPORT_METHOD(initializeRewardedVideo)
{
    if (!initialized) {
        [IronSource setRewardedVideoDelegate:self];
        initialized = YES;
    }
}

//
// Show the Ad
//
RCT_EXPORT_METHOD(showRewardedVideo:(NSString*)placementName)
{
    if ([IronSource hasRewardedVideo]) {
        [self sendEventWithName:kIronSourceRewardedVideoAvailable body:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [IronSource showRewardedVideoWithViewController:RCTPresentedViewController() placement:placementName];
        });
    } else {
        [self sendEventWithName:kIronSourceRewardedVideoUnavailable body:nil];
    }
}

RCT_EXPORT_METHOD(isRewardedVideoAvailable:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    @try {
        resolve(@([IronSource hasRewardedVideo]));
    }
    @catch (NSException *exception) {
        reject(@"isRewardedVideoAvailable, Error, %@", exception.reason, nil);
    }
}

RCT_EXPORT_METHOD(setDynamicUserId:(NSString*)userId)
{
    [IronSource setDynamicUserId:userId];
}

#pragma mark delegate events

/**
 * Invoked when there is a change in the ad availability status.
 * @param - hasAvailableAds - value will change to YES when rewarded videos are available. * You can then show the video by calling showRV(). Value will change to NO when no videos are available.
 */
 - (void)rewardedVideoHasChangedAvailability:(BOOL)available {
     if(available == YES){
         [self sendEventWithName:kIronSourceRewardedVideoAvailable body:nil];
     } else {
         [self sendEventWithName:kIronSourceRewardedVideoUnavailable body:nil];
     }
 }

- (void)didReceiveRewardForPlacement:(ISPlacementInfo*)placementInfo {
    NSNumber * rewardAmount = [placementInfo rewardAmount];
    NSString * rewardName = [placementInfo rewardName];
    [self sendEventWithName:kIronSourceRewardedVideoAdRewarded body:@{
                                                                      @"rewardName": rewardName,
                                                                      @"rewardAmount": rewardAmount
                                                                      }];
}

/**
 * Invoked when an Ad failed to display.
 * @param - error - NSError which contains the reason for the
 * failure. The error contains error.code and error.message.
 */
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error {
    @try {
        NSString *errorMessage = [NSString stringWithFormat:@"code: %ld; message: %@; domain: %@", (long)error.code, error.localizedDescription, error.domain];
        [self sendEventWithName:kIronSourceRewardedVideoClosedByError body:@{@"message": errorMessage}];
    }
    @catch (NSException *e) {
        [self sendEventWithName:kIronSourceRewardedVideoClosedByError body:@{@"message": e.reason}];
    }
}

/**
 * Invoked when the RewardedVideo ad view has opened.
 */
- (void)rewardedVideoDidOpen{
    // @Deprecated kIronSourceRewardedVideoDidStart
    [self sendEventWithName:kIronSourceRewardedVideoDidStart body:nil];
    [self sendEventWithName:kIronSourceRewardedVideoDidOpen body:nil];
}

/**
 * Invoked when the user is about to return to the application after closing the
 * RewardedVideo ad.
 */
- (void)rewardedVideoDidClose {
    [self sendEventWithName:kIronSourceRewardedVideoClosedByUser body:nil];
}

/**
 * Note: the events below are not available
 * for all supported Rewarded Video Ad Networks.
 * Check which events are available per Ad Network
 * you choose to include in your build.
 * We recommend only using events which register to
 * ALL Ad Networks you include in your build.
 */
/**
 * Available for: AdColony, Vungle, AppLovin, UnityAds
 * Invoked when the video ad starts playing.
 */
- (void)rewardedVideoDidStart {
    [self sendEventWithName:kIronSourceRewardedVideoAdStarted body:nil];
}

/**
 * Available for: AdColony, Vungle, AppLovin, UnityAds
 * Invoked when the video ad finishes playing.
 */
- (void)rewardedVideoDidEnd {
    [self sendEventWithName:kIronSourceRewardedVideoAdEnded body:nil];
}

- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo {
    [self sendEventWithName:kIronSourceRewardedVideoClicked body:nil];
}

@end
