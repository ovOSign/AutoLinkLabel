//
//  LAutoLickLabel.h
//  LAutomaticLinkDemo
//
//  Created by 梁海军 on 2016/12/16.
//  Copyright © 2016年 lhj. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger, LAutoLinkType){
    LAutoTypeUserHandle,

    LAutoTypeHashTag,

    LAutoTypeURL,
};

@protocol LAutoLabelDelegate;

@interface LAutoLabel : UILabel

@property(nonatomic, weak)id<LAutoLabelDelegate> delegate;

@end

@protocol LAutoLabelDelegate<NSObject>
@optional
-(void)autolabel:(LAutoLabel*)label userHandleString:(NSString*)string range:(NSRange)range;

-(void)autolabel:(LAutoLabel*)label hashTagString:(NSString*)string range:(NSRange)range;

-(void)autolabel:(LAutoLabel*)label urlTagString:(NSString*)string range:(NSRange)range;

@end
