//
//  ViewController.m
//  MQTT-Chat
//
//  Created by Kertész Tibor on 10/09/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "LoginViewController.h"
#import "ChatViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *topicTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"Login";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation controll

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[ChatViewController class]]) {
        ChatViewController * chatVC = segue.destinationViewController;
        chatVC.username = [self.usernameTextField.text copy];
        chatVC.topicPath = [self.topicTextField.text copy];
    }
    
    
}


@end
