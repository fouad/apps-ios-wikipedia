//  Created by Monte Hurd on 12/16/13.

#import "NavBarTextField.h"
#import "NavController.h"
#import "Defines.h"
#import "UIView+Debugging.h"
#import "UIView+RemoveConstraints.h"
#import "NavBarContainerView.h"
#import "MainMenuTableViewController.h"
#import "UIViewController+HideKeyboard.h"
#import "SearchResultsController.h"
#import "UINavigationController+SearchNavStack.h"

@interface NavController (){

}

// Container.
@property (strong, nonatomic) UIView *navBarContainer;

// Views which go into the container.
@property (strong, nonatomic) NavBarTextField *textField;
@property (strong, nonatomic) UIView *verticalLine1;
@property (strong, nonatomic) UIView *verticalLine2;
@property (strong, nonatomic) UIView *verticalLine3;
@property (strong, nonatomic) UIView *verticalLine4;
@property (strong, nonatomic) UIView *verticalLine5;
@property (strong, nonatomic) UIView *verticalLine6;
@property (strong, nonatomic) UIButton *buttonW;
@property (strong, nonatomic) UIButton *buttonPencil;
@property (strong, nonatomic) UIButton *buttonCheck;
@property (strong, nonatomic) UIButton *buttonX;
@property (strong, nonatomic) UIButton *buttonEye;
@property (strong, nonatomic) UIButton *buttonArrowLeft;
@property (strong, nonatomic) UIButton *buttonArrowRight;
@property (strong, nonatomic) UILabel *label;


// Used for constraining container sub-views.
@property (strong, nonatomic) NSString *navBarSubViewsHorizontalVFLString;
@property (strong, nonatomic) NSDictionary *navBarSubViews;
@property (strong, nonatomic) NSDictionary *navBarSubViewMetrics;

@end

@implementation NavController

-(id)getNavBarItem:(NavBarItemTag)tag
{
    for (UIView *view in self.navBarContainer.subviews) {
        if (view.tag == tag) return view;
    }
    return nil;
}

-(NSDictionary *)getNavBarSubViews
{
    return @{
             @"NAVBAR_BUTTON_X": self.buttonX,
             @"NAVBAR_BUTTON_PENCIL": self.buttonPencil,
             @"NAVBAR_BUTTON_CHECK": self.buttonCheck,
             @"NAVBAR_BUTTON_ARROW_LEFT": self.buttonArrowLeft,
             @"NAVBAR_BUTTON_ARROW_RIGHT": self.buttonArrowRight,
             @"NAVBAR_BUTTON_LOGO_W": self.buttonW,
             @"NAVBAR_BUTTON_EYE": self.buttonEye,
             @"NAVBAR_TEXT_FIELD": self.textField,
             @"NAVBAR_LABEL": self.label,
             @"NAVBAR_VERTICAL_LINE_1": self.verticalLine1,
             @"NAVBAR_VERTICAL_LINE_2": self.verticalLine2,
             @"NAVBAR_VERTICAL_LINE_3": self.verticalLine3,
             @"NAVBAR_VERTICAL_LINE_4": self.verticalLine4,
             @"NAVBAR_VERTICAL_LINE_5": self.verticalLine5,
             @"NAVBAR_VERTICAL_LINE_6": self.verticalLine6
             };
}

-(NSDictionary *)getNavBarSubViewMetrics
{
    return @{
             @"singlePixel": @(1.0f / [UIScreen mainScreen].scale)
             };
}

