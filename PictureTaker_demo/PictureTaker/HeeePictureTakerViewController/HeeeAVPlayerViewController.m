//
//  HeeeAVPlayerViewController.m
//  PictureTaker
//
//  Created by diipo on 2018/8/9.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "HeeeAVPlayerViewController.h"
#import <CoreVideo/CoreVideo.h>
#import "UIView+HeeeToast.h"

@interface HeeeAVPlayerViewController ()
@property (nonatomic,strong) UIVisualEffectView *backView;
@property (nonatomic,strong) UIVisualEffectView *saveBackView;
@property (nonatomic,strong) CADisplayLink *displayLink;
@property (nonatomic,assign) BOOL viewWillDisappear;

@end

@implementation HeeeAVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewWillDisappear = NO;
    
    if (!self.backView.superview) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(statusState)];
        _displayLink.paused = NO;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [self.view addSubview:self.backView];
        [self.view addSubview:self.saveBackView];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.backView.alpha = 1.0;
        self.saveBackView.alpha = 1.0;
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _viewWillDisappear = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_displayLink invalidate];
    _displayLink = nil;
}

- (UIVisualEffectView *)backView {
    if (!_backView) {
        _backView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)]];
        _backView.frame = CGRectMake(6, 80, 60, 47);
        _backView.alpha = 0;
        _backView.layer.cornerRadius = 14;
        _backView.clipsToBounds = YES;
        
        UIButton *selectButton = [[UIButton alloc] initWithFrame:_backView.bounds];
        selectButton.exclusiveTouch = YES;
        selectButton.backgroundColor = [UIColor clearColor];
        [selectButton addTarget:self action:@selector(select) forControlEvents:(UIControlEventTouchUpInside)];
        [selectButton setImage:[UIImage imageNamed:@"H_选择.png"] forState:(UIControlStateNormal)];
        [selectButton setImageEdgeInsets:UIEdgeInsetsMake(12, 18, 12, 18)];
        [_backView.contentView addSubview:selectButton];
    }
    
    return _backView;
}

- (UIVisualEffectView *)saveBackView {
    if (!_saveBackView) {
        _saveBackView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)]];
        _saveBackView.frame = CGRectMake(6, _backView.frame.origin.y + _backView.frame.size.height + 10, 60, 47);
        _saveBackView.alpha = 0;
        _saveBackView.layer.cornerRadius = 14;
        _saveBackView.clipsToBounds = YES;
        
        UIButton *saveButton = [[UIButton alloc] initWithFrame:_saveBackView.bounds];
        saveButton.exclusiveTouch = YES;
        saveButton.backgroundColor = [UIColor clearColor];
        [saveButton addTarget:self action:@selector(saveToAlbum) forControlEvents:(UIControlEventTouchUpInside)];
        [saveButton setImage:[UIImage imageNamed:@"H_保存.png"] forState:(UIControlStateNormal)];
        [saveButton setImageEdgeInsets:UIEdgeInsetsMake(12, 18, 12, 18)];
        [_saveBackView.contentView addSubview:saveButton];
    }
    
    return _saveBackView;
}

- (void)statusState {
    if (_viewWillDisappear) {
        self.backView.alpha = 0;
        self.saveBackView.alpha = 0;
    }else{
        if ([UIApplication sharedApplication].statusBarHidden) {
            [UIView animateWithDuration:0.25 animations:^{
                self.backView.alpha = 0;
                self.saveBackView.alpha = 0;
            }];
        }else{
            [UIView animateWithDuration:0.25 animations:^{
                self.backView.alpha = 1.0;
                self.saveBackView.alpha = 1.0;
            }];
        }
    }
}

- (void)select {
    if (_didSelectVideo) {
        _didSelectVideo();
    }
}

- (void)saveToAlbum {
    if (_didSelectSave) {
        _didSelectSave();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
