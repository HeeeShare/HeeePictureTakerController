//
//  HeeePictureTakerViewController.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,PictureTakerMode) {
    TakerModePicture,
    TakerModeVideo,
    TakerModePictureAndVideo,//点击拍照，长按拍视频
};

@class HeeePictureTakerViewController;
@protocol HeeePictureTakerViewControllerDelegate <NSObject>
@optional
- (void)pictureViewController:(HeeePictureTakerViewController *)pictureTaker didSelectImage:(UIImage *)image;
- (void)pictureViewController:(HeeePictureTakerViewController *)pictureTaker didSaveImage:(UIImage *)image error:(NSError *)error;
- (void)pictureViewController:(HeeePictureTakerViewController *)pictureTaker didSelctVideo:(NSURL *)videoPath;
- (void)pictureViewController:(HeeePictureTakerViewController *)pictureTaker didSaveVideo:(NSURL *)videoPath error:(NSError *)error;

@end

@interface HeeePictureTakerViewController : UIViewController
//照片展示
@property (nonatomic,strong) UIImageView *pictureShowIV;
@property (nonatomic,assign) PictureTakerMode takerMode;
@property (nonatomic,  weak) id<HeeePictureTakerViewControllerDelegate> delegate;

- (instancetype)initWithTakerMode:(PictureTakerMode)takerMode;

@end
