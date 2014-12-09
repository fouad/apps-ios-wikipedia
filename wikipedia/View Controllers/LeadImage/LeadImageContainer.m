//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageContainer.h"
#import "SessionSingleton.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "MWKSection+DisplayHtml.h"
#import "CommunicationBridge.h"
#import "NSObject+ConstraintsScale.h"
#import "LeadImageLabel.h"
#import "UIScreen+Extras.h"
#import "LeadImageThumbUrlFetcher.h"
#import "QueuesSingleton.h"

@interface LeadImageContainer()

@property (weak, nonatomic) IBOutlet LeadImageLabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation LeadImageContainer

-(void)awakeFromNib
{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self adjustConstraintsScaleForViews:@[self.imageView, self.label]];
}

-(void)didMoveToSuperview
{
    self.label.leadImageView = self.imageView;
}

-(UIImage *)getCurrentArticleFirstImage
{

// Temp code for getting first image.
//TODO: This should check article.image once it's in place



    UIImage *image = nil;
    MWKArticleStore *articleStore = [SessionSingleton sharedInstance].articleStore;
    NSArray *allSectionImages = articleStore.imageList.imagesBySection;
    for (NSArray *thisSectionImages in allSectionImages) {
        if (thisSectionImages.count > 0) {
            NSString *firstImageUrlString = thisSectionImages.firstObject;
            //NSLog(@"firstImage = %@", firstImageUrlString);
            MWKImage *mwkImage = [[SessionSingleton sharedInstance].articleStore imageWithURL:firstImageUrlString];
            image = [[SessionSingleton sharedInstance].articleStore UIImageWithImage:mwkImage];
            break;
        }
    }
    return image;
}

-(NSString *)getCurrentArticleTitle
{
    MWKSection *firstSection = [[SessionSingleton sharedInstance].articleStore sectionAtIndex:0];
    NSString *title = [firstSection getHeaderTitle];
    return [title getStringWithoutHTML];
}

-(NSString *)getCurrentArticleDescription
{

//TODO: make this be retrieved from Wikidata.

    return @"\nEnglish actor, comedian and filmmaker";
}

-(void)showLeadImageForCurrentArticle
{
//    self.imageView.image = nil;
    self.label.text = nil;
    
    BOOL isMainPage = [[SessionSingleton sharedInstance] isCurrentArticleMain];
    if (!isMainPage) {
//        self.imageView.image = [self getCurrentArticleFirstImage];
        [self.label setTitle: [self getCurrentArticleTitle]
                 description: [self getCurrentArticleDescription]];
   }
    
    [self performSelector: @selector(updateHeightOfLeadImageContainerAndDiv)
               withObject: nil
               afterDelay: 0.1f];
}

-(void)updateHeightOfLeadImageContainerAndDiv
{




//TODO:
/*
    -right now this is called every time the URLCache retrieves an image
        because it's pulling image from the article, but that image may
        arrive late. switching to download higher res version of the 
        article image will mean we won't want to do this anymore. we'll
        instead already know if there is going to be an image (if we have
        url returned with result?). so if url we'll know to reserve space
        for the image(* see note below). no jitter. will need to update the 
        article data store to allow for this image to be easily set/retrieved
        so back and forward button won't have to re-request it. (like w/wikidata
        description)
        
        * reserve both in the LeadImageContainer and in the web view's
        lead image div


    STEPS TO ROUTING PAGE IMAGE TO ARTICLE & USING PAGE IMAGE FROM LEAD IMAGE CONTAINER:
        -see if prop image is being added to article store
        -write fetcher for imageinfo to get lead image url from file name
        -have fetcher update article store lead image url var
        -have another fetcher for the image itself
        -have lead image container display the fetched image
    let brion know that creating placeholder MWKImage record for page image is ok
        i can then do custom fetcher for getting / saving the img binary

*/



//    BOOL noImage = self.imageView.image ? NO : YES;
    BOOL isLandscape = ![[UIScreen mainScreen] isPortrait];
    
    self.imageView.alpha = (isLandscape) ? 0.0f : 1.0f;
    
    self.label.textColor =
    (isLandscape || self.imageView.hidden) ? [UIColor blackColor] : [UIColor whiteColor];
    
    CGFloat labelHeight = self.label.frame.size.height;
    
    CGFloat containerHeight =
    (isLandscape || self.imageView.hidden) ? (-self.frame.size.height + labelHeight) : 0;

//[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{

    self.frame =
    (CGRect){
        {0, containerHeight},
        {self.frame.size.width, self.frame.size.height}
    };
    
    CGFloat webDivHeight = (isLandscape || self.imageView.hidden) ? labelHeight : self.bounds.size.height;
    
    [self.bridge sendMessage: @"setLeadImageDivHeight"
                 withPayload: @{@"height": @(webDivHeight)}];

//} completion:^(BOOL done){
//}];

}








-(void)setImageFileName:(NSString *)imageFileName
{
    _imageFileName = imageFileName;

//TODO: don't pull lead image if it's not a png or jpg!
// see "Torque" article for ugly example.


//TODO: only call LeadImageThumbUrlFetcher if article.image doesn't return a UIImage!
// right now we're always downloading the image
// need to use the image from article.image if it's already there, or use its image name
// if no image binary



//TODO: vary the resolution requested by screen density? if [UIScreen mainScreen].scale is
// 1 could use 320, if 2 could use 620. So use 320 * that scale :)

    
    if(imageFileName){
        self.imageView.hidden = NO;
        (void)[[LeadImageThumbUrlFetcher alloc] initAndFetchThumbUrlForImageNamed: imageFileName
                                                                            width: 640
                                                                      withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                                               thenNotifyDelegate: self];
    }else{
        self.imageView.hidden = YES;
    }



    

}






//TODO: fetch description from within this object.
// instead of triggering update on imageFileName change
// add a method, like update or something, which will trigger both image and
// description fetches.


- (void)fetchFinished: (id)sender
          fetchedData: (id)fetchedData
               status: (FetchFinalStatus)status
                error: (NSError *)error
{
    if ([sender isKindOfClass:[LeadImageThumbUrlFetcher class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {



NSString *leadImageUrl = fetchedData;

NSLog(@"LEAD IMAGE URL = %@", leadImageUrl);

(void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL: leadImageUrl
                                                 withManager: [QueuesSingleton sharedInstance].articleFetchManager
                                          thenNotifyDelegate: self];




            }
                break;
            case FETCH_FINAL_STATUS_FAILED:
            {
                
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
                
            }
                break;
        }
    } else if ([sender isKindOfClass:[ThumbnailFetcher class]]) {

        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {




//TODO: associate the image retrieved with article.image (once brion adds article.image)
// then we can make sure the lead image can pull directly from the cache once it's been
// retrieved so back and forward button will still cause lead image to be shown
UIImage *leadImage = [UIImage imageWithData:fetchedData];
self.imageView.image = leadImage;

[self showLeadImageForCurrentArticle];



            }
                break;
            case FETCH_FINAL_STATUS_FAILED:
            {
                
            }
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
                
            }
                break;
        }
    }

}













@end
