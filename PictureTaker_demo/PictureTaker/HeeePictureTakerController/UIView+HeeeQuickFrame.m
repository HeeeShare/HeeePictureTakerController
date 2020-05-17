//
//  UIView+HeeeQuickFrame.m
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "UIView+HeeeQuickFrame.h"

@implementation UIView (HeeeQuickFrame)

- (CGFloat)heee_left {
    return self.frame.origin.x;
}

- (void)setHeee_left:(CGFloat)heee_left {
    CGRect frame = self.frame;
    frame.origin.x = heee_left;
    self.frame = frame;
}

- (CGFloat)heee_top {
    return self.frame.origin.y;
}

- (void)setHeee_top:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)heee_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setHeee_right:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)heee_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setHeee_bottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)heee_width {
    return self.frame.size.width;
}

- (void)setHeee_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)heee_height {
    return self.frame.size.height;
}

- (void)setHeee_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGPoint)heee_origin {
    return self.frame.origin;
}

- (void)setHeee_origin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)heee_size {
    return self.frame.size;
}

- (CGFloat)heee_centerX {
    return self.center.x;
}

- (void)setHeee_centerX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)heee_centerY {
    return self.center.y;
}

- (void)setHeee_centerY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (void)setHeee_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGPoint)heee_topRight
{
    return CGPointMake(self.frame.origin.x+self.frame.size.width,self.frame.origin.y);
}

- (void)setHeee_topRight:(CGPoint)heee_topRight
{
    CGRect frame = self.frame;
    CGFloat xdetal = heee_topRight.x - frame.origin.x - frame.size.width;
    frame.origin.x = frame.origin.x + xdetal;
    frame.origin.y = heee_topRight.y;
    self.frame = frame;
}

- (CGPoint)heee_bottomLeft
{
    return CGPointMake(self.frame.origin.x,self.frame.origin.y+self.frame.size.height);
}

- (void)setHeee_bottomLeft:(CGPoint)heee_bottomLeft
{
    CGRect frame = self.frame;
    CGFloat ydetal = heee_bottomLeft.y - frame.origin.y - frame.size.height;
    frame.origin.y = frame.origin.y + ydetal;
    frame.origin.x = heee_bottomLeft.x;
    self.frame = frame;
}

- (CGPoint)heee_bottomRight
{
    return CGPointMake(self.frame.origin.x+self.frame.size.width,self.frame.origin.y+self.frame.size.height);
}

- (void)setHeee_bottomRight:(CGPoint)heee_bottomRight
{
    CGRect frame = self.frame;
    CGFloat xdetal = heee_bottomRight.x - frame.origin.x - frame.size.width;
    frame.origin.x = frame.origin.x + xdetal;
    CGFloat ydetal = heee_bottomRight.y - frame.origin.y - frame.size.height;
    frame.origin.y = frame.origin.y + ydetal;
    self.frame = frame;
}

- (CGFloat)heee_rightToSuper
{
    return self.superview.bounds.size.width - self.frame.size.width - self.frame.origin.x;
}

- (void)setHeee_rightToSuper:(CGFloat)rightToSuper
{
    CGRect frame = self.frame;
    frame.origin.x =  self.superview.bounds.size.width - self.frame.size.width  - rightToSuper;
    self.frame = frame;
}

- (CGFloat)heee_bottomToSuper
{
    return self.superview.bounds.size.height - self.frame.size.height - self.frame.origin.y;
}

- (void)setHeee_bottomToSuper:(CGFloat)bottomToSuper
{
    CGRect frame = self.frame;
    frame.origin.y =  self.superview.bounds.size.height - self.frame.size.height  - bottomToSuper;
    self.frame = frame;
}

@end
