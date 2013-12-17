//  Created by Monte Hurd on 12/4/13.

#import "SavedPagesViewController.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "WebViewController.h"
#import "SavedPagesResultCell.h"
#import "SavedPagesTableHeadingLabel.h"
#import "Defines.h"

@interface SavedPagesViewController ()
{
    ArticleDataContextSingleton *articleDataContext_;
}

@property (strong, atomic) NSMutableArray *savedPagesDataArray;

@end

@implementation SavedPagesViewController

#pragma mark - Init

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    articleDataContext_ = [ArticleDataContextSingleton sharedInstance];

    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.savedPagesDataArray = [[NSMutableArray alloc] init];
    
    [self getSavedPagesData];

    SavedPagesTableHeadingLabel *savedPagesLabel = [[SavedPagesTableHeadingLabel alloc] initWithFrame:CGRectMake(0, 0, 10, 53)];
    savedPagesLabel.text = @"Saved Pages";
    savedPagesLabel.textAlignment = NSTextAlignmentCenter;
    savedPagesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    savedPagesLabel.textColor = SAVED_PAGES_TITLE_TEXT_COLOR;
    self.tableView.tableHeaderView = savedPagesLabel;
    savedPagesLabel.backgroundColor = [UIColor whiteColor];

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
        NSLog(@"SAVED:\n\t\
            article: %@\n\t\
            date: %@\n\t\
            image: %@",
            savedPage.article.title,
            savedPage.dateSaved,
            savedPage.article.thumbnailImage.fileName
        );
        [pages addObject:savedPage];
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
    
    Saved *savedEntry = (Saved *)array[indexPath.row];
    
    NSString *title = [savedEntry.article.title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
    cell.textLabel.text = title;
    cell.textLabel.textColor = SAVED_PAGES_TEXT_COLOR;
    
cell.methodImageView.image = nil;

    Image *thumbnailFromDB = savedEntry.article.thumbnailImage;
    if(thumbnailFromDB){
        UIImage *image = [UIImage imageWithData:thumbnailFromDB.data];
        cell.imageView.image = image;
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
    
    Saved *savedEntry = (Saved *)array[indexPath.row];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Set CurrentArticleTitle so the web view knows what to display for this selection.
    [[NSUserDefaults standardUserDefaults] setObject:savedEntry.article.title forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    WebViewController *webViewController = [self getWebViewController];
    [self.navigationController popToViewController:webViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SAVED_PAGES_RESULT_HEIGHT;
}

#pragma mark - Misc

-(WebViewController *)getWebViewController
{
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[WebViewController class]]) {
            return (WebViewController *)vc;
        }
    }
    return nil;
}

@end
