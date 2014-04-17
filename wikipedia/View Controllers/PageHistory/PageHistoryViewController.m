//  Created by Monte Hurd on 12/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryViewController.h"
#import "PageHistoryTableHeadingLabel.h"
#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "QueuesSingleton.h"
#import "NavController.h"
#import "PageHistoryOp.h"

#import "UINavigationController+SearchNavStack.h"
#import "NSString+FormattedAttributedString.h"
#import "UIViewController+Alert.h"
#import "NSDate-Utilities.h"
#import "NSString+Extras.h"

#define NAV ((NavController *)self.navigationController)

#define SAVED_PAGES_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.1f alpha:1.0f]

@interface PageHistoryViewController (){

}

@property (strong, nonatomic) __block NSMutableArray *pageHistoryDataArray;

@end

@implementation PageHistoryViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self getPageHistoryData];
}

-(PageHistoryTableHeadingLabel *)getHeadingLabel
{
    PageHistoryTableHeadingLabel *pageHistoryLabel =
        [[PageHistoryTableHeadingLabel alloc] initWithFrame:CGRectMake(0, 0, 10, 95)];
    
    NSMutableParagraphStyle *headingParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [headingParagraphStyle setLineSpacing:14];
    [headingParagraphStyle setParagraphSpacing:0];
    
    NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    [titleParagraphStyle setParagraphSpacing:0];
    
    NSAttributedString *pageHistoryTitle =
    [@"$1\n$2" attributedStringWithAttributes: nil
                          substitutionStrings: @[
                                                 MWLocalizedString(@"page-history-title", nil),
                                                 [SessionSingleton sharedInstance].currentArticleTitle
                                                 ]
                       substitutionAttributes: @[
                                                 @{
                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:20],
                                                     NSParagraphStyleAttributeName: headingParagraphStyle
                                                     },
                                                 @{
                                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                                     NSParagraphStyleAttributeName: titleParagraphStyle
                                                     }
                                                 ]
     ];
    pageHistoryLabel.attributedText = pageHistoryTitle;
    pageHistoryLabel.numberOfLines = 0;
    pageHistoryLabel.textAlignment = NSTextAlignmentCenter;
    pageHistoryLabel.textColor = SAVED_PAGES_TITLE_TEXT_COLOR;
    pageHistoryLabel.backgroundColor = [UIColor whiteColor];

    return pageHistoryLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.hidesBackButton = YES;

    self.pageHistoryDataArray = @[].mutableCopy;

    self.tableView.tableHeaderView = [self getHeadingLabel];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName: @"PageHistoryResultPrototypeView" bundle: nil]
         forCellReuseIdentifier: @"PageHistoryResultCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void)getPageHistoryData
{
    [[QueuesSingleton sharedInstance].pageHistoryQ cancelAllOperations];
    
    __weak PageHistoryViewController *weakSelf = self;
    
    PageHistoryOp *pageHistoryOp =
    [[PageHistoryOp alloc] initWithDomain: [SessionSingleton sharedInstance].currentArticleDomain
                                    title: [SessionSingleton sharedInstance].currentArticleTitle
                          completionBlock: ^(NSMutableArray * result){
                              
                              weakSelf.pageHistoryDataArray = result;
                              
                              dispatch_async(dispatch_get_main_queue(), ^(void){
                                  [weakSelf.tableView reloadData];
                              });
                          }
                           cancelledBlock: ^(NSError *error){
                               [self showAlert:error.localizedDescription];
                           }
                               errorBlock: ^(NSError *error){
                                   [self showAlert:error.localizedDescription];
                               }];
    pageHistoryOp.delegate = self;
    [[QueuesSingleton sharedInstance].pageHistoryQ addOperation:pageHistoryOp];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.pageHistoryDataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionDict = self.pageHistoryDataArray[section];
    NSArray *rows = sectionDict[@"revisions"];
    return rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"PageHistoryResultCell";
    PageHistoryResultCell *cell = (PageHistoryResultCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSDictionary *sectionDict = self.pageHistoryDataArray[indexPath.section];
    NSArray *rows = sectionDict[@"revisions"];
    NSDictionary *row = rows[indexPath.row];
    
    cell.separatorHeightConstraint.constant =
        (rows.count == 1) ? 0.0f : (1.0f / [UIScreen mainScreen].scale);

    NSDate *timeStamp = [row[@"timestamp"] getDateFromIso8601DateString];
    
    NSString *formattedTime =
        [NSDateFormatter localizedStringFromDate: timeStamp
                                       dateStyle: NSDateFormatterNoStyle
                                       timeStyle: NSDateFormatterShortStyle];
    
    NSString *commentNoHTML = [row[@"parsedcomment"] getStringWithoutHTML];

    NSNumber *delta = row[@"characterDelta"];
    
    cell.summaryLabel.text = commentNoHTML;
    cell.timeLabel.text = formattedTime;

    cell.deltaLabel.text =
        [NSString stringWithFormat:@"%@%@", (delta.integerValue > 0) ? @"+" : @"", delta.stringValue];
    
    cell.deltaLabel.textColor =
        (delta.integerValue > 0)
        ?
        [UIColor colorWithRed:0.00 green:0.69 blue:0.49 alpha:1.0]
        :
        [UIColor colorWithRed:0.95 green:0.00 blue:0.00 alpha:1.0]
        ;

    cell.iconLabel.attributedText =
    [[NSAttributedString alloc] initWithString: row[@"anon"] ? @"" : @""
                                    attributes: @{
                                                  NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Regular" size:23],
                                                  NSForegroundColorAttributeName : [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0],
                                                  NSBaselineOffsetAttributeName: @1
                                                  }];
    
    cell.nameLabel.text = row[@"user"];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Getting dynamic cell height which respects auto layout constraints is tricky.

    // First get the cell configured exactly as it is for display.
    PageHistoryResultCell *cell =
        (PageHistoryResultCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionDict = self.pageHistoryDataArray[indexPath.section];
    NSArray *rows = sectionDict[@"revisions"];
    NSDictionary *row = rows[indexPath.row];
    NSLog(@"row = %@", row);
    
// TODO: row contains a revisionid, make tap cause diff for that revision to open in Safari?

}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
    view.autoresizesSubviews = YES;
    UILabel *label = [[UILabel alloc] initWithFrame:
                      CGRectMake(10, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height)
                      ];
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor darkGrayColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.backgroundColor = [UIColor clearColor];
    
    NSDictionary *sectionDict = self.pageHistoryDataArray[section];
    
    NSNumber *daysAgo = sectionDict[@"daysAgo"];
    NSDate *date = [NSDate dateWithDaysBeforeNow:daysAgo.integerValue];
    
    NSString *formattedDate = [NSDateFormatter localizedStringFromDate: date
                                                             dateStyle: NSDateFormatterLongStyle
                                                             timeStyle: NSDateFormatterNoStyle];
    
    label.text = formattedDate;
    
    [view addSubview:label];
    
    return view;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 27;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
