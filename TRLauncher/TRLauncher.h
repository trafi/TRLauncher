//
//  TRAppLauncher.h
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, TRAppTrafi) {
    TRAppTrafiTurkey = 0,   // TRAFI Türkiye
    TRAppTrafiBrasil,       // TRAFI Brasil
    TRAppTrafiLithuania,    // Maršrutai
    TRAppTrafiLatvia,       // TRAFI Latvija
    TRAppTrafiEstonia       // TRAFI Eesti
};

@class TRLocation;

typedef void (^TRLauncherCallback)(NSError *error);

@interface TRLauncher : NSObject

/*!
 Launches the application  you selected to launch,
 if there is no application installed on device,
 it launches appstore or or web site.
 Start point is current user location.
 
 @param appToLaunch An enum value identifying application.
 @param toLocation The destination Location.
 @param callback Use callback if you wanna know if app was launched successfully.
 */
+ (void)routeInApp:(TRAppTrafi)appToLaunch
        toLocation:(TRLocation*)toLocation
completionCallback:(TRLauncherCallback)callback;

/*!
 Launches the application  you selected to launch,
 if there is no application installed on device,
 it launches appstore or or web site.
 Start point is current user location.
 
 @param appToLaunch An enum value identifying application.
 @param fromLocation The start Location.
 @param toLocation The destination Location.
 @param callback Use callback if you wanna know if app was launched successfully.
 */
+ (void)routeInApp:(TRAppTrafi)appToLaunch
      fromLocation:(TRLocation*)fromLocation
        toLocation:(TRLocation*)toLocation
completionCallback:(TRLauncherCallback)callback;

@end

@interface TRLocation : NSObject

/*!
 The name of the location.
 */
@property (nonatomic, copy) NSString *name;

/*!
 The coordinate of the location.
 */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/*!
 Creates a TRLocation with given coordinate.

 @param coordinate The coordinate of the location.
 */
+ (TRLocation*)locationWithCoordinate:(CLLocationCoordinate2D)coordinate;

/*!
 Creates a TRLocation given coordinate.
 
 @param name The name of the location.
 @param coordinate The coordinate of the location.
 */

+ (TRLocation*)locationWithName:(NSString*)name
                     coordinate:(CLLocationCoordinate2D)coordinate;

@end
