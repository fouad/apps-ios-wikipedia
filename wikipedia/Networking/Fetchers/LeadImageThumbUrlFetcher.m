//  Created by Monte Hurd on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageThumbUrlFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface LeadImageThumbUrlFetcher()

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic) CGFloat width;

@end

@implementation LeadImageThumbUrlFetcher

-(instancetype)initAndFetchThumbUrlForImageNamed: (NSString *)imageName
                                           width: (CGFloat)width
                                     withManager: (AFHTTPRequestOperationManager *)manager
                              thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.imageName = imageName;
        self.width = width;
        self.fetchFinishedDelegate = delegate;
        [self fetchWithManager:manager];
    }
    return self;
}

- (void)fetchWithManager:(AFHTTPRequestOperationManager *)manager
{
    NSString *url = [SessionSingleton sharedInstance].searchApiUrl;

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Convert the raw NSData response to a dictionary.
        responseObject = [self dictionaryFromDataResponse:responseObject];

        // Convert the raw NSData response to a dictionary.
        if(![responseObject isDict]){
            // Fake out an error if bad response received.
            responseObject = @{@"error": @{@"info": @"Lead image thumbnail URL not found."}};
        }else{
            // Should be able to proceed with dictionary conversion.
/*
            NSError *jsonError = nil;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&jsonError];
            responseObject = jsonError ? @{} : responseObject;
*/
        }
        
        // NSLog(@"\n\nDATA RETRIEVED = %@\n\n", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Lead Image Thumb URL Fetcher"
                                        code: LEAD_IMAGE_THUMB_URL_ERROR_API
                                    userInfo: errorDict];
        }

        NSString *output = @"";
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        // If no matches set error.
        if (!output) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            
            // errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"search-no-matches", nil);
            
            // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
            error = [NSError errorWithDomain:@"Lead Image Thumb URL Fetcher" code:LEAD_IMAGE_THUMB_URL_ERROR_NO_MATCHES userInfo:errorDict];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Error = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSDictionary *)getParams
{
    return @{
             @"action": @"query",
             @"prop": @"imageinfo",
             @"iiprop": @"url|dimensions|mime|extmetadata",
             @"iiurlwidth": @(self.width),
             @"titles": [@"File:" stringByAppendingString:self.imageName],
             @"format": @"json"
             };
}

-(NSString *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSString *thumburl = nil;
    
//TODO: wrap these in a try/catch?
    NSDictionary *pages = rawResponse[@"query"][@"pages"];
    NSDictionary *page = pages[pages.allKeys[0]];
    thumburl = page[@"imageinfo"][0][@"thumburl"];

    return thumburl;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ACCT CREATION TOKEN FETCHER!");
}
*/

@end