-(void)setNavBarStyle:(NavBarStyle)navBarStyle
{
        _navBarStyle = navBarStyle;
        switch (navBarStyle) {
            case NAVBAR_STYLE_EDIT_WIKITEXT:
                self.label.text = @"Edit";
            case NAVBAR_STYLE_LOGIN:
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_X(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_CHECK(50)]|";

self.navBarDayMode = NO;

                break;
            case NAVBAR_STYLE_EDIT_WIKITEXT_WARNING:
                self.label.text = @"Edit issues";
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_CHECK(50)][NAVBAR_VERTICAL_LINE_1(singlePixel)]-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_2(singlePixel)][NAVBAR_BUTTON_PENCIL(50)]|";
                break;
            case NAVBAR_STYLE_EDIT_WIKITEXT_DISALLOW:
                self.label.text = @"Edit issues";
                self.navBarSubViewsHorizontalVFLString = @"H:|-(10)-[NAVBAR_LABEL][NAVBAR_VERTICAL_LINE_1(singlePixel)][NAVBAR_BUTTON_PENCIL(50)]|";
                break;
            default: //NAVBAR_STYLE_SEARCH
                self.navBarSubViewsHorizontalVFLString = @"H:|[NAVBAR_BUTTON_LOGO_W(65)][NAVBAR_VERTICAL_LINE_1(singlePixel)][NAVBAR_TEXT_FIELD]-(10)-|";

self.navBarDayMode = YES;

                break;
        }
        [self.view setNeedsUpdateConstraints];
}

-(void)clearTextFieldText
{
    self.textField.text = @"";
    self.textField.rightView.hidden = YES;
}

-(void)setupNavbarContainerSubviews
{
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        self.navigationBar.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:0.97];
    }

    self.textField = [[NavBarTextField alloc] init];
    self.textField.delegate = self;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.returnKeyType = UIReturnKeyGo;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.font = SEARCH_FONT;
    self.textField.textColor = SEARCH_FONT_HIGHLIGHTED_COLOR;
    self.textField.tag = NAVBAR_TEXT_FIELD;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.textField addTarget:self action:@selector(navItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.navBarContainer addSubview:self.textField];
 
    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 26, 26)];
    [clearButton setImage:[UIImage imageNamed:@"text_field_x_circle_gray.png"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearTextFieldText) forControlEvents:UIControlEventTouchUpInside];
    
    self.textField.rightView = clearButton;
    self.textField.rightViewMode = UITextFieldViewModeWhileEditing;

    UIView *(^getLineView)() = ^UIView *() {
        UIView *view = [[UIView alloc] init];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.backgroundColor = [UIColor lightGrayColor];
        view.tag = NAVBAR_VERTICAL_LINE;
        return view;
    };
    
    self.verticalLine1 = getLineView();
    self.verticalLine2 = getLineView();
    self.verticalLine3 = getLineView();
    self.verticalLine4 = getLineView();
    self.verticalLine5 = getLineView();
    self.verticalLine6 = getLineView();
    
    [self.navBarContainer addSubview:self.verticalLine1];
    [self.navBarContainer addSubview:self.verticalLine2];
    [self.navBarContainer addSubview:self.verticalLine3];
    [self.navBarContainer addSubview:self.verticalLine4];
    [self.navBarContainer addSubview:self.verticalLine5];
    [self.navBarContainer addSubview:self.verticalLine6];

    UIButton *(^getButton)(NSString *, NavBarItemTag) = ^UIButton *(NSString *image, NavBarItemTag tag) {
        UIButton *button = [[UIButton alloc] init];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = [UIColor clearColor];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(navItemTapped:) forControlEvents:UIControlEventTouchUpInside];

        button.tag = tag;
        return button;
    };

    self.buttonPencil =     getButton(@"abuse-filter-edit-black.png",   NAVBAR_BUTTON_PENCIL);
    self.buttonCheck =      getButton(@"abuse-filter-check.png",        NAVBAR_BUTTON_CHECK);
    self.buttonX =          getButton(@"button_cancel_grey.png",        NAVBAR_BUTTON_X);
    self.buttonEye =        getButton(@"button_preview_white.png",      NAVBAR_BUTTON_EYE);
    self.buttonArrowLeft =  getButton(@"button_arrow_left.png",         NAVBAR_BUTTON_ARROW_LEFT);
    self.buttonArrowRight = getButton(@"button_arrow_right.png",        NAVBAR_BUTTON_ARROW_RIGHT);
    self.buttonW =          getButton(@"w.png",                         NAVBAR_BUTTON_LOGO_W);

    [self.navBarContainer addSubview:self.buttonPencil];
    [self.navBarContainer addSubview:self.buttonCheck];
    [self.navBarContainer addSubview:self.buttonX];
    [self.navBarContainer addSubview:self.buttonEye];
    [self.navBarContainer addSubview:self.buttonArrowLeft];
    [self.navBarContainer addSubview:self.buttonArrowRight];
    [self.navBarContainer addSubview:self.buttonW];

    self.label = [[UILabel alloc] init];
    self.label.text = @"";
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.tag = NAVBAR_LABEL;
    self.label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
    self.label.textColor = [UIColor darkGrayColor];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navItemTapped:)];
    [self.label addGestureRecognizer:tapLabel];
    [self.navBarContainer addSubview:self.label];
}

