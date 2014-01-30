//  Created by Monte Hurd on 1/15/14.

#import "UIViewController+Alert.h"
#import "AlertLabel.h"
#import "AlertWebView.h"
#import "SessionSingleton.h"

@implementation UIViewController (Alert)

-(void)showAlert:(NSString *)alertText
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        AlertLabel *alertLabel = nil;
        
        UIView *alertLabelContainer = self.view;
        
        // Special case for web view alerts so they attach not to the view controller's
        // view but to the top of the webView itself.
        // (Invokes selector in way that doesn't show annoying compiler warning.)
        SEL selector = NSSelectorFromString(@"webView");
        if ([self respondsToSelector:selector]) {
            alertLabelContainer = ((id (*)(id, SEL))[self methodForSelector:selector])(self, selector);
        }
        
        // Reuse existing alert label if any.
        for (UIView *view in alertLabelContainer.subviews) {
            if ([view isMemberOfClass:[AlertLabel class]]) {
                alertLabel = (AlertLabel *)view;
                break;
            }
        }
        
        // If none to reuse, add one.
        if (!alertLabel) {
            alertLabel = [[AlertLabel alloc] init];
            alertLabel.translatesAutoresizingMaskIntoConstraints = NO;
            if (alertLabelContainer) {
                [alertLabelContainer addSubview:alertLabel];
                [self constrainAlertLabel:alertLabel];
            }
        }
        
        alertLabel.text = alertText;
    }];
}

-(void)constrainAlertLabel:(AlertLabel *)alertLabel
{
    NSDictionary *viewsDictionary = nil;
    NSString *verticalFormatString = nil;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        // Pre iOS 7:
        viewsDictionary = NSDictionaryOfVariableBindings (alertLabel);
        verticalFormatString = @"V:|[alertLabel]";
    }else{
        id topGuide = self.topLayoutGuide;
        viewsDictionary = NSDictionaryOfVariableBindings (alertLabel, topGuide);
        verticalFormatString = @"V:[topGuide][alertLabel]";
    }

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[alertLabel]|"
                                             options: 0
                                             metrics: nil
                                               views: viewsDictionary
      ]
     ];

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: verticalFormatString
                                             options: 0
                                             metrics: nil
                                               views: viewsDictionary
      ]
     ];
}

-(void)showHTMLAlert:(NSString *)alertHTML dismissalText:(NSString *)text dismissalImage:(UIImage *)image;
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        AlertWebView *alertWebView = nil;
        
        UIView *alertLabelContainer = self.view;
        
        // Special case for web view alerts so they attach not to the view controller's
        // view but to the top of the webView itself.
        // (Invokes selector in way that doesn't show annoying compiler warning.)
        SEL selector = NSSelectorFromString(@"webView");
        if ([self respondsToSelector:selector]) {
            alertLabelContainer = ((id (*)(id, SEL))[self methodForSelector:selector])(self, selector);
        }
        
        // Reuse existing alert web view if any.
        for (UIView *view in alertLabelContainer.subviews) {
            if ([view isMemberOfClass:[AlertWebView class]]) {
                alertWebView = (AlertWebView *)view;
                break;
            }
        }
        
        // If none to reuse, add one.
        if (!alertWebView) {
            alertWebView = [[AlertWebView alloc] init];
            alertWebView.actionLabel.text = text;
            [alertWebView.actionButton setImage:image forState:UIControlStateNormal];
            alertWebView.translatesAutoresizingMaskIntoConstraints = NO;
            if (alertLabelContainer) {
                [alertLabelContainer addSubview:alertWebView];
                [self constrainAlertWebView:alertWebView];
            }
        }

        NSURL *baseUrl = [[SessionSingleton sharedInstance] urlForDomain:[SessionSingleton sharedInstance].currentArticleDomain];

        [alertWebView.webView loadHTMLString:alertHTML baseURL:baseUrl];
    }];
}

-(void)constrainAlertWebView:(AlertWebView *)alertWebView
{
    NSDictionary *viewsDictionary = nil;
    NSString *verticalFormatString = nil;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        // Pre iOS 7:
        viewsDictionary = NSDictionaryOfVariableBindings (alertWebView);
        verticalFormatString = @"V:|[alertWebView]|";
    }else{
        id topGuide = self.topLayoutGuide;
        viewsDictionary = NSDictionaryOfVariableBindings (alertWebView, topGuide);
        verticalFormatString = @"V:[topGuide][alertWebView]|";
    }

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[alertWebView]|"
                                             options: 0
                                             metrics: nil
                                               views: viewsDictionary
      ]
     ];

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: verticalFormatString
                                             options: 0
                                             metrics: nil
                                               views: viewsDictionary
      ]
     ];
}

@end
