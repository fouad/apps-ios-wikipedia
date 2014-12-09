//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageLabel.h"
#import "Defines.h"
#import "LeadImageAttributedString.h"
#import "UIScreen+Extras.h"

#define PADDING UIEdgeInsetsMake(18, 22, 18, 22)

@implementation LeadImageLabel

-(void)setTitle: (NSString *)title
    description: (NSString *)description
{
    BOOL useShadow = (self.leadImageView.image && [[UIScreen mainScreen] isPortrait]);
    self.attributedText =
    [LeadImageAttributedString attributedStringWithTitle: title
                                             description: description
                                               useShadow: useShadow];
}

-(void)didMoveToSuperview
{
    self.padding = PADDING;
}

- (void)drawGradientBackground:(CGRect)rect
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat colorComponents[8] = {
        0.0, 0.0, 0.0, 0.0,    // Starting color.
        0.0, 0.0, 0.0, 0.66    // Ending color.
    };
    
    size_t locationCount = 2;
    CGFloat locations[] = {0.0, 1.0};
    CGGradientRef gradient =
    CGGradientCreateWithColorComponents(colorSpace, colorComponents, locations, locationCount);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

- (void)drawRect:(CGRect)rect
{
    if (!self.leadImageView.hidden && [[UIScreen mainScreen] isPortrait]) {
        [self drawGradientBackground:rect];
    }
    [super drawRect:rect];
}

@end
