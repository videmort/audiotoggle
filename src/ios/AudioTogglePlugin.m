#import "AudioTogglePlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation AudioTogglePlugin
{
    NSString *mode;
}
- (void)setAudioMode:(CDVInvokedUrlCommand *)command
{
    mode = [NSString stringWithFormat:@"%@", [command.arguments objectAtIndex:0]];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [self configureAVAudioSession:session];
}

- (BOOL)configureAVAudioSession:(AVAudioSession *)session {
    BOOL success;
    NSError* error;
    
    success = [session setCategory:[mode isEqualToString:@"speaker"]? AVAudioSessionCategoryPlayAndRecord: AVAudioSessionCategoryRecord
                             error:&error];
    if (!success) {
        NSLog(@"AVAudioSession error setting category:%@",error);
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    
    return success;
}

- (void)didSessionRouteChange:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    NSError* error;
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonCategoryChange: {
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:([self isHeadsetPluggedIn])? AVAudioSessionPortOverrideNone :AVAudioSessionPortOverrideSpeaker error:&error];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            [[AVAudioSession sharedInstance] overrideOutputAudioPort: AVAudioSessionPortOverrideSpeaker error:&error];
        }
            break;
            
        default:
            break;
    }
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

@end