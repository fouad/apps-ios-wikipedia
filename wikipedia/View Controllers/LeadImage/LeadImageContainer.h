//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "ThumbnailFetcher.h"

@class CommunicationBridge;

@interface LeadImageContainer : UIView <FetchFinishedDelegate>

@property (weak, nonatomic) CommunicationBridge *bridge;

@property (strong, nonatomic) NSString *imageFileName;

//-(void)showLeadImageForCurrentArticle;
-(void)updateHeightOfLeadImageContainerAndDiv;

@end
