//
//  UIView+HeeeToast.m
//  PictureTaker
//
//  Created by hgy on 2018/8/15.
//  Copyright © 2018年 hgy. All rights reserved.
//
#define toastViewTag 10077
#define HKStatusBarHeight ([UIApplication sharedApplication].statusBarFrame.size.height)
#define HKHomeIndecatorHeight ((HKStatusBarHeight==20) ? 0.0 : 44.0)

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
    
    CGFloat sizeGap = 24;
    CGFloat titleLeftGap = 20;
    CGFloat titleTopGap = 10;
    
    UIView *toastView = [[UIView alloc] init];
    toastView.tag = toastViewTag;
    toastView.userInteractionEnabled = NO;
    toastView.layer.zPosition = 1000;
    toastView.layer.masksToBounds = YES;
    toastView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    toastView.layer.cornerRadius = 4;
    [self addSubview:toastView];
    toastView.alpha = 0;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - 2*(sizeGap + titleLeftGap), 0)];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    label.textColor = [UIColor whiteColor];
    label.text = content;
    [label sizeToFit];
    label.frame = CGRectMake(titleLeftGap, titleTopGap, label.bounds.size.width, label.bounds.size.height);
    [toastView addSubview:label];
    
    CGFloat toastViewW = label.bounds.size.width + titleLeftGap*2;
    CGFloat toastViewH = label.bounds.size.height + titleTopGap*2;
    CGFloat toastViewX = (self.bounds.size.width - toastViewW)/2;
    CGFloat toastViewY = (self.bounds.size.height - toastViewH)/2;
    if ([position isEqualToString:@"top"]) {
        toastViewY = 12 + HKStatusBarHeight;
    }else if ([position isEqualToString:@"bottom"]) {
        toastViewY = self.bounds.size.height - toastViewH - 12 - HKHomeIndecatorHeight;
    }
    
    toastView.frame = CGRectMake(toastViewX, toastViewY, toastViewW, toastViewH);
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    effectView.frame = toastView.bounds;
    [toastView insertSubview:effectView belowSubview:label];
    
    toastView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    
    [UIView animateWithDuration:0.3 animations:^{
        toastView.alpha = 1.0;
        toastView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.15 animations:^{
                toastView.alpha = 0;
            } completion:^(BOOL finished) {
                [toastView removeFromSuperview];
            }];
        });
    }];
}

- (void)showToast:(NSString *)content duration:(CGFloat)duration {
    [self showToast:content duration:duration andPosition:@"center"];
}

@end
