//
//  HeeePictureTakerController.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger,HeeePictureTakerMode) {
    HeeeTakerModePicture,
    HeeeTakerModeVideo,
    HeeeTakerModePictureAndVideo,//点击拍照，长按拍视频
};

@class HeeePictureTakerController;
@protocol HeeePictureTakerViewControllerDelegate <NSObject>
@optional
- (void)pictureTaker:(HeeePictureTakerController *)pictureTaker didSelectImage:(UIImage *)image;
- (void)pictureTaker:(HeeePictureTakerController *)pictureTaker didSaveImage:(UIImage *)image error:(NSError *)error;
- (void)pictureTaker:(HeeePictureTakerController *)pictureTaker didSelctVideo:(NSURL *)videoPath;
- (void)pictureTaker:(HeeePictureTakerController *)pictureTaker didSaveVideo:(NSURL *)videoPath error:(NSError *)error;

@end

@interface HeeePictureTakerController : UIViewController
@property (nonatomic,assign) HeeePictureTakerMode takerMode;
@property (nonatomic,assign) AVCaptureSessionPreset videoQuality;//默认：AVCaptureSessionPreset1920x1080
@property (nonatomic,assign) NSTimeInterval maxVideoDuration;//视频最长录制时间，默认不限制。
@property (nonatomic,weak) id<HeeePictureTakerViewControllerDelegate> delegate;

- (instancetype)initWithTakerMode:(HeeePictureTakerMode)takerMode;

@end
