//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "HistoryViewController.h"
#import "WikipediaAppUtils.h"
#import "NSDate-Utilities.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "HistoryResultCell.h"
#import "Defines.h"
#import "Article+Convenience.h"
#import "CenterNavController.h"
#import "NSString+Extras.h"
#import "WikiGlyph_Chars.h"
#import "TopMenuContainerView.h"
#import "TopMenuViewController.h"
#import "UIViewController+StatusBarHeight.h"
#import "UIViewController+ModalPop.h"
#import "PaddedLabel.h"
#import "MenuButton.h"
#import "TopMenuViewController.h"
#import "CoreDataHousekeeping.h"

#define HISTORY_THUMBNAIL_WIDTH 110
#define HISTORY_RESULT_HEIGHT 66
#define HISTORY_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define HISTORY_LANGUAGE_COLOR [UIColor colorWithWhite:0.0f alpha:0.4f]
#define HISTORY_DATE_HEADER_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.6f]
#define HISTORY_DATE_HEADER_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.97f]
#define HISTORY_DATE_HEADER_HEIGHT 51.0f
#define HISTORY_DATE_HEADER_LEFT_PADDING 37.0f

@interface HistoryViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSMutableArray *historyDataArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HistoryViewController

-(NavBarMode)navBarMode
{
    return NAVBAR_MODE_PAGES_HISTORY;
}

-(NSString *)title
{
    return MWLocalizedString(@"history-label", nil);
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Top menu

// Handle nav bar taps. (same way as any other view controller would)
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_X:
        case NAVBAR_LABEL:
            [self popModal];

            break;
        case NAVBAR_BUTTON_TRASH:
            [self showDeleteAllDialog];
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - View lifecycle

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"NavItemTapped"
                                                  object: nil];
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
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    [self.dateFormatter setTimeZone:[NSTimeZone localTimeZone]];

    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.historyDataArray = [[NSMutableArray alloc] init];
    
    [self getHistoryData];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
    self.tableView.tableHeaderView = headerView;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    // Register the history results cell for reuse
    [self.tableView registerNib:[UINib nibWithNibName:@"HistoryResultPrototypeView" bundle:nil] forCellReuseIdentifier:@"HistoryResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setEmptyOverlayAndTrashIconVisibility];
}

#pragma mark - History data

-(void)getHistoryData
{
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"History"
                                              inManagedObjectContext: articleDataContext_.mainContext];
    [fetchRequest setEntity:entity];
    
    // For now fetch all history records - history entries older than 30 days will
    // be placed into "garbage" array below and removed.
    //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dateVisited > %@", [[NSDate date] dateBySubtractingDays:30]]];

    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:NO selector:nil];

    [fetchRequest setSortDescriptors:@[dateSort]];

    NSMutableArray *today = [@[] mutableCopy];
    NSMutableArray *yesterday = [@[] mutableCopy];
    NSMutableArray *lastWeek = [@[] mutableCopy];
    NSMutableArray *lastMonth = [@[] mutableCopy];
    NSMutableArray *garbage = [@[] mutableCopy];

    error = nil;
    NSArray *historyEntities = [articleDataContext_.mainContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch.");
    for (History *history in historyEntities) {
        /*
        NSLog(@"HISTORY:\n\t\
            article: %@\n\t\
            site: %@\n\t\
            domain: %@\n\t\
            date: %@\n\t\
            method: %@\n\t\
            image: %@",
            history.article.title,
            history.article.site,
            history.article.domain,
            history.dateVisited,
            history.discoveryMethod,
            history.article.thumbnailImage.fileName
        );
        */
        if ([history.dateVisited isToday]) {
            [today addObject:history.objectID];
        }else if ([history.dateVisited isYesterday]) {
            [yesterday addObject:history.objectID];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:7]]) {
            [lastWeek addObject:history.objectID];
        }else if ([history.dateVisited isLaterThanDate:[[NSDate date] dateBySubtractingDays:30]]) {
            [lastMonth addObject:history.objectID];
        }else{
            // Older than 30 days == Garbage! Remove!
            [garbage addObject:history.objectID];
        }
    }
    
    [self removeGarbage:garbage];

    if (today.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": today,
                                            @"sectionTitle": MWLocalizedString(@"history-section-today", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForToday]
                                            }
                                          mutableCopy]];
    if (yesterday.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": yesterday,
                                            @"sectionTitle": MWLocalizedString(@"history-section-yesterday", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForYesterday]
                                            }
                                          mutableCopy]];
    if (lastWeek.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": lastWeek,
                                            @"sectionTitle": MWLocalizedString(@"history-section-lastweek", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForLastWeek]
                                            }
                                          mutableCopy]];
    if (lastMonth.count > 0)
        [self.historyDataArray addObject:[@{
                                            @"data": lastMonth,
                                            @"sectionTitle": MWLocalizedString(@"history-section-lastmonth", nil),
                                            @"sectionDateString": [self getHistorySectionTitleForLastMonth]
                                            }
                                          mutableCopy]];
}

