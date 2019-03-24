#import <Cordova/CDVPlugin.h>

@interface CordovaPluginACRCloud : CDVPlugin {
}

// The hooks for our plugin commands
- (void)init:(CDVInvokedUrlCommand *)command;
- (void)startRecognition:(CDVInvokedUrlCommand *)command;
- (void)stopRecognition:(CDVInvokedUrlCommand *)command;

@end
