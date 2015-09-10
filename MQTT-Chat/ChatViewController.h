//
//  ChatViewController.h
//  MQTT-Chat
//
//  Created by Kertész Tibor on 10/09/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "SLKTextViewController.h"

@interface ChatViewController : SLKTextViewController

@property (strong,nonatomic) NSString *username;
@property (strong,nonatomic) NSString *topicPath;

@end