#pragma mark - History garbage removal

-(void) removeGarbage:(NSMutableArray *)garbage
{
    //NSLog(@"GARBAGE COUNT = %lu", (unsigned long)garbage.count);
    //NSLog(@"GARBAGE = %@", garbage);
    if (garbage.count == 0) return;

    [articleDataContext_.mainContext performBlockAndWait:^(){
        for (NSManagedObjectID *historyID in garbage) {
            History *history = (History *)[articleDataContext_.mainContext objectWithID:historyID];

            NSManagedObject *objectToDelete = [self objectToDeleteForHistoryItem:history];
            [articleDataContext_.mainContext deleteObject:objectToDelete];

        }
        NSError *error = nil;
        [articleDataContext_.mainContext save:&error];
        if (error) NSLog(@"GARBAGE error = %@", error);

    }];

    // Remove any orphaned images.
    CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    [imageHousekeeping performHouseKeeping];
    
    [NAV loadTodaysArticleIfNoCoreDataForCurrentArticle];
}

#pragma mark - History section titles

-(NSString *)getHistorySectionTitleForToday
{
    [self.dateFormatter setDateFormat:@"MMMM dd yyyy"];
    return [self.dateFormatter stringFromDate:[NSDate date]];
}

-(NSString *)getHistorySectionTitleForYesterday
{
    [self.dateFormatter setDateFormat:@"MMMM dd yyyy"];
    return [self.dateFormatter stringFromDate:[NSDate dateYesterday]];
}

-(NSString *)getHistorySectionTitleForLastWeek
{
    // Couldn't use just a single month name because 7 days ago could spans 2 months.
    [self.dateFormatter setDateFormat:@"%@ - %@"];
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    [self.dateFormatter setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:7]];
    NSString *d2 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:2]];
    return [NSString stringWithFormat:dateString, d1, d2];
}

-(NSString *)getHistorySectionTitleForLastMonth
{
    // Couldn't use just a single month name because 30 days ago probably spans 2 months.
    /*
     [self.dateFormatter setDateFormat:@"MMMM yyyy"];
     return [self.dateFormatter stringFromDate:[NSDate date]];
     */
    [self.dateFormatter setDateFormat:@"%@ - %@"];
    NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
    [self.dateFormatter setDateFormat:@"MMM dd yyyy"];
    NSString *d1 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:30]];
    NSString *d2 = [self.dateFormatter stringFromDate:[NSDate dateWithDaysBeforeNow:8]];
    return [NSString stringWithFormat:dateString, d1, d2];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.historyDataArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //Number of rows it should expect should be based on the section
    NSDictionary *dict = self.historyDataArray[section];
    NSArray *array = [dict objectForKey:@"data"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"HistoryResultCell";
    HistoryResultCell *cell = (HistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *dict = self.historyDataArray[indexPath.section];
    NSArray *array = [dict objectForKey:@"data"];
    
    __block History *historyEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)array[indexPath.row];
        historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
    }];
    
    NSString *title = [historyEntry.article.title wikiTitleWithoutUnderscores];
    NSString *language = [NSString stringWithFormat:@"\n%@", historyEntry.article.domainName];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = [WikipediaAppUtils rtlSafeAlignment];

    NSMutableAttributedString *(^styleText)(NSString *, CGFloat, UIColor *) = ^NSMutableAttributedString *(NSString *str, CGFloat size, UIColor *color){
        return [[NSMutableAttributedString alloc] initWithString:str attributes: @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:size * (1.0f / ICON_PERCENT_OF_CHROME_MENUS_HEIGHT)],
            NSParagraphStyleAttributeName : paragraphStyle,
            NSForegroundColorAttributeName : color,
        }];
    };

    NSMutableAttributedString *attributedTitle = styleText(title, 15, HISTORY_TEXT_COLOR);
    NSMutableAttributedString *attributedLanguage = styleText(language, 8, HISTORY_LANGUAGE_COLOR);
    
    [attributedTitle appendAttributedString:attributedLanguage];
    cell.textLabel.attributedText = attributedTitle;

    ArticleDiscoveryMethod discoveryMethod = [NAV getDiscoveryMethodForString:historyEntry.discoveryMethod];
    cell.methodLabel.attributedText = [self getIconLabelAttributedStringForDiscoveryMethod:discoveryMethod];

    UIImage *thumbImage = [historyEntry.article getThumbnailUsingContext:articleDataContext_.mainContext];
    if(thumbImage){
        cell.imageView.image = thumbImage;
        cell.useField = YES;
        return cell;
    }

    // If execution reaches this point a cached core data thumb was not found.

    // Set thumbnail placeholder
