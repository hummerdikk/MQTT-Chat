//
//  ChatViewController.m
//  MQTT-Chat
//
//  Created by Kertész Tibor on 10/09/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "ChatViewController.h"
#import "Message.h"
#import "MessageTableViewCell.h"
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>

static NSString *MessengerCellIdentifier = @"MessengerCell";

@interface ChatViewController ()<MQTTSessionManagerDelegate>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong,nonatomic) MQTTSessionManager *mqttManager;
@property(strong,nonatomic) NSString *userid;

- (void)disconnectMqtt;

@end

@implementation ChatViewController


#pragma mark - Initializer

- (id)init {
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}


// Uncomment if you are using Storyboard.
// You don't need to call initWithCoder: anymore
+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder {
    return UITableViewStylePlain;
}



#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userid = [[NSUUID UUID] UUIDString];
    
    self.messages = [[NSMutableArray alloc]init];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:MessengerCellIdentifier];
    
    // MQTT setup
    if (self.mqttManager == nil) {
        
        self.mqttManager = [[MQTTSessionManager alloc] init];
        self.mqttManager.delegate = self;
        self.mqttManager.subscriptions = [[NSMutableDictionary alloc] init];
        
        self.mqttManager.subscriptions[self.topicPath] = @(MQTTQosLevelAtMostOnce);
        
        [self.mqttManager connectTo:@"fds-node1.cloudapp.net"
                               port:1883
                                tls:NO
                          keepalive:60
                              clean:YES
                               auth:NO
                               user:nil
                               pass:nil
                               will:NO
                          willTopic:nil
                            willMsg:nil
                            willQos:MQTTQosLevelAtMostOnce
                     willRetainFlag:NO
                       withClientId:self.userid];
    } else {
        //else we can reconnect to the last mqtt server
        [self.mqttManager connectToLast];
    }
    
    [self.mqttManager addObserver:self
                       forKeyPath:@"state"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:nil];
}


#pragma mark - SLKTextViewController Events

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status {
    // Notifies the view controller that the keyboard changed status.
    // Calling super does nothing
}

- (void)textWillUpdate {
    // Notifies the view controller that the text will update.
    // Calling super does nothing
    
    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated {
    // Notifies the view controller that the text did update.
    // Must call super
    
    [super textDidUpdate:animated];
}

- (BOOL)canPressRightButton {
    // Asks if the right button can be pressed
    
    return [super canPressRightButton];
}

- (void)didPressRightButton:(id)sender {
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    // Must call super
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    //Send here the message to the MQTT Broker and that's it.
    
    NSDictionary *newmessageJson = @{
                                @"userid" : self.userid,
                                @"username" : self.username,
                                @"message" : self.textView.text,
                                };
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:newmessageJson
                                                       options:0
                                                         error:&jsonError];
    [self.mqttManager sendData:jsonData
                         topic:self.topicPath
                           qos:MQTTQosLevelExactlyOnce
                        retain:NO];
    
    
    [super didPressRightButton:sender];
}


#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        return [self messageCellForRowAtIndexPath:indexPath];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Returns the number of rows in the section.
    
    if ([tableView isEqual:self.tableView]) {
        return self.messages.count;
    }
    
    return 0;
}

- (MessageTableViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MessengerCellIdentifier];
    
    Message *message = self.messages[indexPath.row];
    
    cell.titleLabel.text = message.username;
    cell.bodyLabel.text = message.text;
    
    
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        Message *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        CGFloat pointSize = [MessageTableViewCell defaultFontSize];
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:pointSize],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame);
        width -= 25.0;
        
        CGRect titleBounds = [message.username boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.text.length == 0) {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 40.0;
        
        if (height < kMessageTableViewCellMinimumHeight) {
            height = kMessageTableViewCellMinimumHeight;
        }
        
        return height;
    }
    else {
        return kMessageTableViewCellMinimumHeight;
    }
}

#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Navigation controll

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //Whatever seque is preparing, close MQTT connection!!!
    [self disconnectMqtt];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //needs more check
    [self disconnectMqtt];
}

#pragma mark - MQTT related codes

//Handle the incomming message
//TODO: JSON!
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"%@",dataString);
    
    NSError *jsonError;
    NSDictionary *incomMessage = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&jsonError];
    if(incomMessage){
    
        Message *message = [Message new];
        message.username = incomMessage[@"username"];
        message.text = incomMessage[@"message"];
    
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
        UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
        [self.tableView beginUpdates];
        [self.messages insertObject:message atIndex:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
        [self.tableView endUpdates];
    
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSLog(@"ERROR with incomMessage");
    }
    
}

//Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    switch (self.mqttManager.state) {
        case MQTTSessionManagerStateClosed: {
            NSLog(@"MQTT: Connection closed");
            break;
        }
        case MQTTSessionManagerStateClosing: {
            NSLog(@"MQTT: Connection closing");
            break;
        }
        case MQTTSessionManagerStateConnected: {
            NSLog(@"MQTT: Connected");
            break;
        }
        case MQTTSessionManagerStateConnecting: {
            NSLog(@"MQTT: Connection connecting");
            break;
        }
        case MQTTSessionManagerStateError: {
            NSLog(@"MQTT: Error");
            break;
        }
        case MQTTSessionManagerStateStarting:{
            NSLog(@"MQTT: Connection starting");
            break;
        }
        default: {
            NSLog(@"MQTT: Not connected");
            break;
        }
    }
}

- (void)disconnectMqtt{
    [self.mqttManager removeObserver:self forKeyPath:@"state"];
    [self.mqttManager disconnect];
}

@end
