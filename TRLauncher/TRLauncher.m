//
//  TRAppLauncher.m
//
//  Copyright (c) 2014 Trafi. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "TRLauncher.h"

#define TR_LAUNCHER_VERSION @"0.5"

static NSString * const kTRCharsToLeaveEscaped = @"!*'();:@&=+$,/?%#[]";

static NSString * const kTRAppLinkDataParameterName = @"al_applink_data";
static NSString * const kTRAppLinkTargetKeyName = @"target_url";
static NSString * const kTRAppLinkUserAgentKeyName = @"user_agent";
static NSString * const kTRAppLinkExtrasKeyName = @"extras";
static NSString * const kTRAppLinkVersionKeyName = @"version";
static NSString * const kTRAppLinkVersion = @"1.0";

static NSString * const kTRAppLinksAppStoreUrlFormat = @"https://itunes.apple.com/app/id%@";
static NSString * const kTRAppLinksFromCoordinateFormat = @"fromCoord=%f,%f";
static NSString * const kTRAppLinksToCoordinateFormat = @"toCoord=%f,%f";
static NSString * const kTRAppLinksFromNameFormat = @"fromName=%@";
static NSString * const kTRAppLinksToNameFormat = @"toName=%@";

static NSString * const kTRAppLinksPropertyUrl = @"al:ios:url";
static NSString * const kTRAppLinksPropertyAppStoreId = @"al:ios:app_store_id";
static NSString * const kTRAppLinksPropertyAppName = @"al:ios:app_name";
static NSString * const kTRAppLinksResolverTagExtractionJavaScript = @""
"(function() {"
"  var metaTags = document.getElementsByTagName('meta');"
"  var results = [];"
"  for (var i = 0; i < metaTags.length; i++) {"
"    var property = metaTags[i].getAttribute('property');"
"    if (property && property.substring(0, 'al:'.length) === 'al:') {"
"      var tag = { \"property\": metaTags[i].getAttribute('property') };"
"      if (metaTags[i].hasAttribute('content')) {"
"        tag['content'] = metaTags[i].getAttribute('content');"
"      }"
"      results.push(tag);"
"    }"
"  }"
"  return JSON.stringify(results);"
"})()";

#pragma mark - Helpers

NSString* encodeUrlString(NSString *stringToEncode) {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)stringToEncode,
                                                                                 NULL,
                                                                                 (CFStringRef)kTRCharsToLeaveEscaped,
                                                                                 kCFStringEncodingUTF8));
}

#pragma mark - TRAppLinkTarget

@interface TRAppLinkTarget : NSObject
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *appStoreId;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, readonly) NSURL *URL;
@end

@implementation TRAppLinkTarget
-(NSURL *)URL {
    return [NSURL URLWithString:self.urlString];
}
@end

#pragma mark - TRAppLinksResolver

typedef void (^TRAppLinksResolverSuccessCallback)(TRAppLinkTarget *appLinkTarget);
typedef void (^TRAppLinksResolverFailureCallback)(NSError *error);

@interface TRAppLinksResolver : NSObject <UIWebViewDelegate>

@property (nonatomic, copy) TRAppLinksResolverSuccessCallback successCallback;
@property (nonatomic, copy) TRAppLinksResolverFailureCallback failureCallback;

- (void)loadAppLinksDataWithUrl:(NSURL*)url
                      onSuccess:(TRAppLinksResolverSuccessCallback)successCallback
                        failure:(TRAppLinksResolverFailureCallback)failureCallback;
@end

@implementation TRAppLinksResolver

- (void)loadAppLinksDataWithUrl:(NSURL*)url
                      onSuccess:(TRAppLinksResolverSuccessCallback)successCallback
                        failure:(TRAppLinksResolverFailureCallback)failureCallback {
    
    _successCallback = successCallback;
    _failureCallback = failureCallback;

    __weak __typeof(self)weakSelf = self;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"al" forHTTPHeaderField:@"Prefer-Html-Meta-Tags"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               if (connectionError) {
                                   if (weakSelf.failureCallback) {
                                       weakSelf.failureCallback(connectionError);
                                   }
                                   return;
                               }
                               
                               if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                   UIWebView *webView = [UIWebView new];
                                   webView.delegate = weakSelf;
                                   webView.hidden = YES;
                                   
                                   UIWindow *window = [UIApplication sharedApplication].delegate.window;
                                   [window addSubview:webView];
                                   
                                   [webView loadData:data
                                            MIMEType:response.MIMEType
                                    textEncodingName:response.textEncodingName
                                             baseURL:response.URL];
                               }
                           }];
}