//TODO: don't load thumb from file every time in loop if no image found. fix here and in search
    cell.imageView.image = [UIImage imageNamed:@"logo-placeholder-search.png"];
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
    NSDictionary *dict = self.historyDataArray[indexPath.section];
    NSArray *array = dict[@"data"];
    selectedCell = array[indexPath.row];
    
    __block History *historyEntry = nil;
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)array[indexPath.row];
        historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
    }];

    [NAV loadArticleWithTitle: historyEntry.article.titleObj
                       domain: historyEntry.article.domain
                     animated: YES
              discoveryMethod: DISCOVERY_METHOD_SEARCH
            invalidatingCache: NO
                   popToWebVC: NO];

    [self popModalToRoot];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HISTORY_RESULT_HEIGHT;
}

#pragma mark - Table headers

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = self.historyDataArray[section];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = HISTORY_DATE_HEADER_BACKGROUND_COLOR;
    view.autoresizesSubviews = YES;
    PaddedLabel *label = [[PaddedLabel alloc] init];

    CGFloat leadingIndent = HISTORY_DATE_HEADER_LEFT_PADDING;
    label.padding = UIEdgeInsetsMake(0, leadingIndent, 0, 0);

    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];

    NSString *title = dict[@"sectionTitle"];
    NSString *dateString = dict[@"sectionDateString"];

    label.attributedText = [self getAttributedHeaderForTitle:title dateString:dateString];

    [view addSubview:label];

    return view;
}

-(NSAttributedString *)getAttributedHeaderForTitle:(NSString *)title dateString:(NSString *)dateString
{
    NSString *header = [NSString stringWithFormat:@"%@ %@", title, dateString];
    NSMutableAttributedString *attributedHeader = [[NSMutableAttributedString alloc] initWithString: header];
    
    NSRange rangeOfTitle = NSMakeRange(0, title.length);
    NSRange rangeOfDateString = NSMakeRange(title.length + 1, dateString.length);
    
    [attributedHeader addAttributes:@{
                                      NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0 * (1.0f / ICON_PERCENT_OF_CHROME_MENUS_HEIGHT)],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfTitle];
    
    [attributedHeader addAttributes:@{
                                      NSFontAttributeName : [UIFont systemFontOfSize:12.0 * (1.0f / ICON_PERCENT_OF_CHROME_MENUS_HEIGHT)],
                                      NSForegroundColorAttributeName : HISTORY_DATE_HEADER_TEXT_COLOR
                                      } range:rangeOfDateString];
    return attributedHeader;
}

#pragma mark - Delete

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        self.tableView.editing = NO;
        [self performSelector:@selector(deleteHistoryForIndexPath:) withObject:indexPath afterDelay:0.15f];
    }
}

-(void)deleteHistoryForIndexPath:(NSIndexPath *)indexPath
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        NSManagedObjectID *historyEntryId = (NSManagedObjectID *)self.historyDataArray[indexPath.section][@"data"][indexPath.row];
        History *historyEntry = (History *)[articleDataContext_.mainContext objectWithID:historyEntryId];
        if (historyEntry) {
            
            [self.tableView beginUpdates];

            NSUInteger itemsInSection = [(NSArray *)self.historyDataArray[indexPath.section][@"data"] count];
            
            if (itemsInSection == 1) {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            NSError *error = nil;

            NSManagedObject *objectToDelete = [self objectToDeleteForHistoryItem:historyEntry];
            [articleDataContext_.mainContext deleteObject:objectToDelete];
            [articleDataContext_.mainContext save:&error];
            
            if (itemsInSection == 1) {
                [self.historyDataArray removeObjectAtIndex:indexPath.section];
            }else{
                [self.historyDataArray[indexPath.section][@"data"] removeObject:historyEntryId];
            }
            
            [self.tableView endUpdates];
            
            [self setEmptyOverlayAndTrashIconVisibility];
        }
    }];

    // Remove any orphaned images.
    CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    [imageHousekeeping performHouseKeeping];
    
    [NAV loadTodaysArticleIfNoCoreDataForCurrentArticle];
}

