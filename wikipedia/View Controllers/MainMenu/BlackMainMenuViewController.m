//  Created by Monte Hurd on 5/22/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BlackMainMenuViewController.h"
#import "TopMenuButtonView.h"
#import "TopMenuLabel.h"
#import "WMF_WikiFont_Chars.h"
#import "BlackMenuTableViewCell.h"
#import "NSString+extras.h"
#import "WikipediaAppUtils.h"
#import "UIView+TemporaryAnimatedXF.h"
#import "SessionSingleton.h"

#import "LoginViewController.h"
#import "HistoryViewController.h"
#import "SavedPagesViewController.h"
#import "PageHistoryViewController.h"
#import "UIViewController+Alert.h"

#import "QueuesSingleton.h"
#import "DownloadTitlesForRandomArticlesOp.h"

#import "MainMenuViewController.h"
#import "TopMenuViewController.h"

#import "TopMenuContainerView.h"
#import "TopMenuViewController.h"

typedef NS_ENUM(NSInteger, BlackMenuItemTag) {
    BLACK_MENU_ITEM_UNKNOWN = 0,
    BLACK_MENU_ITEM_LOGIN = 1,
    BLACK_MENU_ITEM_RANDOM = 2,
    BLACK_MENU_ITEM_RECENT = 3,
    BLACK_MENU_ITEM_SAVEDPAGES = 4,
    BLACK_MENU_ITEM_MORE = 6
};

@interface BlackMainMenuViewController ()

@property (weak, nonatomic) IBOutlet TopMenuButtonView *moreButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *tableData;

@property (weak, nonatomic) TopMenuViewController *topMenuViewController;

@end

@implementation BlackMainMenuViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed_in_BlackMainMenuViewController"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.topMenuViewController.navBarStyle = NAVBAR_STYLE_NIGHT;
    self.topMenuViewController.navBarMode = NAVBAR_MODE_X_WITH_LABEL;
    self.topMenuViewController.navBarContainer.showBottomBorder = NO;

    /*
     TopMenuLabel *label = [self.topMenuViewController getNavBarItem:NAVBAR_LABEL];
     label.text = @"Saved Pages";
     label.font = [UIFont systemFontOfSize:21];
     label.textAlignment = NSTextAlignmentCenter;
     */

    [self setupTableData];
    //[self randomizeTitles];

    [self.moreButton.label setWikiText: WIKIFONT_CHAR_ELLIPSIS
                                 color: [UIColor darkGrayColor]
                                  size: 64];

    self.moreButton.label.textAlignment = NSTextAlignmentLeft;

    self.moreButton.label.padding = UIEdgeInsetsMake(0, 12, 0, 12);

    [self addTableHeaderView];
    
    [self.moreButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreButtonTapped)]];
}

-(void)addTableHeaderView
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 38)];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[QueuesSingleton sharedInstance].randomArticleQ cancelAllOperations];
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(navItemTappedNotification:)
                                                 name: @"NavItemTapped"
                                               object: nil];
}

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self hide];

            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupTableData
{
    self.tableData = @[].mutableCopy;

    NSString *userName = [SessionSingleton sharedInstance].keychainCredentials.userName;
    if(!userName){
        [self.tableData addObject:@{
            @"title": MWLocalizedString(@"main-menu-account-login", nil),
            @"tag": @(BLACK_MENU_ITEM_LOGIN)
        }.mutableCopy];
    }

    [self.tableData addObjectsFromArray: @[
        @{
            @"title": MWLocalizedString(@"main-menu-random", nil),
            @"tag": @(BLACK_MENU_ITEM_RANDOM)
        }.mutableCopy,
        @{
            @"title": MWLocalizedString(@"main-menu-show-history", nil),
            @"tag": @(BLACK_MENU_ITEM_RECENT)
        }.mutableCopy,
        @{
            @"title": MWLocalizedString(@"main-menu-show-saved", nil),
            @"tag": @(BLACK_MENU_ITEM_SAVEDPAGES)
        }.mutableCopy
    ]];
}