-(void)navItemTapped:(id)sender
{
    UIView *tappedView = nil;
    if([sender isKindOfClass:[UIGestureRecognizer class]]){
        tappedView = ((UIGestureRecognizer *)sender).view;
    }else{
        tappedView = sender;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NavItemTapped" object:self userInfo:
        @{@"tappedItem": tappedView}
    ];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
 
    self.currentSearchResultsOrdered = [@[] mutableCopy];
    self.currentSearchString = @"";

    [self setupNavbarContainer];
    [self setupNavbarContainerSubviews];


self.navBarDayMode = YES;


    [self.buttonW addTarget:self action:@selector(mainMenuToggle) forControlEvents:UIControlEventTouchUpInside];

    self.navBarStyle = NAVBAR_STYLE_SEARCH;

    self.textField.placeholder = SEARCH_FIELD_PLACEHOLDER_TEXT;

    [self.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];

    // Perform search when text entered into textField
    [self.textField addTarget:self action:@selector(searchStringChanged) forControlEvents:UIControlEventEditingChanged];
    
    self.navBarSubViews = [self getNavBarSubViews];
    
    self.navBarSubViewMetrics = [self getNavBarSubViewMetrics];
}






























- (UIStatusBarStyle)preferredStatusBarStyle
 {
     return (self.navBarDayMode) ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
 }

-(void)setNavBarDayMode:(BOOL)navBarDayMode
{
    if (_navBarDayMode != navBarDayMode) {
        _navBarDayMode = navBarDayMode;
        

        if (navBarDayMode) {    //Day
            [self.navigationBar setBarTintColor:[UIColor whiteColor]];


        }else{                  //Night
            [self.navigationBar setBarTintColor:[UIColor blackColor]];


        }

    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }






        
        for (id view in self.navBarContainer.subviews) {
            [self makeView:view useDayMode:navBarDayMode];
        }
    }
}



- (UIImage *)getImageOfColor:(UIColor *)color usingImageMask:(UIImage *)maskImage
{
    CIImage *adjustedImage = [CIImage imageWithCGImage:maskImage.CGImage];

    CIFilter *colorClampFilter = [CIFilter filterWithName:@"CIColorClamp"];
    [colorClampFilter setValue: adjustedImage forKey:@"inputImage"];
    [colorClampFilter setDefaults];
    // From Apple's "Core Image Filter Reference":
    // "At each pixel, color component values less than those in inputMinComponents will be increased to match those in inputMinComponents"
    // So the next line is saying make any pixel which is not 100% clear become pure white.
    [colorClampFilter setValue: [CIVector vectorWithX:1.0 Y:1.0 Z:1.0 W:0.0] forKey:@"inputMinComponents"];
    adjustedImage = [colorClampFilter outputImage];

    CIImage *backgroundImage = [CIImage imageWithColor:[CIColor colorWithCGColor:[UIColor clearColor].CGColor]];
    CIImage *colorImage = [CIImage imageWithColor:[CIColor colorWithCGColor:color.CGColor]];
    CIFilter *maskFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    
    [maskFilter setValue: colorImage forKey:@"inputImage"];
    [maskFilter setValue: backgroundImage forKey:@"inputBackgroundImage"];
    [maskFilter setValue: adjustedImage forKey:@"inputMaskImage"];
    
    [maskFilter setDefaults];
    adjustedImage = [maskFilter outputImage];

    //See: http://stackoverflow.com/a/15886422/135557
    CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:adjustedImage fromRect:adjustedImage.extent];
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return outputImage;
}


