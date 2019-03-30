//
//  UIView+HeeeQuickFrame.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HeeeQuickFrame)
@property (nonatomic) CGFloat heee_left;
@property (nonatomic) CGFloat heee_top;
@property (nonatomic) CGFloat heee_right;
@property (nonatomic) CGFloat heee_bottom;
@property (nonatomic) CGFloat heee_width;
@property (nonatomic) CGFloat heee_height;
@property (nonatomic) CGPoint heee_origin;
@property (nonatomic) CGSize  heee_size;
@property (nonatomic) CGFloat heee_centerX;
@property (nonatomic) CGPoint heee_topRight;
@property (nonatomic) CGPoint heee_bottomLeft;
@property (nonatomic) CGPoint heee_bottomRight;
@property (nonatomic) CGFloat heee_centerY;
@property (nonatomic) CGFloat heee_rightToSuper;
@property (nonatomic) CGFloat heee_bottomToSuper;

@end
