//
//  ViewController.m
//  LAutomaticLinkDemo
//
//  Created by 梁海军 on 2016/12/15.
//  Copyright © 2016年 lhj. All rights reserved.
//

#import "ViewController.h"

#import "LAutoLabel.h"
@interface ViewController ()<LAutoLabelDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    LAutoLabel *label = [[LAutoLabel alloc] initWithFrame:CGRectMake(10, 100, 394, 300)];
    label.numberOfLines = 0;
    label.delegate = self;
    label.lineBreakMode=NSLineBreakByCharWrapping;
    label.text = @"这是使用\0@UITextView\0时用到的iOS7新增加的类：\0@NSTextContainer\0、\0@NSLayoutManager\0、\0@NSTextStorage\0及其相互关系：";
    [label sizeToFit];
    [self.view addSubview:label];
}

-(void)autolabel:(LAutoLabel *)label userHandleString:(NSString *)string range:(NSRange)range{
    NSLog(@"userHandleString:%@,rang:%@",string,NSStringFromRange(range));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