-(void)makeView:(UIView *)view useDayMode:(BOOL)dayMode
{


// Both the button's image and the text field's clear image need to use the ciimage filter for inverting colors




    switch (view.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_BUTTON_PENCIL:
        case NAVBAR_BUTTON_CHECK:
        case NAVBAR_BUTTON_ARROW_LEFT:
        case NAVBAR_BUTTON_ARROW_RIGHT:
        case NAVBAR_BUTTON_LOGO_W:
        case NAVBAR_BUTTON_EYE:
{

UIImage *buttonImage = ((UIButton *)view).imageView.image;
UIImage *filteredImage = [self getImageOfColor:[UIColor brownColor] usingImageMask:buttonImage];
((UIButton *)view).imageView.image = filteredImage;

}

            break;
            
        case NAVBAR_TEXT_FIELD:
        
            // Typed text.
            ((UITextField *)view).textColor = (dayMode) ? [UIColor lightGrayColor] : [UIColor whiteColor];
            
            // Placeholder text.
            ((NavBarTextField *)view).placeholderColor = (dayMode) ? [UIColor lightGrayColor] : [UIColor whiteColor];
        
            break;
        case NAVBAR_LABEL:

            ((UILabel *)view).textColor = (dayMode) ? [UIColor lightGrayColor] : [UIColor whiteColor];

            break;
        case NAVBAR_VERTICAL_LINE:
                view.backgroundColor = (dayMode) ? [UIColor lightGrayColor] : [UIColor whiteColor];

            break;
        default:
            break;
    }
}


































-(void)setupNavbarContainer
{
    self.navBarContainer = [[NavBarContainerView alloc] init];
    self.navBarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.navBarContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.navBarContainer];
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    
    CGFloat duration = 0.3f;

    [self constrainNavBarContainer];
    [self constrainNavBarContainerSubViews];

    for (UIView *v in self.navBarContainer.subviews) v.alpha = 0.0f;

    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionTransitionNone animations:^{
        for (UIView *v in self.navBarContainer.subviews) v.alpha = 0.7f;
        [self.navBarContainer layoutIfNeeded];
    } completion:^(BOOL done){
        [UIView animateWithDuration:0.15 delay:0.1f options:UIViewAnimationOptionTransitionNone animations:^{
            for (UIView *v in self.navBarContainer.subviews) v.alpha = 1.0f;
        } completion:^(BOOL done){
        }];
    }];
}

-(void)constrainNavBarContainer
{
    // Remove existing navBarContainer constraints.
    [self.navBarContainer removeConstraintsOfViewFromView:self.view];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:|[navBarContainer]|"
                                                                      options: 0
                                                                      metrics: nil
                                                                        views: @{@"navBarContainer": self.navBarContainer}]];
    NSArray *constraintsArray = @[
                                  [NSLayoutConstraint constraintWithItem: self.navBarContainer
                                                               attribute: NSLayoutAttributeTop
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: self.view
                                                               attribute: NSLayoutAttributeTop
                                                              multiplier: 1.0
                                                                constant: self.navigationBar.frame.origin.y]
                                  ,
                                  [NSLayoutConstraint constraintWithItem: self.navBarContainer
                                                               attribute: NSLayoutAttributeHeight
                                                               relatedBy: NSLayoutRelationEqual
                                                                  toItem: NSLayoutAttributeNotAnAttribute
                                                               attribute: 0
                                                              multiplier: 1.0
                                                                constant: self.navigationBar.bounds.size.height]
                                  ];
    [self.view addConstraints:constraintsArray];
}

