//
//  UIView+HeeeToast.m
//  PictureTaker
//
//  Created by hgy on 2018/8/15.
//  Copyright © 2018年 hgy. All rights reserved.
//
#define toastViewTag 10077

#import "UIView+HeeeToast.h"
#import "UIView+HeeeQuickFrame.h"

@implementation UIView (HeeeToast)
- (void)showToast:(NSString *)content duration:(CGFloat)duration andPosition:(NSString *)position {
    if ([self viewWithTag:toastViewTag]) {
        [[self viewWithTag:toastViewTag] removeFromSuperview];
    }
    
    if (!content || content.length == 0) {
        content = @" ";
    }
    
    UIVisualEffectView *backView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    backView.userInteractionEnabled = NO;
    backView.layer.zPosition = 9999;
    backView.tag = toastViewTag;
    backView.layer.cornerRadius = 8;
    backView.layer.masksToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.heee_width - 40, 0)];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:18 weight:0.3];
    label.textColor = [UIColor whiteColor];
    label.text = content;
    [label sizeToFit];
    
    CGFloat lineSpace = 5;
    if (label.heee_height < 30) {
        lineSpace = 0;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setLineSpacing:lineSpace];//设置行间距
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [content length])];
    [label setAttributedText:attributedString];
    [label sizeToFit];
    
    [backView.contentView addSubview:label];
    backView.heee_width = fabs(label.heee_width + 20);
    backView.heee_height = fabs(label.heee_height + 20);
    label.center = CGPointMake(backView.heee_width/2, backView.heee_height/2);
    [self addSubview:backView];
    
    backView.transform = CGAffineTransformMakeScale(0.4, 0.4);
    
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:10 options:UIViewAnimationOptionCurveEaseOut animations:^{
        backView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        
    }];
    
    if ([position isEqualToString:@"top"]) {
        backView.heee_top = 20;
        backView.heee_centerX = self.heee_width/2;
    }else if ([position isEqualToString:@"bottom"]) {
        backView.heee_bottom = self.heee_height - 20;
        backView.heee_centerX = self.heee_width/2;
    }else{
        backView.center = CGPointMake(self.heee_width/2, self.heee_height/2);
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                backView.alpha = 0;
            } completion:^(BOOL finished) {
                if (finished) {
                    [backView removeFromSuperview];
                }
            }];
        });
    });
}

- (void)showToast:(NSString *)content duration:(CGFloat)duration {
    [self showToast:content duration:duration andPosition:@"center"];
}

@end
