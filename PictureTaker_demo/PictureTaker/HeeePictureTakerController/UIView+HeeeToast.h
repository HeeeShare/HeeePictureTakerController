//
//  UIView+HeeeToast.h
//  PictureTaker
//
//  Created by hgy on 2018/8/15.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HeeeToast)
- (void)showToast:(NSString *)content duration:(CGFloat)duration;//@"center"
- (void)showToast:(NSString *)content duration:(CGFloat)duration andPosition:(NSString *)position;//position -> @"top" , @"center" , @"bottom"

@end
