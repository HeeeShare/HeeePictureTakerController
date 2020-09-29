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
    
    UIView *maskView = [[UIView alloc] init];
    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    maskView.layer.cornerRadius = 8;
    maskView.layer.masksToBounds = YES;
    [clearBackView addSubview:maskView];
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    [maskView addSubview:blurView];
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicatorView startAnimating];
    [maskView addSubview:indicatorView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 80, 20)];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textColor = [UIColor whiteColor];
    [maskView addSubview:label];
    
    if (title.length > 0) {
        maskView.width = 100;
        label.text = title;
        indicatorView.top = 15;
        indicatorView.centerX = maskView.width/2;
        label.top = indicatorView.bottom + 15;
        maskView.height = label.bottom + 15;
    }else{
        maskView.width = 64;
        maskView.height = 64;
        indicatorView.center = CGPointMake(maskView.width/2, maskView.height/2);
    }
    
    maskView.center = CGPointMake(self.width/2, self.height/2);
    blurView.frame = maskView.bounds;
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
