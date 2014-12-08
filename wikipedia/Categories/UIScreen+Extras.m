//  Created by Monte Hurd on 11/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIScreen+Extras.h"

@implementation UIScreen (Extras)

-(BOOL)isThreePointFiveInchScreen
{

//TODO: Fix in iOS 8 and above - the bounds width and height change when
// interface orientation does. So the 480 check below won't work if
// device is landscape...

    return (((int)self.bounds.size.height) == 480);
}

-(BOOL)isPortrait {
    // UIViewController's interfaceOrientation property is deprecated - the status
    // bar's orientation isn't...
    return UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
}

@end
