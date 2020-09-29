//
//  HeeePictureTakerAnimateButton.m
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#define H_buttonWidth 72.0
#define H_lineWidth 4.0
#define H_gap 2.5
#define H_noStartWidth (H_buttonWidth - 2*H_lineWidth - 2*H_gap)
#define H_startWidth H_noStartWidth/2
#define H_startCornerRadius 6

#import "HeeePictureTakerAnimateButton.h"

@interface HeeePictureTakerAnimateButton ()
@property (nonatomic,strong) UIView *centerAnimateView;
@property (nonatomic,strong) NSTimer *longPressTimer;
@property (nonatomic,assign) BOOL isStart;
@property (nonatomic,assign) BOOL pictureMode;
@property (nonatomic,assign) BOOL longPressMode;

@end

@implementation HeeePictureTakerAnimateButton
- (instancetype)initWithPictureMode:(BOOL)pictureMode {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, H_buttonWidth, H_buttonWidth);
        _pictureMode = pictureMode;
        
        _centerAnimateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, H_noStartWidth, H_noStartWidth)];
        _centerAnimateView.userInteractionEnabled = NO;
        _centerAnimateView.layer.cornerRadius = H_noStartWidth/2;
        _centerAnimateView.backgroundColor = _pictureMode?[UIColor whiteColor]:[UIColor colorWithRed:242/255.0 green:54/255.0 blue:58/255.0 alpha:1.0];
        _centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
        [self addSubview:_centerAnimateView];
        
        if (!_pictureMode) {
            [self addTarget:self action:@selector(startAnimation) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    return self;
}

- (void)reset {
    _centerAnimateView.frame = CGRectMake(0, 0, H_noStartWidth, H_noStartWidth);
    _centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
    _centerAnimateView.backgroundColor = _pictureMode?[UIColor whiteColor]:[UIColor colorWithRed:242/255.0 green:54/255.0 blue:58/255.0 alpha:1.0];
    _centerAnimateView.layer.cornerRadius = H_noStartWidth/2;
    _isStart = NO;
    if (_longPressTimer) {
        [_longPressTimer invalidate];
        _longPressTimer = nil;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_pictureMode) {
        if (highlighted) {
            if (_longPressTimer == nil) {
                _longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(longPressAction) userInfo:nil repeats:NO];
            }
            
            [UIView animateWithDuration:0.1 animations:^{
                self.centerAnimateView.frame = CGRectMake(0, 0, H_noStartWidth*0.95, H_noStartWidth*0.95);
                self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
                self.centerAnimateView.layer.cornerRadius = H_noStartWidth*0.95/2;
                self.centerAnimateView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            }];
        }else{
            if (_longPressTimer) {
                [_longPressTimer invalidate];
                _longPressTimer = nil;
            }
            
            if (_longPressMode && _longPressEnd) {
                _longPressMode = NO;
                _longPressEnd();
            }
            
            [UIView animateWithDuration:0.1 animations:^{
                self.centerAnimateView.frame = CGRectMake(0, 0, H_noStartWidth, H_noStartWidth);
                self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
                self.centerAnimateView.layer.cornerRadius = H_noStartWidth/2;
                self.centerAnimateView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
            }];
        }
    }else{
        CGFloat offset = highlighted?1:0;
        
        if (_isStart) {
            [UIView animateWithDuration:0.25 animations:^{
                self.centerAnimateView.layer.cornerRadius = H_startCornerRadius - offset;
                self.centerAnimateView.frame = CGRectMake(self.centerAnimateView.frame.origin.x, self.centerAnimateView.frame.origin.y, H_startWidth - 2*offset, H_startWidth - 2*offset);
                self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
            }];
        }else{
            [UIView animateWithDuration:0.25 animations:^{
                self.centerAnimateView.layer.cornerRadius = H_noStartWidth/2 - 2*offset;
                self.centerAnimateView.frame = CGRectMake(self.centerAnimateView.frame.origin.x, self.centerAnimateView.frame.origin.y, H_noStartWidth - 4*offset, H_noStartWidth - 4*offset);
                self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
            }];
        }
    }
}

- (void)longPressAction {
    if (_longPressStart) {
        _longPressMode = YES;
        _longPressStart();
    }
}

- (void)startAnimation {
    _isStart = !_isStart;
    
    CGFloat duration = 0;
    if (@available(iOS 11.0,*)) {
        duration = 0.25;
    }
    
    if (_isStart) {
        [UIView animateWithDuration:duration animations:^{
            self.centerAnimateView.layer.cornerRadius = 5;
            self.centerAnimateView.frame = CGRectMake(self.centerAnimateView.frame.origin.x, self.centerAnimateView.frame.origin.y, H_startWidth, H_startWidth);
            self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
        }];
    }else{
        [UIView animateWithDuration:duration animations:^{
            self.centerAnimateView.layer.cornerRadius = H_noStartWidth/2;
            self.centerAnimateView.frame = CGRectMake(self.centerAnimateView.frame.origin.x, self.centerAnimateView.frame.origin.y, H_noStartWidth, H_noStartWidth);
            self.centerAnimateView.center = CGPointMake(H_buttonWidth/2, H_buttonWidth/2);
        }];
    }
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(H_lineWidth/2, H_lineWidth/2, H_buttonWidth - H_lineWidth, H_buttonWidth - H_lineWidth)];
    [[UIColor whiteColor] setStroke];
    [path setLineWidth:H_lineWidth];
    [path stroke];
}

@end
