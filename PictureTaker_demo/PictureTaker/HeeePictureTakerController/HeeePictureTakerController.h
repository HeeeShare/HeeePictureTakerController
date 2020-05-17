//
//  HeeePictureTakerController.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger,HeeePictureTakerMode) {
    HeeeTakerModePicture,
    HeeeTakerModeVideo,
    HeeeTakerModePictureAndVideo,//点击拍照，长按拍视频
};

@class HeeePictureTakerController;
@protocol HeeePictureTakerViewControllerDelegate <NSObject>
@optional
- (void)pictureViewController:(HeeePictureTakerController *)pictureTaker didSelectImage:(UIImage *)image;
- (void)pictureViewController:(HeeePictureTakerController *)pictureTaker didSaveImage:(UIImage *)image error:(NSError *)error;
- (void)pictureViewController:(HeeePictureTakerController *)pictureTaker didSelctVideo:(NSURL *)videoPath;
- (void)pictureViewController:(HeeePictureTakerController *)pictureTaker didSaveVideo:(NSURL *)videoPath error:(NSError *)error;

@end

@interface HeeePictureTakerController : UIViewController
//照片展示
@property (nonatomic,strong) UIImageView *pictureShowIV;
@property (nonatomic,assign) HeeePictureTakerMode takerMode;
@property (nonatomic,  weak) id<HeeePictureTakerViewControllerDelegate> delegate;

- (instancetype)initWithTakerMode:(HeeePictureTakerMode)takerMode;

@end
