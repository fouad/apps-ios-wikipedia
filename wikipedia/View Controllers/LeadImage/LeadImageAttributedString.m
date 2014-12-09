//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageAttributedString.h"
#import "NSString+FormattedAttributedString.h"
#import "Defines.h"

#define TITLE_FONT_SIZE 30.0f
#define DESCRIPTION_FONT_SIZE 13.0f
#define DESCRIPTION_TOP_PADDING 5.0f

@implementation LeadImageAttributedString

+ (NSAttributedString *)attributedStringWithTitle: (NSString *)title
                                      description: (NSString *)description
                                        useShadow: (BOOL)useShadow
{

    CGFloat strokeWidth = -0.5;
    UIColor *strokeColor = [UIColor colorWithWhite:0.0f alpha:0.6];
    UIColor *shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6];
    CGFloat shadowBlurRadius = 1.5;

    NSMutableDictionary *titleAttributes =
    @{
      NSFontAttributeName: [UIFont fontWithName:@"Times New Roman" size:TITLE_FONT_SIZE * MENUS_SCALE_MULTIPLIER],
      NSStrokeWidthAttributeName: [NSNumber numberWithFloat:strokeWidth],
      NSStrokeColorAttributeName:strokeColor
      }.mutableCopy;
    
    NSMutableParagraphStyle *descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descriptionParagraphStyle.paragraphSpacingBefore = DESCRIPTION_TOP_PADDING * MENUS_SCALE_MULTIPLIER;
    
    NSMutableDictionary *descriptionAttributes =
    @{
      NSFontAttributeName: [UIFont systemFontOfSize:DESCRIPTION_FONT_SIZE * MENUS_SCALE_MULTIPLIER],
      NSParagraphStyleAttributeName : descriptionParagraphStyle,
      NSStrokeWidthAttributeName: [NSNumber numberWithFloat:strokeWidth],
      NSStrokeColorAttributeName:strokeColor
      }.mutableCopy;
    
    if (useShadow){
        NSShadow *shadow = [[NSShadow alloc] init];
        
        //[shadow setShadowColor : [UIColor redColor]];
        [shadow setShadowColor : shadowColor];
        [shadow setShadowOffset : CGSizeMake (0.5, 0.5)];
        [shadow setShadowBlurRadius : shadowBlurRadius];
        
        titleAttributes[NSShadowAttributeName] = shadow;
        descriptionAttributes[NSShadowAttributeName] = shadow;
    }
    
    return
    [@"$1$2" attributedStringWithAttributes: @{}
                        substitutionStrings: @[title, description]
                     substitutionAttributes: @[titleAttributes, descriptionAttributes]];
}

@end
