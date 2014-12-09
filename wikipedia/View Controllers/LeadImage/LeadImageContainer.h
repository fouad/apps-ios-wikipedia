//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class CommunicationBridge;

@interface LeadImageContainer : UIView

@property (weak, nonatomic) CommunicationBridge *bridge;

-(void)showLeadImageForCurrentArticle;
-(void)updateHeightOfLeadImageContainerAndDiv;

@end
