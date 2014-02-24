//  Created by Monte Hurd on 2/19/14.

#import "CaptchaViewController.h"

@interface CaptchaViewController ()

@property (weak, nonatomic) IBOutlet UIButton *reloadCaptchaButton;

@end

@implementation CaptchaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    [self.reloadCaptchaButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
}

- (void)reloadCaptchaPushed:(id)sender
{
    if ([self.parentViewController respondsToSelector:@selector(reloadCaptchaPushed:)]) {
        [self.parentViewController performSelectorOnMainThread:@selector(reloadCaptchaPushed:) withObject:nil waitUntilDone:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.reloadCaptchaButton addTarget: self
                                 action: @selector(reloadCaptchaPushed:)
                       forControlEvents: UIControlEventTouchUpInside];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.reloadCaptchaButton removeTarget: nil
                                    action: NULL
                          forControlEvents: UIControlEventAllEvents];

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