#pragma mark - Discovery method icons

-(NSAttributedString *)getIconLabelAttributedStringForDiscoveryMethod:(ArticleDiscoveryMethod)discoveryMethod
{
    NSString *wikiFontCharacter = nil;;
    switch (discoveryMethod) {
        case DISCOVERY_METHOD_RANDOM:
            wikiFontCharacter = WIKIGLYPH_DICE;
            break;
        case DISCOVERY_METHOD_LINK:
            wikiFontCharacter = WIKIGLYPH_LINK;
            break;
        default:
            wikiFontCharacter = WIKIGLYPH_MAGNIFYING_GLASS;
            break;
    }
    
    UIColor *iconColor = [UIColor lightGrayColor];
    CGFloat fontSize = 20.0f * (1.0f / ICON_PERCENT_OF_CHROME_MENUS_HEIGHT);
    NSDictionary *attributes =
        @{
            NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:fontSize],
            NSForegroundColorAttributeName : iconColor,
            NSBaselineOffsetAttributeName: @0
        };
    
    return [[NSAttributedString alloc] initWithString: wikiFontCharacter
                                           attributes: attributes];
}

-(void)deleteAllHistoryItems
{
    [articleDataContext_.mainContext performBlockAndWait:^(){
        
        // Delete all entites - from: http://stackoverflow.com/a/1383645
        NSFetchRequest * historyFetch = [[NSFetchRequest alloc] init];
        [historyFetch setEntity:[NSEntityDescription entityForName:@"History" inManagedObjectContext:articleDataContext_.mainContext]];

        //[historyFetch setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError *error = nil;
        NSArray *historyRecords =
            [articleDataContext_.mainContext executeFetchRequest:historyFetch error:&error];

        for (History *historyRecord in historyRecords) {
            NSManagedObject *objectToDelete = [self objectToDeleteForHistoryItem:historyRecord];
            [articleDataContext_.mainContext deleteObject:objectToDelete];
        }
        NSError *saveError = nil;
        [articleDataContext_.mainContext save:&saveError];
        
    }];

    // Remove any orphaned images.
    CoreDataHousekeeping *imageHousekeeping = [[CoreDataHousekeeping alloc] init];
    [imageHousekeeping performHouseKeeping];
    
    [self.historyDataArray removeAllObjects];
    [self.tableView reloadData];
    
    [self setEmptyOverlayAndTrashIconVisibility];
        
    [NAV loadTodaysArticleIfNoCoreDataForCurrentArticle];
}

-(NSManagedObject *)objectToDeleteForHistoryItem:(History *)history
{
    // If there's a saved page record, just delete the history record, so the
    // saved page data isn't disturbed. If the page isn't saved it's safe to
    // delete the article (which will cascade to delete the history record too).
    return (history.article.saved.count > 0) ? history : history.article;
}

-(void)setEmptyOverlayAndTrashIconVisibility
{
    BOOL historyItemFound = ([self.historyDataArray count] > 0);
    
    self.emptyOverlay.hidden = historyItemFound;

    MenuButton *trashButton = (MenuButton *)[self.topMenuViewController getNavBarItem:NAVBAR_BUTTON_TRASH];
    trashButton.alpha = historyItemFound ? 1.0 : 0.0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteAllHistoryItems];
    }
}

-(void)showDeleteAllDialog
{
    UIAlertView *dialog =
    [[UIAlertView alloc] initWithTitle: MWLocalizedString(@"history-clear-confirmation-heading", nil)
                               message: MWLocalizedString(@"history-clear-confirmation-sub-heading", nil)
                              delegate: self
                     cancelButtonTitle: MWLocalizedString(@"history-clear-cancel", nil)
                     otherButtonTitles: MWLocalizedString(@"history-clear-delete-all", nil), nil];
    [dialog show];
}

@end
