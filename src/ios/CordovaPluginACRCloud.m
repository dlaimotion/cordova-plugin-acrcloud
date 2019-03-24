#import "CordovaPluginACRCloud.h"
#import <Cordova/CDVAvailability.h>
#import "ACRCloudRecognition.h"
#import "ACRCloudConfig.h"

@implementation CordovaPluginACRCloud {
    ACRCloudRecognition     *_client;
    ACRCloudConfig          *_config;
    UITextView              *_resultTextView;
    NSTimeInterval          startTime;
    NSString                *_result;
    NSString                *_volume;
    NSString                *_state;
    NSString                *_callbackIdForRecognition;
    NSString                *_callbackIdForVolume;
    __block BOOL    _start;
}

- (void)pluginInitialize {
    
}

// init function
- (void)init:(CDVInvokedUrlCommand *)command {
    
    NSString* accessKey = [command.arguments objectAtIndex:0];
    NSString* accessSecret = [command.arguments objectAtIndex:1];
    NSString* host = [command.arguments objectAtIndex:2];
    
    _start = NO;
    
    _config = [[ACRCloudConfig alloc] init];
    
    _config.accessKey = accessKey;
    _config.accessSecret = accessSecret;
    _config.host = host;
    _config.protocol = @"https";
    
    //if you want to identify your offline db, set the recMode to "rec_mode_local"
    _config.recMode = rec_mode_remote;
    _config.requestTimeout = 10;
    
    /* used for local model */
    if (_config.recMode == rec_mode_local || _config.recMode == rec_mode_both)
        _config.homedir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"acrcloud_local_db"];
    
    __weak __typeof(self) weakSelf = self;

    _config.stateBlock = ^(NSString *state) {
        [weakSelf handleState:state];
    };

    _config.volumeBlock = ^(float volume) {
        //do some animations with volume
        [weakSelf handleVolume:volume];
    };

    _config.resultBlock = ^(NSString *result, ACRCloudResultType resType) {
        [weakSelf handleResult:result resultType:resType];
    };
    
    /*if you want to get the result and fingerprint, uncoment this code, comment the code "resultBlock".*/
    //_config.resultFpBlock = ^(NSString *result, NSData* fingerprint) {
    //    [weakSelf handleResultFp:result fingerprint:fingerprint];
    //};
    
    /*if you want to get the result and pcm data, uncoment this code, comment the code "resultBlock".*/
    //    _config.resultDataBlock = ^(NSString *result, NSData* pcm_data) {
    //        [weakSelf handleResultData:result data:pcm_data];
    //    };
    
    _client = [[ACRCloudRecognition alloc] initWithConfig:_config];
    
    //start pre-record
    [_client startPreRecord:3000];
    
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
    
}

// start recognition function
- (void)startRecognition:(CDVInvokedUrlCommand *)command {
    if (_start) {
        return;
    }
    
    _result = @"";
    
    [_client startRecordRec];
    _start = YES;
    
    startTime = [[NSDate date] timeIntervalSince1970];
    
    _callbackIdForRecognition = command.callbackId;
}

// stop recognition function
- (void)stopRecognition:(CDVInvokedUrlCommand *)command {
    if(_client) {
        [_client stopRecordRec];
    }
    _start = NO;
}

// watch volume function
- (void)watchForVolumeChange:(CDVInvokedUrlCommand *)command {
    _callbackIdForVolume = command.callbackId;
}




//////
-(void)handleResult:(NSString *)result
         resultType:(ACRCloudResultType)resType
{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        
        NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        
        NSString *r = nil;

        if ([[jsonObject valueForKeyPath: @"status.code"] integerValue] == 0) {
            if ([jsonObject valueForKeyPath: @"metadata.music"]) {
                NSDictionary *meta = [jsonObject valueForKeyPath: @"metadata.music"][0];
                NSString *title = [meta objectForKey:@"title"];
                NSString *artist = [meta objectForKey:@"artists"][0][@"name"];
                NSString *album = [meta objectForKey:@"album"][@"name"];
                NSString *play_offset_ms = [meta objectForKey:@"play_offset_ms"];
                NSString *duration = [meta objectForKey:@"duration_ms"];
                
                NSArray *ra = @[[NSString stringWithFormat:@"title:%@", title],
                                [NSString stringWithFormat:@"artist:%@", artist],
                                [NSString stringWithFormat:@"album:%@", album],
                                [NSString stringWithFormat:@"play_offset_ms:%@", play_offset_ms],
                                [NSString stringWithFormat:@"duration_ms:%@", duration]];
                r = [ra componentsJoinedByString:@"\n"];
            }
            if ([jsonObject valueForKeyPath: @"metadata.custom_files"]) {
                NSDictionary *meta = [jsonObject valueForKeyPath: @"metadata.custom_files"][0];
                NSString *title = [meta objectForKey:@"title"];
                NSString *audio_id = [meta objectForKey:@"audio_id"];
                
                r = [NSString stringWithFormat:@"title : %@\naudio_id : %@", title, audio_id];
            }
            if ([jsonObject valueForKeyPath: @"metadata.streams"]) {
                NSDictionary *meta = [jsonObject valueForKeyPath: @"metadata.streams"][0];
                NSString *title = [meta objectForKey:@"title"];
                NSString *title_en = [meta objectForKey:@"title_en"];
                
                r = [NSString stringWithFormat:@"title : %@\ntitle_en : %@", title,title_en];
            }
            if ([jsonObject valueForKeyPath: @"metadata.custom_streams"]) {
                NSDictionary *meta = [jsonObject valueForKeyPath: @"metadata.custom_streams"][0];
                NSString *title = [meta objectForKey:@"title"];
                
                r = [NSString stringWithFormat:@"title : %@", title];
            }
            if ([jsonObject valueForKeyPath: @"metadata.humming"]) {
                NSArray *metas = [jsonObject valueForKeyPath: @"metadata.humming"];
                NSMutableArray *ra = [NSMutableArray arrayWithCapacity:6];
                for (id d in metas) {
                    NSString *title = [d objectForKey:@"title"];
                    NSString *score = [d objectForKey:@"score"];
                    NSString *sh = [NSString stringWithFormat:@"title : %@  score : %@", title, score];
                    
                    [ra addObject:sh];
                }
                r = [ra componentsJoinedByString:@"\n"];
            }
            
            _result = result;
            [self sendPluginResult: @"recognition_response"];
        } else {
            _result = result;
            [self sendPluginResult: @"recognition_response"];
        }
        
        [_client stopRecordRec];
        _start = NO;
        
        //        NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
        //        int cost = nowTime - startTime;
        //        self.costLabel.text = [NSString stringWithFormat:@"cost : %ds", cost];
        
    });
}

-(void)handleVolume:(float)volume
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _volume = [NSString stringWithFormat:@"%f",volume];
        [self sendPluginResult: @"volume"];
    });
}

-(void)handleState:(NSString *)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _state = [NSString stringWithFormat:@"State : %@",state];
    });
}

- (void)sendPluginResult:(NSString *)resultType
{
    int status = CDVCommandStatus_OK;
    
    CDVPluginResult* result;
    NSString* callbackId;
    
    if ([resultType isEqual: @"recognition_response"]) {
        result = [CDVPluginResult resultWithStatus:status messageAsString:_result];
        callbackId = _callbackIdForRecognition;
    } else if ([resultType isEqual: @"volume"]) {
        result = [CDVPluginResult resultWithStatus:status messageAsString:_volume];
        callbackId = _callbackIdForVolume;
    }
    
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

@end
