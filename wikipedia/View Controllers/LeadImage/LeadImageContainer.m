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
//TODO: make this method be something the api can tell us in one line

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
    self.imageView.image = nil;
    self.label.text = nil;
    
    BOOL isMainPage = [[SessionSingleton sharedInstance] isCurrentArticleMain];
    if (!isMainPage) {
        self.imageView.image = [self getCurrentArticleFirstImage];
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



    BOOL noImage = self.imageView.image ? NO : YES;
    BOOL isLandscape = ![[UIScreen mainScreen] isPortrait];
    
    self.imageView.alpha = (isLandscape) ? 0.0f : 1.0f;
    
    self.label.textColor =
    (isLandscape || noImage) ? [UIColor blackColor] : [UIColor whiteColor];
    
    CGFloat labelHeight = self.label.frame.size.height;
    
    CGFloat containerHeight =
    (isLandscape || noImage) ? (-self.frame.size.height + labelHeight) : 0;

//[UIView animateWithDuration:0.5 delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{

    self.frame =
    (CGRect){
        {0, containerHeight},
        {self.frame.size.width, self.frame.size.height}
    };
    
    CGFloat webDivHeight = (isLandscape || noImage) ? labelHeight : self.bounds.size.height;
    
    [self.bridge sendMessage: @"setLeadImageDivHeight"
                 withPayload: @{@"height": @(webDivHeight)}];

//} completion:^(BOOL done){
//}];

}

@end