#pragma mark webView

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *json = [webView stringByEvaluatingJavaScriptFromString:kTRAppLinksResolverTagExtractionJavaScript];
    NSError *error = nil;
    NSArray *propertiesArray = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:0
                                                                 error:&error];
    [webView removeFromSuperview];
    
    if (!error) {
        TRAppLinkTarget *target = [TRAppLinkTarget new];
        
        for (NSDictionary *dictionary in propertiesArray) {
            NSString *key = dictionary[@"property"];
            NSString *value = dictionary[@"content"];
            
            if ([key isEqualToString:kTRAppLinksPropertyAppName]) {
                target.appName = value;
            }
            else if ([key isEqualToString:kTRAppLinksPropertyAppStoreId]) {
                target.appStoreId = value;
            }
            else if ([key isEqualToString:kTRAppLinksPropertyUrl]) {
                target.urlString = value;
            }
        }
        
        if (self.successCallback) {
            self.successCallback(target);
        }
    }
    else if (self.failureCallback) {
        self.failureCallback(error);
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.failureCallback) {
        self.failureCallback(error);
    }
}

@end

#pragma mark - TRLauncher

@interface TRLauncher ()

@property (nonatomic, copy) TRLauncherCallback callback;

+ (NSURL*)urlForApp:(TRAppTrafi)inApp
       fromLocation:(TRLocation*)fromLocation
         toLocation:(TRLocation*)toLocation;

- (void)openAppWithTarget:(TRAppLinkTarget*)target
                      url:(NSURL*)url;
@end

@implementation TRLauncher

- (NSURL *)appLinkURLWithTargetURL:(NSURL *)targetURL
                         sourceURL:(NSURL*)sourceURL
                             error:(NSError **)error {
    
    NSMutableDictionary *appLinkData = [NSMutableDictionary dictionary];
    
    appLinkData[kTRAppLinkUserAgentKeyName] = [NSString stringWithFormat:@"TRLauncher iOS %@", TR_LAUNCHER_VERSION];
    appLinkData[kTRAppLinkVersionKeyName] = kTRAppLinkVersion;
    appLinkData[kTRAppLinkExtrasKeyName] = @{};
    appLinkData[kTRAppLinkTargetKeyName] = [sourceURL absoluteString];
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:appLinkData
                                                       options:0
                                                         error:&jsonError];
    if (!jsonError) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        
        NSString *endUrlString = [NSString stringWithFormat:@"%@%@%@=%@",
                                  [targetURL absoluteString],
                                  targetURL.query ? @"&" : @"?",
                                  kTRAppLinkDataParameterName,
                                  encodeUrlString(jsonString)];
        
        return [NSURL URLWithString:endUrlString];
    }
    else if (error) {
        *error = jsonError;
    }
    
    return nil;
}

- (void)openAppWithTarget:(TRAppLinkTarget*)target url:(NSURL*)url {
    
    if ([[UIApplication sharedApplication] canOpenURL:target.URL]) {
        NSError *error = nil;
        NSURL *appLinkURL = [self appLinkURLWithTargetURL:target.URL
                                                sourceURL:url
                                                    error:&error];
        
        if (!error && appLinkURL && [[UIApplication sharedApplication] openURL:appLinkURL]) {
            if (self.callback) {
                self.callback(nil);
            }
        }
        else if (error && self.callback) {
            self.callback(error);
        }
    }
    else if ([target.appStoreId length]) {
        NSString *appStoreUrlString = [NSString stringWithFormat:kTRAppLinksAppStoreUrlFormat,
                                       target.appStoreId];
        NSURL *appStoreUrl = [NSURL URLWithString:appStoreUrlString];
        if ([[UIApplication sharedApplication] openURL:appStoreUrl]) {
            if (self.callback) {
                self.callback(nil);
            }
        }
    }
    else if (url) {
        NSError *error = nil;
        NSURL *appLinkURL = [self appLinkURLWithTargetURL:url
                                                sourceURL:url
                                                    error:&error];
        
        if (!error && appLinkURL && [[UIApplication sharedApplication] openURL:appLinkURL]) {
            if (self.callback) {
                self.callback(nil);
            }
        }
        else if (error && self.callback) {
            self.callback(error);
        }
    }
}

