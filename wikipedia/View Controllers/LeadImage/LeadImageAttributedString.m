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
    NSMutableDictionary *titleAttributes =
    @{
      NSFontAttributeName: [UIFont fontWithName:@"Times New Roman" size:TITLE_FONT_SIZE * MENUS_SCALE_MULTIPLIER]
      }.mutableCopy;
    
    NSMutableParagraphStyle *descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descriptionParagraphStyle.paragraphSpacingBefore = DESCRIPTION_TOP_PADDING * MENUS_SCALE_MULTIPLIER;
    
    NSMutableDictionary *descriptionAttributes =
    @{
      NSFontAttributeName: [UIFont systemFontOfSize:DESCRIPTION_FONT_SIZE * MENUS_SCALE_MULTIPLIER],
      NSParagraphStyleAttributeName : descriptionParagraphStyle
      }.mutableCopy;
    
    if (useShadow){
        NSShadow *shadow = [[NSShadow alloc] init];
        
        //[shadow setShadowColor : [UIColor redColor]];
        [shadow setShadowColor : [UIColor colorWithWhite:0.0f alpha:0.5]];
        [shadow setShadowOffset : CGSizeMake (0.0, 0.0)];
        [shadow setShadowBlurRadius : 1.0];
        
        titleAttributes[NSShadowAttributeName] = shadow;
        descriptionAttributes[NSShadowAttributeName] = shadow;
    }
    
    return
    [@"$1$2" attributedStringWithAttributes: @{}
                        substitutionStrings: @[title, description]
                     substitutionAttributes: @[titleAttributes, descriptionAttributes]];
}

@end
