//
//  MessageTableViewCell.h
//  MQTT-Chat
//
// From Slack
//
//  Created by Kertész Tibor on 10/09/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat kMessageTableViewCellMinimumHeight = 50.0;

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic) BOOL usedForMessage;

+ (CGFloat)defaultFontSize;

@end
