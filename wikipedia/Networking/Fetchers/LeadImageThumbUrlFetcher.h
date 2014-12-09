//  Created by Monte Hurd on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"
#import "Defines.h"
#import "SearchResultFetcher.h"

typedef NS_ENUM(NSInteger, LeadImageThumbUrlFetcherErrorType) {
    LEAD_IMAGE_THUMB_URL_ERROR_UNKNOWN = 0,
    LEAD_IMAGE_THUMB_URL_ERROR_API,
    LEAD_IMAGE_THUMB_URL_ERROR_NO_MATCHES
};

@class AFHTTPRequestOperationManager;

@interface LeadImageThumbUrlFetcher : FetcherBase

@property (nonatomic, strong, readonly) NSString *imageName;
@property (nonatomic, readonly) CGFloat width;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchThumbUrlForImageNamed: (NSString *)imageName
                                           width: (CGFloat)width
                                     withManager: (AFHTTPRequestOperationManager *)manager
                              thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