-(void)randomizeTitles
{
    for (NSMutableDictionary *rowData in self.tableData) {
        rowData[@"title"] = [@"abc " randomlyRepeatMaxTimes:50];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"BlackMenuCell";

    BlackMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

    NSMutableDictionary *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.label.text = rowData[@"title"];

    // Set "tag" so if this item is tapped we can have a pointer to the label
    // which is presently onscreen in this cell so it can be animated. Note:
    // this is needed because table cells get reused.
    NSNumber *tagNumber = rowData[@"tag"];
    cell.label.tag = tagNumber.integerValue;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Getting dynamic cell height which respects auto layout constraints is tricky.

    // First get the cell configured exactly as it is for display.
    BlackMenuTableViewCell *cell =
        (BlackMenuTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];

    // Then coax the cell into taking on the size that would satisfy its layout constraints (and
    // return that size's height).
    // From: http://stackoverflow.com/a/18746930/135557
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    cell.bounds = CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, cell.bounds.size.height);
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    return ([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlackMenuTableViewCell *cell =
        (BlackMenuTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    NSDictionary *selectedRowDict = self.tableData[indexPath.row];
    NSNumber *tagNumber = selectedRowDict[@"tag"];

    [self animateView:cell thenPerformActionForItem:tagNumber.integerValue];
}

-(void)moreButtonTapped
{
    [self animateView:self.moreButton thenPerformActionForItem:BLACK_MENU_ITEM_MORE];
}

-(void)animateView:(UIView *)view thenPerformActionForItem:(BlackMenuItemTag)tag
{
    [view animateAndRewindXF: CATransform3DMakeScale(1.03f, 1.03f, 1.04f)
                  afterDelay: 0.0
                    duration: 0.1
                        then: ^{
                            [self performActionForItem:tag];
                        }];
}

-(void)performActionForItem:(BlackMenuItemTag)tag
{
    switch (tag) {
        case BLACK_MENU_ITEM_LOGIN: {
            LoginViewController *loginVC =
            [NAV.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [NAV pushViewController:loginVC animated:YES];
[self hide];
            
        }
            break;
        case BLACK_MENU_ITEM_RANDOM: {
            [self showAlert:MWLocalizedString(@"fetching-random-article", nil)];
            [self fetchRandomArticle];
[self hide];
        }
            break;
        case BLACK_MENU_ITEM_RECENT: {
            HistoryViewController *historyVC =
            [NAV.storyboard instantiateViewControllerWithIdentifier:@"HistoryViewController"];
//            [NAV pushViewController:historyVC animated:YES];
//[self hide];
        [self presentViewController:historyVC animated:YES completion:^{}];

        }
            break;
        case BLACK_MENU_ITEM_SAVEDPAGES: {
            SavedPagesViewController *savedPagesVC =
            [NAV.storyboard instantiateViewControllerWithIdentifier:@"SavedPagesViewController"];
//            [NAV pushViewController:savedPagesVC animated:YES];

        [self presentViewController:savedPagesVC animated:YES completion:^{}];

//[self hide];




        }
            break;
        case BLACK_MENU_ITEM_MORE: {
            MainMenuViewController *mainMenuTableVC =
            [self.storyboard instantiateViewControllerWithIdentifier:@"MainMenuViewController"];
//            [NAV pushViewController:mainMenuTableVC animated:NO];
//[self hide];
        [self presentViewController:mainMenuTableVC animated:YES completion:^{}];

        }
            break;
        default:
            break;
    }
}

-(void)hide
{
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

-(void)fetchRandomArticle {

    [[QueuesSingleton sharedInstance].randomArticleQ cancelAllOperations];

    DownloadTitlesForRandomArticlesOp *downloadTitlesForRandomArticlesOp =
        [[DownloadTitlesForRandomArticlesOp alloc] initForDomain: [SessionSingleton sharedInstance].domain
                                                 completionBlock: ^(NSString *title) {
                                                     if (title) {
                                                         dispatch_async(dispatch_get_main_queue(), ^(){
                                                             [NAV loadArticleWithTitle: title
                                                                                domain: [SessionSingleton sharedInstance].domain
                                                                              animated: YES
                                                                       discoveryMethod: DISCOVERY_METHOD_RANDOM
                                                                     invalidatingCache: NO];
                                                         });
                                                     }
                                                 } cancelledBlock: ^(NSError *errorCancel) {
                                                    [self fadeAlert];
                                                 } errorBlock: ^(NSError *error) {
                                                    [self showAlert:error.localizedDescription];
                                                 }];

    [[QueuesSingleton sharedInstance].randomArticleQ addOperation:downloadTitlesForRandomArticlesOp];
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
