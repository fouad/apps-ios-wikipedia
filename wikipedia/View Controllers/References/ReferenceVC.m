//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ReferenceVC.h"
#import "WebViewController.h"
#import "SessionSingleton.h"
#import "MWLanguageInfo.h"
#import "WikipediaAppUtils.h"

#define REFERENCE_LINK_COLOR @"#2b6fb2"

@interface ReferenceVC ()

@property (strong, nonatomic) IBOutlet UIWebView *referenceWebView;

@end

@implementation ReferenceVC

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //NSLog(@"request = %@ \ntype = %d", request, navigationType);
    switch (navigationType) {
            case UIWebViewNavigationTypeOther:
                // YES allows the reference html to actually be loaded/displayed.
                return YES;
            break;
            case UIWebViewNavigationTypeLinkClicked: {
                NSURL *requestURL = [request URL];
                
// Test wiki link:
//requestURL = [NSURL URLWithString:@"/wiki/toast"];

                NSString *scheme = [requestURL scheme];
                
                // Open external link in Safari.
                if (
                    [scheme isEqualToString:@"http"]
                    ||
                    [scheme isEqualToString:@"https"]
                    ||
                    [scheme isEqualToString:@"mailto"]
                    ){
                    [[UIApplication sharedApplication] openURL:requestURL];
                
                // Or open wiki link in the WebViewController's web view.
                }else if ([requestURL.path hasPrefix:@"/wiki/"]) {

                    NSString *href = requestURL.path;
                    NSString *encodedTitle = [href substringWithRange:NSMakeRange(6, href.length - 6)];
                    NSString *title = [encodedTitle stringByRemovingPercentEncoding];
                    MWPageTitle *pageTitle = [MWPageTitle titleWithString:title];
                    [self.webVC navigateToPage: pageTitle
                                        domain: [SessionSingleton sharedInstance].currentArticleDomain
                               discoveryMethod: DISCOVERY_METHOD_LINK
                             invalidatingCache: NO];
                    [self.webVC referencesHide];
                }

                return NO;
            }
        default:
            return NO;
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Prevent this web view from blocking the article web view from scrolling to top
    // when title bar tapped. (Only one scroll view can have scrollsToTop set to YES for
    // the title bar tap to cause scroll-to-top.)
    self.referenceWebView.scrollView.scrollsToTop = NO;
    self.referenceWebView.delegate = self;

    NSString *domain = [SessionSingleton sharedInstance].currentArticleDomain;
    MWLanguageInfo *languageInfo = [MWLanguageInfo languageInfoForCode:domain];
    NSString *baseUrl = [NSString stringWithFormat:@"https://%@.wikipedia.org/", languageInfo.code];

    NSString *html = [NSString stringWithFormat:@"\
<html>\
<head>\
<base href='%@' target='_self'>\
<style>\
    *{\
        color:#999;\
        font-family:'Helvetica Neue';\
        font-size:14pt;\
        font-weight:normal;\
        line-height:148%%;\
        font-style:normal;\
        -webkit-text-size-adjust: none;\
        -webkit-hyphens: auto;\
        word-break: break-word;\
     }\
    BODY{\
        padding-left:10;\
        padding-right:10;\
     }\
    A, A *{\
        color:%@;\
        text-decoration:none;\
    }\
</style>\
</head>\
<body style='background-color:black;' lang='%@' dir='%@'>\
%@ %@\
</body>\
</html>\
", baseUrl, REFERENCE_LINK_COLOR, languageInfo.code, languageInfo.dir, self.linkText, self.html];

    [self.referenceWebView loadHTMLString:html baseURL:[NSURL URLWithString:@""]];
    
    CGFloat topInset = 32;
    
    CGFloat bottomInset = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? 0 : topInset;

    self.referenceWebView.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);

    //self.webView.layer.borderColor = [UIColor whiteColor].CGColor;
    //self.webView.layer.borderWidth = 25;
    
    //self.view.layer.borderColor = [UIColor whiteColor].CGColor;
    //self.view.layer.borderWidth = 1;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSString *eval = [NSString stringWithFormat:@"\
        document.getElementById('%@').oldBackgroundColor = document.getElementById('%@').style.backgroundColor;\
        document.getElementById('%@').style.backgroundColor = '#999';\
        document.getElementById('%@').style.borderRadius = 2;\
        ", self.linkId, self.linkId, self.linkId, self.linkId];

    [self.webVC.webView stringByEvaluatingJavaScriptFromString:eval];
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSString *eval = [NSString stringWithFormat:@"\
        document.getElementById('%@').style.backgroundColor = document.getElementById('%@').oldBackgroundColor;\
        ", self.linkId, self.linkId];

    [self.webVC.webView stringByEvaluatingJavaScriptFromString:eval];

    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
