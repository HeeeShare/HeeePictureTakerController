//
//  ViewController.m
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "ViewController.h"
#import "HeeePictureTakerViewController.h"
#import "UIView+HeeeToast.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *pictureBtn = [self makeButtonWithTitle:@"照片模式"];
    pictureBtn.frame = CGRectMake(60, 60, 160, 50);
    [self.view addSubview:pictureBtn];
    [pictureBtn addTarget:self action:@selector(pictureBtnClick) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *videoBtn = [self makeButtonWithTitle:@"视频模式"];
    videoBtn.frame = CGRectMake(60, 140, 160, 50);
    [self.view addSubview:videoBtn];
    [videoBtn addTarget:self action:@selector(videoBtnClick) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *pictureAndVideoBtn = [self makeButtonWithTitle:@"照片视频模式"];
    pictureAndVideoBtn.frame = CGRectMake(60, 220, 160, 50);
    [self.view addSubview:pictureAndVideoBtn];
    [pictureAndVideoBtn addTarget:self action:@selector(pictureAndVideoBtnClick) forControlEvents:(UIControlEventTouchUpInside)];
}

- (void)pictureBtnClick {
    HeeePictureTakerViewController *pictureTakerVC = [[HeeePictureTakerViewController alloc] initWithTakerMode:TakerModePicture];
    [self presentViewController:pictureTakerVC animated:YES completion:nil];
}

- (void)videoBtnClick {
    HeeePictureTakerViewController *pictureTakerVC = [[HeeePictureTakerViewController alloc] initWithTakerMode:TakerModeVideo];
    [self presentViewController:pictureTakerVC animated:YES completion:nil];
}

//点击拍照，长按拍视频
- (void)pictureAndVideoBtnClick {
    HeeePictureTakerViewController *pictureTakerVC = [[HeeePictureTakerViewController alloc] initWithTakerMode:TakerModePictureAndVideo];
    [self presentViewController:pictureTakerVC animated:YES completion:nil];
}

- (UIButton *)makeButtonWithTitle:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.titleLabel.font = [UIFont systemFontOfSize:18 weight:0.3];
    btn.frame = CGRectMake(60, 60, 160, 50);
    btn.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [btn setTitle:title forState:(UIControlStateNormal)];
    return btn;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
