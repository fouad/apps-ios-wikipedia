//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface LeadImageAttributedString : NSObject

+ (NSAttributedString *)attributedStringWithTitle: (NSString *)title
                                      description: (NSString *)description
                                        useShadow: (BOOL)useShadow;

@end
