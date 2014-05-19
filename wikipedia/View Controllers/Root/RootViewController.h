//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class TopMenuViewController, BottomMenuViewController, CenterNavController;

@interface RootViewController : UIViewController

@property (weak, nonatomic) TopMenuViewController *topMenuViewController;
@property (weak, nonatomic) CenterNavController *centerNavController;
@property (weak, nonatomic) BottomMenuViewController *bottomMenuViewController;

@property (nonatomic) BOOL topMenuHidden;
@property (nonatomic) BOOL bottomMenuHidden;

-(void)updateTopAndBottomMenuVisibilityForViewController:(UIViewController *)viewController;

-(void)animateTopAndBottomMenuToggle;

@end
