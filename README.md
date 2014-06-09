TRLauncher
==========

There are two ways to launch trafi application. Using TRLauncher, or using other libraries, that supports [App Links](http://applinks.org).

### TRLauncher

We suggest you to use TRLauncher. Example below displays hot to launch TRAFI Türkiye application with directions from current location to Taksim squere.

    TRLocation *toLocation = [TRLocation locationWithName:@"Taksim Squere"
                                               coordinate:CLLocationCoordinate2DMake(41.036855, 28.986639)];
    
    [TRLauncher routeInApp:TRAppTrafiTurkey        //application you want to launch
                toLocation:toLocation              //destination location
        completionCallback:^(NSError *error) {
            if (error) {
                //see error, application is not launched
            }
        }];

In example above, current location is used as journey start location. If you want to specify start location use:

    + (void)routeInApp:(TRAppTrafi)appToLaunch
          fromLocation:(TRLocation*)fromLocation
            toLocation:(TRLocation*)toLocation
    completionCallback:(TRLauncherCallback)callback;
    
If you do not know name of location use:

    + (TRLocation*)locationWithCoordinate:(CLLocationCoordinate2D)coordinate


Currently supported applications:

- TRAppTrafiTurkey - TRAFI Türkiye
- TRAppTrafiBrasil - TRAFI Brasil
- TRAppTrafiLithuania - Maršrutai
- TRAppTrafiLatvia - TRAFI Latvija
- TRAppTrafiEstonia - TRAFI Eesti
        
### App Links

Trafi applications supports [App Links](http://applinks.org) specification. You can use any framework that supports [App Links](http://applinks.org) specification, or implement it yourself.
You should format url:

	http://<ApplicationUrl>/go?fromName=<LocationName>&fromCoord=<lat>,<lng>&toName=<LocationName>&toCoord=<lat>,<lng>

Here is example how you can launch TRAFI Türkiye application with directions from current location to Taksim squere using [BoltsFramework](https://github.com/BoltsFramework/Bolts-iOS):
    
    NSString *urlString = @"http://trafi.com.tr/go?toName=Taksim%20Squere&toCoord=41.036855,28.986639";
    NSURL *url = [NSURL URLWithString:url];
    [BFAppLinkNavigation navigateToURLInBackground:url];
    
    
List of available applications (use one of host name instead of ApplicationUrl):
- trafi.com.tr - TRAFI Türkiye
- trafi.com.br - TRAFI Brasil
- marsrutai.lt - Maršrutai
- trafi.lv - TRAFI Latvija
- trafi.ee - TRAFI Eesti
