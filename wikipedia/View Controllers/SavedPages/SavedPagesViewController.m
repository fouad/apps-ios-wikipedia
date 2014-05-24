//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SavedPagesViewController.h"
#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "SavedPagesResultCell.h"
#import "Defines.h"
#import "Article+Convenience.h"
#import "SessionSingleton.h"
#import "UINavigationController+SearchNavStack.h"
#import "CenterNavController.h"
#import "NSString+Extras.h"

#import "TopMenuContainerView.h"
#import "TopMenuViewController.h"
#import "TopMenuLabel.h"

#define SAVED_PAGES_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define SAVED_PAGES_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:1.0f]
#define SAVED_PAGES_LANGUAGE_COLOR [UIColor colorWithWhite:0.0f alpha:0.4f]
#define SAVED_PAGES_RESULT_HEIGHT 116

@interface SavedPagesViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, nonatomic) NSMutableArray *savedPagesDataArray;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) TopMenuViewController *topMenuViewController;

@end

@implementation SavedPagesViewController

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Top menu

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed_in_SavedPagesViewController"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
    }
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

-(void)configureContainedTopMenu
{
    self.topMenuViewController.navBarStyle = NAVBAR_STYLE_DAY;
    self.topMenuViewController.navBarMode = NAVBAR_MODE_X_WITH_LABEL;
    self.topMenuViewController.navBarContainer.showBottomBorder = NO;
    
    TopMenuLabel *label = [self.topMenuViewController getNavBarItem:NAVBAR_LABEL];
    label.text = MWLocalizedString(@"saved-pages-title", nil);
    label.font = [UIFont systemFontOfSize:21];
    label.textAlignment = NSTextAlignmentCenter;
}

#pragma mark - Hiding

-(void)hide
{
    // Hide this view controller.
    if(!(self.isBeingPresented || self.isBeingDismissed)){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

-(void)hidePresenter
{
    // Hide the black menu which presented this view controller.
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated: YES
                                                                               completion: ^{}];
}

#pragma mark - View lifecycle

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureContainedTopMenu];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.savedPagesDataArray = [[NSMutableArray alloc] init];
    
    [self getSavedPagesData];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
    self.tableView.tableHeaderView = headerView;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    // Register the Saved Pages results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"SavedPagesResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"SavedPagesResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - SavedPages data

-(void)getSavedPagesData
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Saved"
                                              inManagedObjectContext: articleDataContext_.mainContext];
    [fetchRequest setEntity:entity];
    
    // For now fetch all Saved Pages records.
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateSaved" ascending:NO selector:nil];

    [fetchRequest setSortDescriptors:@[dateSort]];

    NSMutableArray *pages = [@[] mutableCopy];

    error = nil;
    NSArray *savedPagesEntities = [articleDataContext_.mainContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch.");
    for (Saved *savedPage in savedPagesEntities) {
        /*
        NSLog(@"SAVED:\n\t\
              article: %@\n\t\
              date: %@\n\t\
              image: %@",
              savedPage.article.title,
              savedPage.dateSaved,
              savedPage.article.thumbnailImage.fileName
              );
        */
        [pages addObject:savedPage.objectID];
    }
    
    [self.savedPagesDataArray addObject:[@{@"data": pages} mutableCopy]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Number of rows it should expect should be based on the section
    NSDictionary *dict = self.savedPagesDataArray[section];
    NSArray *array = [dict objectForKey:@"data"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"SavedPagesResultCell";
    SavedPagesResultCell *cell = (SavedPagesResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *dict = self.savedPagesDataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];

    __block Saved *savedEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)array[indexPath.row];
        savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
    }];
    
    NSString *title = [savedEntry.article.title wikiTitleWithoutUnderscores];
    NSString *language = [NSString stringWithFormat:@"\n%@", savedEntry.article.domainName];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;

    NSMutableAttributedString *(^styleText)(NSString *, CGFloat, UIColor *) = ^NSMutableAttributedString *(NSString *str, CGFloat size, UIColor *color){
        return [[NSMutableAttributedString alloc] initWithString:str attributes: @{
            NSFontAttributeName : [UIFont fontWithName:@"Georgia" size:size],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color,
        }];
    };

    NSMutableAttributedString *attributedTitle = styleText(title, 22, SAVED_PAGES_TEXT_COLOR);
    NSMutableAttributedString *attributedLanguage = styleText(language, 10, SAVED_PAGES_LANGUAGE_COLOR);
    
    [attributedTitle appendAttributedString:attributedLanguage];
    cell.textLabel.attributedText = attributedTitle;
    
    cell.methodImageView.image = nil;

    UIImage *thumbImage = [savedEntry.article getThumbnailUsingContext:articleDataContext_.mainContext];
    
    if(thumbImage){
        cell.imageView.image = thumbImage;
        cell.useField = YES;
        return cell;
    }

    // If execution reaches this point a cached core data thumb was not found.

    // Set thumbnail placeholder
//TODO: don't load thumb from file every time in loop if no image found. fix here and in search
    cell.imageView.image = [UIImage imageNamed:@"logo-search-placeholder.png"];
    cell.useField = NO;

    //if (!thumbURL){
    //    // Don't bother downloading if no thumbURL
    //    return cell;
    //}

//TODO: retrieve a thumb
    // determine thumbURL then get thumb
    // if no thumbURL mine section html for image reference and download it

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedCell = nil;
    NSDictionary *dict = self.savedPagesDataArray[indexPath.section];
    NSArray *array = dict[@"data"];
    selectedCell = array[indexPath.row];

    __block Saved *savedEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)array[indexPath.row];
        savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
    }];
    
    [NAV loadArticleWithTitle: savedEntry.article.title
                       domain: savedEntry.article.domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO];

    [self hidePresenter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SAVED_PAGES_RESULT_HEIGHT;
}

#pragma mark - Delete

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.tableView.editing = NO;
        [self performSelector:@selector(deleteSavedPageForIndexPath:) withObject:indexPath afterDelay:0.15f];
    }
}

-(void)deleteSavedPageForIndexPath:(NSIndexPath *)indexPath
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *savedEntryId = (NSManagedObjectID *)self.savedPagesDataArray[indexPath.section][@"data"][indexPath.row];
        Saved *savedEntry = (Saved *)[articleDataContext_.mainContext objectWithID:savedEntryId];
        if (savedEntry) {
            
            [self.tableView beginUpdates];

            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            NSError *error = nil;
            [articleDataContext_.mainContext deleteObject:savedEntry];
            [articleDataContext_.mainContext save:&error];
            
            [self.savedPagesDataArray[indexPath.section][@"data"] removeObject:savedEntryId];
            
            [self.tableView endUpdates];
        }
    }];
}

@end