+ (void)routeInApp:(TRAppTrafi)appToLaunch
        toLocation:(TRLocation*)toLocation
completionCallback:(TRLauncherCallback)callback {
    [TRLauncher routeInApp:appToLaunch
              fromLocation:nil
                toLocation:toLocation
        completionCallback:callback];
}

+ (void)routeInApp:(TRAppTrafi)appToLaunch
      fromLocation:(TRLocation*)fromLocation
        toLocation:(TRLocation*)toLocation
completionCallback:(TRLauncherCallback)callback {
    
    __block NSURL *url = [TRLauncher urlForApp:appToLaunch
                                  fromLocation:fromLocation
                                    toLocation:toLocation];
    __block TRLauncherCallback callbackCopy = [callback copy];
    __block TRAppLinksResolver *appLinksDataResolver = [TRAppLinksResolver new];
    [appLinksDataResolver loadAppLinksDataWithUrl:url
                                        onSuccess:^(TRAppLinkTarget *appLinkTarget) {
                                            TRLauncher *launcher = [TRLauncher new];
                                            launcher.callback = callbackCopy;
                                            
                                            [launcher openAppWithTarget:appLinkTarget
                                                                    url:url];
                                            
                                            appLinksDataResolver = nil;
                                        } failure:^(NSError *error) {
                                            if (callbackCopy) {
                                                callbackCopy(error);
                                            }
                                            appLinksDataResolver = nil;
                                        }];
}

+ (NSURL*)urlForApp:(TRAppTrafi)appToLaunch
       fromLocation:(TRLocation*)fromLocation
         toLocation:(TRLocation*)toLocation {
    
    NSMutableArray *params = [NSMutableArray array];
    
    if (fromLocation) {
        if ([fromLocation.name length]) {
            [params addObject:[NSString stringWithFormat:kTRAppLinksFromNameFormat,
                               encodeUrlString(fromLocation.name)]];
        }
        
        NSString *coordinatesString = [NSString stringWithFormat:kTRAppLinksFromCoordinateFormat,
                                       fromLocation.coordinate.latitude,
                                       fromLocation.coordinate.longitude];

        [params addObject:coordinatesString];
    }
    
    if (toLocation) {
        if ([toLocation.name length]) {
            [params addObject:[NSString stringWithFormat:kTRAppLinksToNameFormat,
                               encodeUrlString(toLocation.name)]];
        }
        
        NSString *coordinatesString = [NSString stringWithFormat:kTRAppLinksToCoordinateFormat,
                                       toLocation.coordinate.latitude,
                                       toLocation.coordinate.longitude];
        
        [params addObject:coordinatesString];
    }
    else {
        [[NSException exceptionWithName:@"To location not provided"
                                 reason:@"You must provide destination location"
                                userInfo:nil] raise];
    }
    
    NSString *appHostName = nil;
    
    switch (appToLaunch) {
        case TRAppTrafiTurkey:
            appHostName = @"trafi.com.tr";
            break;
        case TRAppTrafiBrasil:
            appHostName = @"trafi.com.br";
            break;
        case TRAppTrafiLithuania:
            appHostName = @"marsrutai.lt";
            break;
        case TRAppTrafiLatvia:
            appHostName = @"trafi.lv";
            break;
        case TRAppTrafiEstonia:
            appHostName = @"trafi.ee";
            break;
        default:
            break;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/go?%@", appHostName, [params componentsJoinedByString:@"&"]];
    
    return [NSURL URLWithString:urlString];
}

@end

#pragma mark - TRLocation

@implementation TRLocation

+ (TRLocation*)locationWithCoordinate:(CLLocationCoordinate2D)coordinate {
    TRLocation *location = [TRLocation new];
    location->_coordinate = coordinate;
    
    return location;
}

+ (TRLocation*)locationWithName:(NSString*)name
                     coordinate:(CLLocationCoordinate2D)coordinate {
    TRLocation *location = [TRLocation new];
    location->_coordinate = coordinate;
    location->_name = name;
    
    return location;
}

@end