-(void)constrainNavBarContainerSubViews
{
    // Remove *all* navBarContainer constraints.
    [self.navBarContainer removeConstraints:self.navBarContainer.constraints];

    // Hide all navBarContainer subviews. Only those affected by navBarSubViewsHorizontalVFLString
    // will be revealed.
    for (UIView *v in [self.navBarContainer.subviews copy]) {
        v.hidden = YES;
    }

    // navBarSubViewsHorizontalVFLString controls which elements are going to be shown.
    [self.navBarContainer addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: self.navBarSubViewsHorizontalVFLString
                                             options: 0
                                             metrics: self.navBarSubViewMetrics
                                               views: self.navBarSubViews
      ]
     ];
    
    // Now take the views which were constrained horizontally (above) and constrain them
    // vertically as well. Also set hidden = NO for just these views.
    for (NSLayoutConstraint *c in [self.navBarContainer.constraints copy]) {
        UIView *view = (c.firstItem != self.navBarContainer) ? c.firstItem: c.secondItem;
        view.hidden = NO;
        [self.navBarContainer addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]|"
                                                 options: 0
                                                 metrics: @{@"topMargin": @((view.tag == NAVBAR_VERTICAL_LINE) ? 5 : 0)}
                                                   views: NSDictionaryOfVariableBindings(view)
          ]
         ];
    }

    // Constrain the views not being presently shown so when they are shown they'll animate from
    // the constrained position specified below.
    for (UIView *view in [self.navBarContainer.subviews copy]) {
        if (view.hidden) {
            [self.navBarContainer addConstraint:
             [NSLayoutConstraint constraintWithItem: view
                                          attribute: NSLayoutAttributeRight
                                          relatedBy: NSLayoutRelationEqual
                                             toItem: self.navBarContainer
                                          attribute: NSLayoutAttributeLeft
                                         multiplier: 1.0
                                           constant: 0.0
              ]
            ];
            [self.navBarContainer addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-(topMargin)-[view]|"
                                                     options: 0
                                                     metrics: @{@"topMargin": @((view.tag == NAVBAR_VERTICAL_LINE) ? 5 : 0)}
                                                       views: NSDictionaryOfVariableBindings(view)
              ]
             ];
        }
    }
}

#pragma mark Search term changed

- (void)searchStringChanged
{
    NSString *searchString = self.textField.text;

    NSString *trimmedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.currentSearchString = trimmedSearchString;

    [self showSearchResultsController];
    
    if (trimmedSearchString.length == 0){
        self.textField.rightView.hidden = YES;
        
        return;
    }
    self.textField.rightView.hidden = NO;
}

-(void)showSearchResultsController
{
    SearchResultsController *searchResultsVC = [self searchNavStackForViewControllerOfClass:[SearchResultsController class]];

    if(searchResultsVC){
        if (self.topViewController == searchResultsVC) {
            [searchResultsVC refreshSearchResults];
        }else{
            [self popToViewController:searchResultsVC animated:YES];
        }
    }else{
        SearchResultsController *searchResultsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsController"];
        [self pushViewController:searchResultsVC animated:YES];
    }
}

-(void)mainMenuToggle
{
    UIViewController *topVC = self.topViewController;

    [topVC hideKeyboard];
    
    MainMenuTableViewController *mainMenuTableVC = [self searchNavStackForViewControllerOfClass:[MainMenuTableViewController class]];
    
    if(mainMenuTableVC){
        [self popToRootViewControllerAnimated:YES];
    }else{
        MainMenuTableViewController *mainMenuTableVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MainMenuTableViewController"];
        [self pushViewController:mainMenuTableVC animated:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.navigationBar){
        if ([keyPath isEqualToString:@"bounds"]) {
            [self.view setNeedsUpdateConstraints];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchFieldBecameFirstResponder" object:self userInfo:nil];
    
    if (self.textField.text.length == 0) self.textField.rightView.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
