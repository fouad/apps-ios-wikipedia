//  Created by Monte Hurd on 2/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CaptchaViewController.h"
#import "EditFunnel.h"
#import "FetcherBase.h"

@class NSManagedObjectID;

@interface PreviewAndSaveViewController : UIViewController <NetworkOpDelegate, FetchFinishedDelegate, UITextFieldDelegate, CaptchaViewControllerRefresh, UIScrollViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;
@property (strong, nonatomic) SavedPagesFunnel *savedPagesFunnel;
@property (strong, nonatomic) NSString *abuseFilterCode;

-(void)reloadCaptchaPushed:(id)sender;

@property (strong, nonatomic) NSString *summaryText;

@end
