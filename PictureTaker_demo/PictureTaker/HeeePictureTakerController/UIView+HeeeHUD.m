//
//  UIView+HeeeHUD.m
//  PictureTaker
//
//  Created by diipo on 2018/8/9.
//  Copyright © 2018年 hgy. All rights reserved.
//

#define clearBackViewTag 10078

#import "UIView+HeeeHUD.h"
#import "UIView+HeeeQuickFrame.h"

@implementation UIView (HeeeHUD)
- (void)showHUDWithTitle:(NSString *)title {
    if ([self viewWithTag:clearBackViewTag]) {
        [[self viewWithTag:clearBackViewTag] removeFromSuperview];
    }
    
    UIView *clearBackView = [[UIView alloc] initWithFrame:self.bounds];
    clearBackView.layer.zPosition = 9999;
    clearBackView.tag = clearBackViewTag;
    clearBackView.backgroundColor = [UIColor clearColor];
    [self addSubview:clearBackView];
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    effectView.layer.cornerRadius = 12;
    effectView.layer.masksToBounds = YES;
    [clearBackView addSubview:effectView];
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicatorView startAnimating];
    [effectView.contentView addSubview:indicatorView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 20)];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:16 weight:0.3];
    label.textColor = [UIColor whiteColor];
    [effectView.contentView addSubview:label];
    
    if (title.length > 0) {
        effectView.width = 120;
        label.text = title;
        indicatorView.top = 15;
        indicatorView.centerX = effectView.width/2;
        label.top = indicatorView.bottom + 15;
        effectView.height = label.bottom + 15;
    }else{
        effectView.width = 80;
        effectView.height = 80;
        indicatorView.center = CGPointMake(effectView.width/2, effectView.height/2);
    }
    
    effectView.center = CGPointMake(self.width/2, self.height/2);
}

- (void)hideHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *clearBackView = [self viewWithTag:clearBackViewTag];
        if (clearBackView) {
            [UIView animateWithDuration:0.25 animations:^{
                clearBackView.alpha = 0;
            } completion:^(BOOL finished) {
                if (finished) {
                    [clearBackView removeFromSuperview];
                }
            }];
        }
    });
}

@end
