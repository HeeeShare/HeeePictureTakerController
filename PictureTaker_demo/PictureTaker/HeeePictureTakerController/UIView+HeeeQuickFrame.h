//
//  UIView+HeeeQuickFrame.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HeeeQuickFrame)
@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize  size;
@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGPoint topRight;
@property (nonatomic) CGPoint bottomLeft;
@property (nonatomic) CGPoint bottomRight;
@property (nonatomic) CGFloat centerY;
@property (nonatomic) CGFloat rightToSuper;
@property (nonatomic) CGFloat bottomToSuper;

@end
