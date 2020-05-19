//
//  HeeePictureTakerController.m
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import "HeeePictureTakerController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "HeeePictureTakerAnimateButton.h"
#import "HeeeAVPlayerController.h"
#import "UIView+HeeeQuickFrame.h"
#import "UIView+HeeeHUD.h"
#import "UIView+HeeeToast.h"

typedef NS_ENUM(NSInteger,HPFlashMode) {
    HPFlashModeAuto,
    HPFlashModeOn,
    HPFlashModeOff,
};

@interface HeeePictureTakerController ()<CAAnimationDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
/*相机配置*/
@property (nonatomic, strong) AVCaptureDevice               *videoDevice;
@property (nonatomic, strong) AVCaptureSession              *session;
@property (nonatomic, strong) dispatch_queue_t              videoQueue;
@property (nonatomic, strong) dispatch_queue_t              audioQueue;
@property (nonatomic, strong) AVCaptureDeviceInput          *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput          *audioInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput      *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput      *audioOutput;

/*视频写入*/
@property (nonatomic, strong) dispatch_queue_t              writeQueue;
@property (nonatomic, strong) NSURL                         *videoUrl;
@property (nonatomic, strong) NSURL                         *temVideoUrl;
@property (nonatomic, strong) AVAssetWriter                 *videoAssetWriter;
@property (nonatomic, strong) AVAssetWriterInput            *assetWriterVideoInput;

/*音频写入*/
@property (nonatomic, strong) AVAssetWriter                 *audioAssetWriter;
@property (nonatomic, strong) NSURL                         *temAudioUrl;
@property (nonatomic, strong) AVAssetWriterInput            *assetWriterAudioInput;

@property (nonatomic, assign) BOOL                          isRecoding;//是否开始了录制
@property (nonatomic, assign) CGSize                        outputSize;//视频分辨率大小

/*UI*/
@property (nonatomic, strong) UIVisualEffectView            *maskView;
@property (nonatomic, strong) UIView                        *gestureView;//用于添加手势的view
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;//用于显示摄像头画面
@property (nonatomic, strong) AVCaptureStillImageOutput     *imageOutput;//照片输出流
@property (nonatomic, strong) UIImage                       *image;//拍照获得的照片
@property (nonatomic, strong) HeeePictureTakerAnimateButton *shutterButton;//拍照按钮
@property (nonatomic, strong) UIButton                      *switchCameraButton;//前后摄像头切换
@property (nonatomic, strong) UIButton                      *flashButton;//闪光灯按钮
@property (nonatomic, strong) UILabel                       *flashNoticeLabel;//闪光灯切换说明
@property (nonatomic, strong) UIView                        *recodeTimeBackView;//录像时间显示背景
@property (nonatomic, strong) UILabel                       *recodeTimeLabel;//录像时间显示
@property (nonatomic, strong) UIVisualEffectView            *retakeBackView;//重拍
@property (nonatomic, strong) UIVisualEffectView            *selectBackView;//选择
@property (nonatomic, strong) UIVisualEffectView            *saveBackView;//保存
@property (nonatomic, strong) UIView                        *focusView;//聚焦
@property (nonatomic, strong) UITapGestureRecognizer        *focusGesture;//对焦手势
@property (nonatomic, strong) UIPinchGestureRecognizer      *pinchGesture;//缩放手势
@property (nonatomic, strong) NSTimer                       *focusViewTimer1,*focusViewTimer2,*flashNoticeLabelTimer,*recodeTimer;//控制控件显示的timer
@property (nonatomic, assign) HPFlashMode                   flashMode;//0:自动，1:打开，2:关闭
@property (nonatomic, assign) CGFloat                       initialPinchZoom;
@property (nonatomic, assign) BOOL                          pictureMode;//没有在录视频的标志
@property (nonatomic, assign) int                           recodeTime;
@property (nonatomic, assign) BOOL                          isFirstComeIn;
@property (nonatomic, assign) BOOL                          notNeedStopRunning;
@property (nonatomic, assign) CGFloat                       screenWidth;
@property (nonatomic, assign) CGFloat                       screenHeight;

@end

@implementation HeeePictureTakerController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.temAudioUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.temAudioUrl path] error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.temVideoUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.temVideoUrl path] error:nil];
    }
}

- (void)willResignActiveNotification {
    [self reset];
    
    if (_session.isRunning) {
        [_session stopRunning];
    }
    
    if (_takerMode != HeeeTakerModeVideo) {
        _pictureMode = YES;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 1.0;
    }];
}

- (void)didBecomeActiveNotification {
   [_session startRunning];
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 0;
    }];
}

- (instancetype)initWithTakerMode:(HeeePictureTakerMode)takerMode {
    self = [super init];
    if (self) {
        _takerMode = takerMode;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _videoQueue = dispatch_queue_create("com.Heee.video", DISPATCH_QUEUE_SERIAL);
    _audioQueue = dispatch_queue_create("com.Heee.audio", DISPATCH_QUEUE_SERIAL);
    _writeQueue = dispatch_queue_create("com.Heee.write", DISPATCH_QUEUE_SERIAL);
    self.videoUrl = [[NSURL alloc] initFileURLWithPath:[self getVideoFolderWithName:@"video.mp4"]];
    self.temVideoUrl = [[NSURL alloc] initFileURLWithPath:[self getVideoFolderWithName:@"temVideo.mp4"]];
    self.temAudioUrl = [[NSURL alloc] initFileURLWithPath:[self getVideoFolderWithName:@"temAudio.m4a"]];
    _outputSize = CGSizeMake(1080, 1920);
    
    if (_takerMode != HeeeTakerModeVideo) {
        _pictureMode = YES;
    }
    
    _isFirstComeIn = YES;
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    _gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    [self.view addSubview:_gestureView];
    
    if ([self checkCameraPermission]) {
        [self configCamera];
        [self addSubViews];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _screenWidth = self.view.bounds.size.width;
    _screenHeight = self.view.bounds.size.height;
    _gestureView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    _maskView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    _pictureShowIV.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    self.retakeBackView.heee_bottom = _screenHeight - 80;
    self.saveBackView.heee_bottom = self.retakeBackView.heee_top - 10;
    self.selectBackView.heee_bottom = self.saveBackView.heee_top - 10;
    self.previewLayer.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    self.shutterButton.heee_centerX = _screenWidth/2;
    self.shutterButton.heee_bottom = _screenHeight - 34;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //需要设置info里面的View controller-based status bar appearance为NO才可以隐藏状态栏
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    if (!self.session.isRunning) {
        //开始显示画面
        [self.session startRunning];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([_videoDevice hasFlash] && !_notNeedStopRunning) {
        if (_pictureMode) {
            [self configFlashMode];
        }else{
            [self configTorchMode];
        }
    }
    
    _notNeedStopRunning = NO;
    if (_isFirstComeIn) {
        if ([self checkCameraPermission]) {
            [self handleFlashNoticeLabel];
            [self focusAtPoint:CGPointMake(_screenWidth/2, _screenHeight/2)];
        }else{
            __weak typeof (self) weakSelf = self;
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请到【设置】->【隐私】->【相机】中打开相机权限" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf closeButtonClickAnimate:YES];
            }];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"去设置" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
                
                [weakSelf closeButtonClickAnimate:YES];
            }];
            
            [alertC addAction:cancleAction];
            [alertC addAction:confirmAction];
            
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
    
    _isFirstComeIn = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self reset];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self reset];
    [self clearPicture];
    
    if (!_notNeedStopRunning && self.session.isRunning) {
        [self.session stopRunning];
    }
    
    [self.focusView.layer removeAllAnimations];
}

//UI
- (void)addSubViews {
    _maskView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _maskView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    _maskView.alpha = 0;
    [self.view addSubview:_maskView];
    
    [self.view addSubview:self.shutterButton];
    
    _switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [_switchCameraButton addTarget:self action:@selector(switchCameraButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
    
    if (@available(iOS 11.0, *)) {
        _switchCameraButton.heee_top = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top;
    }else{
        _switchCameraButton.heee_top = 10;
    }
    
    _switchCameraButton.heee_right = _screenWidth - 10;
    [_switchCameraButton setImage:[UIImage imageNamed:@"H_前后摄像头切换.png"] forState:(UIControlStateNormal)];
    [_switchCameraButton setImageEdgeInsets:UIEdgeInsetsMake(1, 0, 1, 0)];
    [self.view addSubview:_switchCameraButton];
    
    _flashButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [_flashButton addTarget:self action:@selector(flashButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
    [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_自动.png"] forState:(UIControlStateNormal)];
    [_flashButton setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
    _flashButton.heee_centerY = _switchCameraButton.heee_centerY;
    _flashButton.heee_right = _switchCameraButton.heee_left - 20;
    [self.view addSubview:_flashButton];
    
    _flashNoticeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 40)];
    _flashNoticeLabel.heee_top = _flashButton.heee_bottom + 20;
    _flashNoticeLabel.heee_centerX = _screenWidth/2;
    _flashNoticeLabel.alpha = 0;
    _flashNoticeLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    _flashNoticeLabel.layer.cornerRadius = 8;
    _flashNoticeLabel.clipsToBounds = YES;
    _flashNoticeLabel.textAlignment = NSTextAlignmentCenter;
    _flashNoticeLabel.font = [UIFont systemFontOfSize:18 weight:0.3];
    _flashNoticeLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_flashNoticeLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 40, 40)];
    [closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
    closeButton.heee_centerY = _switchCameraButton.heee_centerY;
    [closeButton setImage:[UIImage imageNamed:@"H_取消_白.png"] forState:(UIControlStateNormal)];
    [closeButton setImageEdgeInsets:UIEdgeInsetsMake(11, 11, 11, 11)];
    [self.view addSubview:closeButton];
    
    _recodeTimeBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
    _recodeTimeBackView.userInteractionEnabled = NO;
    _recodeTimeBackView.heee_centerY = _switchCameraButton.heee_centerY;
    _recodeTimeBackView.heee_centerX = (_flashButton.heee_centerX + closeButton.heee_centerX)/2;
    _recodeTimeBackView.alpha = 0;
    _recodeTimeBackView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    _recodeTimeBackView.layer.cornerRadius = 8;
    _recodeTimeBackView.clipsToBounds = YES;
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 10, 10)];
    redView.backgroundColor = [UIColor colorWithRed:242/255.0 green:54/255.0 blue:58/255.0 alpha:1.0];
    redView.layer.cornerRadius = 5;
    redView.clipsToBounds = YES;
    redView.heee_centerY = 20;
    [_recodeTimeBackView addSubview:redView];
    
    _recodeTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(redView.heee_right + 10, 0, 90, 40)];
    _recodeTimeLabel.textColor = [UIColor whiteColor];
    _recodeTimeLabel.font = [UIFont systemFontOfSize:18 weight:0.3];
    _recodeTimeLabel.text = @"00:00";
    [_recodeTimeBackView addSubview:_recodeTimeLabel];
    [self.view addSubview:_recodeTimeBackView];
    
    [self.view addSubview:self.focusView];
    
    _pictureShowIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    _pictureShowIV.userInteractionEnabled = YES;
    _pictureShowIV.hidden = YES;
    _pictureShowIV.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_pictureShowIV];
    
    [self.view addSubview:self.retakeBackView];
    [self.view addSubview:self.selectBackView];
    [self.view addSubview:self.saveBackView];
    self.retakeBackView.heee_bottom = _screenHeight - 80;
    self.saveBackView.heee_bottom = self.retakeBackView.heee_top - 10;
    self.selectBackView.heee_bottom = self.saveBackView.heee_top - 10;
    
    //对焦手势
    _focusGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    [_gestureView addGestureRecognizer:_focusGesture];
    
    //缩放手势
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [_gestureView addGestureRecognizer:_pinchGesture];
}

- (void)configCamera {
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    
    [self.session beginConfiguration];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    //添加视频输入
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if (_takerMode != HeeeTakerModePicture) {
        //添加语音输入
        AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:nil];
        if ([self.session canAddInput:self.audioInput]) {
            [self.session addInput:self.audioInput];
        }
    }
    
    //添加视频输出
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = [self.previewLayer connection].videoOrientation;
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([self.videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [connection setPreferredVideoStabilizationMode:stabilizationMode];
    }
    
    //添加语音输出
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
    //添加图像输出
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
    [self.session commitConfiguration];
    
    //添加画面显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    if ([self.videoDevice lockForConfiguration:nil]) {
        //默认自动闪光灯
        if ([self.videoDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [self.videoDevice setFlashMode:AVCaptureFlashModeAuto];
        }
        
        [self.videoDevice unlockForConfiguration];
    }
}

#pragma mark - action
//检测相机权限
- (BOOL)checkCameraPermission {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        return NO;
    }else{
        return YES;
    }
    return YES;
}

//设置写入属性
- (void)setUpWriter {
    //视频
    self.videoAssetWriter = [AVAssetWriter assetWriterWithURL:self.temVideoUrl fileType:AVFileTypeMPEG4 error:nil];
    
    NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                               AVVideoWidthKey : @(self.outputSize.height),
                                               AVVideoHeightKey : @(self.outputSize.width), AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill};
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    if ([_videoAssetWriter canAddInput:_assetWriterVideoInput]) {
        [_videoAssetWriter addInput:_assetWriterVideoInput];
    }
    
    //音频
    self.audioAssetWriter = [AVAssetWriter assetWriterWithURL:self.temAudioUrl fileType:AVFileTypeAppleM4A error:nil];
    
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                               AVEncoderBitRateKey:@(128000),
                                               AVSampleRateKey:@(44100),
                                               AVNumberOfChannelsKey:@(1)};
    
    self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
    self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    if ([self.audioAssetWriter canAddInput:self.assetWriterAudioInput]) {
        [self.audioAssetWriter addInput:self.assetWriterAudioInput];
    }
    
    _pictureMode = NO;
    _isRecoding = YES;
}

- (void)destroyWrite {
    self.videoAssetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
}

//存放视频的文件夹
- (NSString *)getVideoFolderWithName:(NSString *)name {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *direc = [cacheDir stringByAppendingPathComponent:@"videoFolder"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:direc]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:direc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    direc = [direc stringByAppendingPathComponent:name];
    return direc;
}

- (void)pinchGesture:(UIPinchGestureRecognizer*)sender {
    if (!_videoDevice)
        return;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        _initialPinchZoom = _videoDevice.videoZoomFactor;
    }
    
    if ([_videoDevice lockForConfiguration:nil]) {
        CGFloat zoomFactor;
        zoomFactor =  _initialPinchZoom*pow(sender.scale < 1.0?8:2, (sender.scale - 1.0f));
        zoomFactor = MIN(5.0, zoomFactor);
        zoomFactor = MAX(1.0, zoomFactor);
        _videoDevice.videoZoomFactor = zoomFactor;
        [_videoDevice unlockForConfiguration];
    }
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point {
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake(point.y /size.height ,1 - point.x/size.width);
    
    if ([self.videoDevice lockForConfiguration:nil]) {
        [self.videoDevice setFocusPointOfInterest:focusPoint];
        
        if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.videoDevice setExposurePointOfInterest:focusPoint];
            [self.videoDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            //曝光量调节
            [self.videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        [self.videoDevice unlockForConfiguration];
    }
    
    [self clearFocusTimer];
    
    self.focusView.transform = CGAffineTransformIdentity;
    self.focusView.center = point;
    self.focusView.alpha = 1;
    
    //对焦框缩放动画
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    anima.fillMode = kCAFillModeForwards;
    anima.removedOnCompletion = NO;
    anima.fromValue = [NSNumber numberWithFloat:1.0f];
    anima.toValue = [NSNumber numberWithFloat:0.6f];
    anima.duration = 0.25;
    anima.delegate = self;
    [self.focusView.layer addAnimation:anima forKey:@"focusViewAnimate"];
}

- (void)handleFlashNoticeLabel {
    if (_flashNoticeLabelTimer) {
        [_flashNoticeLabelTimer invalidate];
        _flashNoticeLabelTimer = nil;
    }
    
    self.flashNoticeLabel.alpha = 0;
    
    if (_flashMode == HPFlashModeAuto) {
        self.flashNoticeLabel.text = @"闪光灯-自动";
    }else if (_flashMode == HPFlashModeOn) {
        self.flashNoticeLabel.text = @"闪光灯-开";
    }else{
        self.flashNoticeLabel.text = @"闪光灯-关";
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.flashNoticeLabel.alpha = 1;
    }];
    
    _flashNoticeLabelTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(flashNoticeLabelTimerAction) userInfo:nil repeats:NO];
}

- (void)focusViewTimer1Action {
    [UIView animateWithDuration:0.25 animations:^{
        self.focusView.alpha = 0.3;
    }];
}

- (void)focusViewTimer2Action {
    [UIView animateWithDuration:0.25 animations:^{
        self.focusView.alpha = 0;
    }];
    [self clearFocusTimer];
}

- (void)flashNoticeLabelTimerAction  {
    [UIView animateWithDuration:0.25 animations:^{
        self.flashNoticeLabel.alpha = 0;
    }];
}

- (void)refreshRecodeTime {
    _recodeTime++;
    
    if (_recodeTime < 60) {
        _recodeTimeLabel.text = [NSString stringWithFormat:@"00:%02d",_recodeTime];
    }else if (_recodeTime < 60*60) {
        _recodeTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d",_recodeTime/60,_recodeTime%60];
    }else{
        //最多录制1个小时
        [self stopWrite];
    }
}

- (void)clearFocusTimer {
    if (_focusViewTimer1) {
        [_focusViewTimer1 invalidate];
        _focusViewTimer1 = nil;
    }
    
    if (_focusViewTimer2) {
        [_focusViewTimer2 invalidate];
        _focusViewTimer2 = nil;
    }
    
    [self.focusView.layer removeAllAnimations];
    self.focusView.alpha = 0;
}

- (void)reset {
    [self.view hideHUD];
    _focusGesture.enabled = YES;
    _pinchGesture.enabled = YES;
    _recodeTimeLabel.text = @"00:00";
    _recodeTimeBackView.alpha = 0;
     _flashNoticeLabel.alpha = 0;
    [_shutterButton reset];
    _isRecoding = NO;
    _recodeTime = 0;
    [self clearFocusTimer];
    
    if (_videoDevice.isTorchActive) {
        if ([_videoDevice lockForConfiguration:nil]) {
            [_videoDevice setTorchMode:AVCaptureTorchModeOff];
            [_videoDevice setFlashMode:AVCaptureFlashModeAuto];
            [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_自动.png"] forState:UIControlStateNormal];
            [_videoDevice unlockForConfiguration];
        }
        
        _flashMode = HPFlashModeAuto;
    }
    
    if (_recodeTimer) {
        [_recodeTimer invalidate];
        _recodeTimer = nil;
    }
    
    [self destroyWrite];
}

- (void)clearPicture {
    self.retakeBackView.hidden = YES;
    self.selectBackView.hidden = YES;
    self.saveBackView.hidden = YES;
    _pictureShowIV.image = nil;
    _pictureShowIV.hidden = YES;
}

- (void)retakePicture {
    [self reset];
    [self clearPicture];
}

- (void)selectPicture {
    if (_delegate && [_delegate respondsToSelector:@selector(pictureTaker:didSelectImage:)]) {
        [_delegate pictureTaker:self didSelectImage:_image];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//保存照片到手机相册
- (void)saveToAlbum {
    UIImageWriteToSavedPhotosAlbum(_image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

//照片保存成功
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self.view showToast:@"保存照片成功" duration:1.5 andPosition:@"center"];
    if (_delegate && [_delegate respondsToSelector:@selector(pictureTaker:didSaveImage:error:)]) {
        [_delegate pictureTaker:self didSaveImage:image error:error];
    }
}

- (void)shutterButtonClick {
    if (_takerMode == HeeeTakerModeVideo) {
        if (_isRecoding) {
            [UIView animateWithDuration:0.25 animations:^{
                self.recodeTimeBackView.alpha = 0;
            } completion:^(BOOL finished) {
                self.recodeTimeLabel.text = @"00:00";
            }];
            
            [self stopWrite];
            
            if (self.recodeTimer) {
                [self.recodeTimer invalidate];
                self.recodeTimer = nil;
            }
            
            self.recodeTime = 0;
        }else{
            [UIView animateWithDuration:0.25 animations:^{
                self.recodeTimeBackView.alpha = 1.0;
            }];
            
            [self configTorchMode];
            
            [self startWrite];
            
            if (self.recodeTimer == nil) {
                self.recodeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshRecodeTime) userInfo:nil repeats:YES];
            }
        }
    }else if (_pictureMode) {
        [self.view hideHUD];
        
        _pictureShowIV.hidden = NO;
        _focusGesture.enabled = NO;
        _pinchGesture.enabled = NO;
        
        AVCaptureConnection *videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (videoConnection ==  nil) {
            _pictureShowIV.hidden = YES;
            _focusGesture.enabled = YES;
            _pinchGesture.enabled = YES;
            return;
        }
        
        //前置摄像头时，设置镜像图片
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionFront) {
            videoConnection.videoMirrored = YES;
        }
        
        __weak typeof (self) weakSelf = self;
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer == nil) {
                weakSelf.pictureShowIV.hidden = YES;
                weakSelf.focusGesture.enabled = YES;
                weakSelf.pinchGesture.enabled = YES;
                return;
            }
            
            NSData *imageData =  [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            weakSelf.image = [UIImage imageWithData:imageData];
            weakSelf.pictureShowIV.image = weakSelf.image;
            weakSelf.retakeBackView.hidden = weakSelf.pictureShowIV.hidden;
            weakSelf.selectBackView.hidden = weakSelf.pictureShowIV.hidden;
            weakSelf.saveBackView.hidden = weakSelf.pictureShowIV.hidden;
        }];
    }
}

- (void)startWrite {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.temVideoUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.temVideoUrl path] error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.temAudioUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.temAudioUrl path] error:nil];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.videoUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.videoUrl path] error:nil];
    }
    
    [self setUpWriter];
}

- (void)stopWrite {
    [self.view showHUDWithTitle:nil];
    
    if (_takerMode == HeeeTakerModePictureAndVideo) {
        //这种情况录视频，最好把shutterButton移除再加上，否则会走shutterButtonClick，造成不必要的问题。
        [self.shutterButton removeFromSuperview];
        self.shutterButton.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.shutterButton.userInteractionEnabled = YES;
        });
        [self.view insertSubview:self.shutterButton belowSubview:_pictureShowIV];
    }
    
    _isRecoding = NO;
    
    if (_takerMode == HeeeTakerModePictureAndVideo) {
        _pictureMode = YES;
    }
    
    //完成拍摄，关掉闪光灯
    if ([_videoDevice lockForConfiguration:nil]) {
        [_videoDevice setTorchMode:AVCaptureTorchModeOff];
        [_videoDevice unlockForConfiguration];
    }
    
    __weak __typeof(self)weakSelf = self;
    if(_videoAssetWriter && _videoAssetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            //视频
            [self.videoAssetWriter finishWritingWithCompletionHandler:^{
                [weakSelf mergeAudioAndVideo];
                [weakSelf destroyWrite];
            }];
            
            //音频
            [self.audioAssetWriter finishWritingWithCompletionHandler:^{
                
            }];
        });
    }else{
        [self reset];
        [self clearPicture];
    }
}

//合并音视频
-(void)mergeAudioAndVideo {
    if ([[NSFileManager defaultManager]fileExistsAtPath:[self.videoUrl path]]) {
        [[NSFileManager defaultManager]removeItemAtPath:[self.videoUrl path] error:nil];
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    CMTime nextClipStartTime = kCMTimeZero;
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:self.temVideoUrl options:options];
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:self.temAudioUrl options:options];
    
    //将视频加入混合器
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CMTime videoAssetTime = videoAssetTrack.timeRange.duration;
    Float64 videoDuration = CMTimeGetSeconds(videoAssetTime);
    
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    CMTime audioAssetTime = audioAssetTrack.timeRange.duration;
    Float64 audioDuration = CMTimeGetSeconds(audioAssetTime);
    
    if (videoDuration == 0 || audioDuration == 0) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self reset];
            [self.view showToast:@"视频时间太短" duration:1.5];
        });
        return;
    }
    
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    //******视频方向处理
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1,60);
    videoComposition.renderScale = 1.0;
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:a_compositionVideoTrack];
    
    AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI/2);
    CGAffineTransform rotateTranslate = CGAffineTransformTranslate(rotationTransform,320,0);
    
    [a_compositionVideoTrack setPreferredTransform:sourceVideoTrack.preferredTransform];
    [layerInstruction setTransform:rotateTranslate atTime:kCMTimeZero];
    
    instruction.layerInstructions = [NSArray arrayWithObject: layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    //将音频加入混合器
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audioDuration>videoDuration?video_timeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
    
    AVAssetExportSession *_assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1920x1080];
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    _assetExport.outputURL = self.videoUrl;
    
    __weak typeof (self) weakSelf = self;
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void ) {
         if (_assetExport.status == AVAssetExportSessionStatusCompleted) {
             //视频处理完成
             dispatch_sync(dispatch_get_main_queue(), ^{
                 [weakSelf.view hideHUD];
                 
                 HeeeAVPlayerController *moviePlayerVC = [HeeeAVPlayerController new];
                 moviePlayerVC.didSelectVideo = ^{
                     if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(pictureTaker:didSelctVideo:)]) {
                         [weakSelf.delegate pictureTaker:weakSelf didSelctVideo:weakSelf.videoUrl];
                     }
                     
                     [weakSelf dismissViewControllerAnimated:NO completion:nil];
                     [weakSelf dismissViewControllerAnimated:YES completion:nil];
                 };
                 
                 moviePlayerVC.didSelectSave = ^{
                     [weakSelf.view showHUDWithTitle:nil];
                     
                     //保存视频到相册
                     if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([weakSelf.videoUrl path])) {
                         UISaveVideoAtPathToSavedPhotosAlbum([weakSelf.videoUrl path], weakSelf, @selector(saveVideoToAlbum:didFinishSavingWithError:contextInfo:), nil);
                     }
                 };
                 
                 weakSelf.notNeedStopRunning = YES;
                 moviePlayerVC.player = [AVPlayer playerWithURL:weakSelf.videoUrl];
                 [weakSelf presentViewController:moviePlayerVC animated:YES completion:nil];
             });
         }else{
             dispatch_sync(dispatch_get_main_queue(), ^{
                 [weakSelf reset];
                 [weakSelf.view showToast:@"视频处理失败" duration:1.5];
             });
         }
     }];
}

- (void)switchCameraButtonClick {
    //获取摄像头的数量
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    //摄像头小于等于1的时候直接返回
    if (cameraCount <= 1) return;
    AVCaptureDevice *newCamera = nil;
    AVCaptureDeviceInput *newInput = nil;
    //获取当前相机的方向(前还是后)
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if (position == AVCaptureDevicePositionFront) {
        //获取后置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }else{
        //获取前置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }
    
    //输入流
    newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
    if (newInput != nil) {
        [self.session beginConfiguration];
        //先移除原来的input
        [self.session removeInput:self.videoInput];
        
        if (position == AVCaptureDevicePositionBack) {
            if ([UIScreen mainScreen].bounds.size.height == 480) {
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset640x480];
                }
            }else{
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
                }
            }
        }else{
            if ([UIScreen mainScreen].bounds.size.height == 480) {
                if ([self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
                    [self.session setSessionPreset:AVCaptureSessionPresetiFrame960x540];
                }
            }else{
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
                }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
                }
            }
        }
        
        if ([self.session canAddInput:newInput]) {
            [self.session addInput:newInput];
            self.videoInput = newInput;
        } else {
            //如果不能加现在的input，就加原来的input
            [self.session addInput:self.videoInput];
        }
        
        [self.session commitConfiguration];
    }
    
    if (_isRecoding || (_takerMode == HeeeTakerModeVideo && _flashMode == HPFlashModeOn)) {
        [self configTorchMode];
    }
    
    [self focusAtPoint:CGPointMake(_screenWidth/2, _screenHeight/2)];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

- (void)flashButtonClick {
    if (_flashMode < 2) {
        _flashMode++;
    }else{
        _flashMode = 0;
    }
    
    if ([_videoDevice hasFlash]) {
        if (_pictureMode) {
            [self configFlashMode];
        }else{
            [self configTorchMode];
        }
    }
    
    [self handleFlashNoticeLabel];
}

//拍照时
- (void)configFlashMode {
    if ([self.videoDevice lockForConfiguration:nil]) {
        if (_flashMode == HPFlashModeAuto) {
            if ([_videoDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_videoDevice setFlashMode:AVCaptureFlashModeAuto];
                [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_自动.png"] forState:UIControlStateNormal];
            }
        }else if (_flashMode == HPFlashModeOn) {
            if ([_videoDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                [_videoDevice setFlashMode:AVCaptureFlashModeOn];
                [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_开.png"] forState:UIControlStateNormal];
            }
        }else{
            if ([_videoDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                [_videoDevice setFlashMode:AVCaptureFlashModeOff];
                [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_关.png"] forState:UIControlStateNormal];
            }
        }
        
        [self.videoDevice unlockForConfiguration];
    }
}

//拍视频时
- (void)configTorchMode {
    //前摄拍视频不能开闪光灯，因此当成拍照模式来处理
    if ([[self.videoInput device] position] == AVCaptureDevicePositionBack) {
        if ([self.videoDevice lockForConfiguration:nil]) {
            [_videoDevice setTorchMode:AVCaptureTorchModeOff];
            if (_flashMode == HPFlashModeAuto) {
                if ([_videoDevice isTorchModeSupported:AVCaptureTorchModeAuto]) {
                    if (!_isFirstComeIn) {
                        [_videoDevice setTorchMode:AVCaptureTorchModeAuto];
                    }
                    
                    [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_自动.png"] forState:UIControlStateNormal];
                }
            }else if (_flashMode == HPFlashModeOn) {
                if ([_videoDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
                    [_videoDevice setTorchMode:AVCaptureTorchModeOn];
                    [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_开.png"] forState:UIControlStateNormal];
                }
            }else{
                if ([_videoDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
                    [_videoDevice setTorchMode:AVCaptureTorchModeOff];
                    [_flashButton setImage:[UIImage imageNamed:@"H_闪光灯_关.png"] forState:UIControlStateNormal];
                }
            }
            [self.videoDevice unlockForConfiguration];
        }
    }else{
        [self configFlashMode];
    }
}

- (void)closeButtonClick {
    [self closeButtonClickAnimate:YES];
}

- (void)closeButtonClickAnimate:(BOOL)animate {
    if (self.presentingViewController) {
        if (self.navigationController) {
            if (self.navigationController.viewControllers.count > 1) {
                [self.navigationController popViewControllerAnimated:animate];
            }else{
                [self dismissViewControllerAnimated:animate completion:nil];
            }
        }else{
            [self dismissViewControllerAnimated:animate completion:nil];
        }
    }else{
        [self.navigationController popViewControllerAnimated:animate];
    }
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        _focusViewTimer1 = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(focusViewTimer1Action) userInfo:nil repeats:NO];
        _focusViewTimer2 = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(focusViewTimer2Action) userInfo:nil repeats:NO];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!_isRecoding) {
        return;
    }
    
    @autoreleasepool {
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            @synchronized(self) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
            }
        }
        
        //音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
            @synchronized(self) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
            }
        }
    }
}

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL){
        return;
    }
    
    @synchronized(self){
        if (!_isRecoding){
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (!self.isRecoding){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (self.videoAssetWriter.status != AVAssetWriterStatusWriting) {
                [self.videoAssetWriter startWriting];
                CMTime start_recording_time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                CMTime startingTimeDelay = CMTimeMakeWithSeconds(0.1, 1000000000);
                CMTime startTimeToUse = CMTimeAdd(start_recording_time, startingTimeDelay);
                [self.videoAssetWriter startSessionAtSourceTime:startTimeToUse];
            }
            
            if (self.audioAssetWriter.status != AVAssetWriterStatusWriting) {
                [self.audioAssetWriter startWriting];
                CMTime start_recording_time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self.audioAssetWriter startSessionAtSourceTime:start_recording_time];
            }
            
            //写入视频数据
            if (mediaType == AVMediaTypeVideo && self.assetWriterVideoInput.readyForMoreMediaData) {
                [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio && self.assetWriterAudioInput.readyForMoreMediaData) {
                [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            }
            
            CFRelease(sampleBuffer);
        }
    });
}

//视频保存成功
- (void)saveVideoToAlbum:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self.view hideHUD];
    
    [self.presentedViewController.view showToast:@"保存视频成功" duration:1.5];
    if (_delegate && [_delegate respondsToSelector:@selector(pictureTaker:didSaveVideo:error:)]) {
        [_delegate pictureTaker:self didSaveVideo:self.videoUrl error:error];
    }
}

#pragma mark - lazy
- (HeeePictureTakerAnimateButton *)shutterButton {
    if (!_shutterButton) {
        _shutterButton = [[HeeePictureTakerAnimateButton alloc] initWithPictureMode:_takerMode == HeeeTakerModeVideo?NO:YES];
        
        if (_takerMode == HeeeTakerModePictureAndVideo) {
            __weak typeof (self) weakSelf = self;
            _shutterButton.longPressStart = ^{
                weakSelf.pictureMode = NO;
                
                [weakSelf configTorchMode];
                
                [UIView animateWithDuration:0.25 animations:^{
                    weakSelf.recodeTimeBackView.alpha = 1.0;
                }];
                
                [weakSelf startWrite];
                
                if (weakSelf.recodeTimer == nil) {
                    weakSelf.recodeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(refreshRecodeTime) userInfo:nil repeats:YES];
                }
            };
            
            _shutterButton.longPressEnd = ^{
                [UIView animateWithDuration:0.25 animations:^{
                    weakSelf.recodeTimeBackView.alpha = 0;
                } completion:^(BOOL finished) {
                    weakSelf.recodeTimeLabel.text = @"00:00";
                }];
                
                [weakSelf stopWrite];
                
                weakSelf.pictureMode = YES;
                if (weakSelf.recodeTimer) {
                    [weakSelf.recodeTimer invalidate];
                    weakSelf.recodeTimer = nil;
                }
                
                weakSelf.recodeTime = 0;
            };
        }
        
        [_shutterButton addTarget:self action:@selector(shutterButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
    }
    
    return _shutterButton;
}

- (UIVisualEffectView *)retakeBackView {
    if (!_retakeBackView) {
        _retakeBackView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)]];
        _retakeBackView.frame = CGRectMake(10, 80, 60, 47);
        _retakeBackView.hidden = YES;
        _retakeBackView.layer.cornerRadius = 14;
        _retakeBackView.clipsToBounds = YES;
        
        UIButton *retakeButton = [[UIButton alloc] initWithFrame:_retakeBackView.bounds];
        retakeButton.exclusiveTouch = YES;
        retakeButton.backgroundColor = [UIColor clearColor];
        [retakeButton addTarget:self action:@selector(retakePicture) forControlEvents:(UIControlEventTouchUpInside)];
        [retakeButton setImage:[UIImage imageNamed:@"H_取消_灰.png"] forState:(UIControlStateNormal)];
        [retakeButton setImageEdgeInsets:UIEdgeInsetsMake(13, 19, 13, 19)];
        [_retakeBackView.contentView addSubview:retakeButton];
    }
    
    return _retakeBackView;
}

- (UIVisualEffectView *)selectBackView {
    if (!_selectBackView) {
        _selectBackView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)]];
        _selectBackView.frame = CGRectMake(10, 80, 60, 47);
        _selectBackView.hidden = YES;
        _selectBackView.layer.cornerRadius = 14;
        _selectBackView.clipsToBounds = YES;
        
        UIButton *selectButton = [[UIButton alloc] initWithFrame:_selectBackView.bounds];
        selectButton.exclusiveTouch = YES;
        selectButton.backgroundColor = [UIColor clearColor];
        [selectButton addTarget:self action:@selector(selectPicture) forControlEvents:(UIControlEventTouchUpInside)];
        [selectButton setImage:[UIImage imageNamed:@"H_选择.png"] forState:(UIControlStateNormal)];
        [selectButton setImageEdgeInsets:UIEdgeInsetsMake(12, 18, 12, 18)];
        [_selectBackView.contentView addSubview:selectButton];
    }
    
    return _selectBackView;
}

- (UIVisualEffectView *)saveBackView {
    if (!_saveBackView) {
        _saveBackView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:(UIBlurEffectStyleDark)]];
        _saveBackView.frame = CGRectMake(10, 80, 60, 47);
        _saveBackView.hidden = YES;
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

- (UIView *)focusView {
    if (!_focusView) {
        CGFloat length = 120;
        
        _focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, length, length)];
        _focusView.userInteractionEnabled = NO;
        _focusView.alpha = 0;
        _focusView.layer.borderColor = [UIColor whiteColor].CGColor;
        _focusView.layer.borderWidth = 2;
        
        UIView *topLittleLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, length/10)];
        topLittleLine.heee_centerX = length/2;
        topLittleLine.backgroundColor = [UIColor whiteColor];
        [_focusView addSubview:topLittleLine];
        
        UIView *rightLittleLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, length/10, 2)];
        rightLittleLine.heee_centerY = length/2;
        rightLittleLine.heee_right = length;
        rightLittleLine.backgroundColor = [UIColor whiteColor];
        [_focusView addSubview:rightLittleLine];
        
        UIView *bottomLittleLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, length/10)];
        bottomLittleLine.heee_centerX = length/2;
        bottomLittleLine.heee_bottom = length;
        bottomLittleLine.backgroundColor = [UIColor whiteColor];
        [_focusView addSubview:bottomLittleLine];
        
        UIView *leftLittleLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, length/10, 2)];
        leftLittleLine.heee_centerY = length/2;
        leftLittleLine.backgroundColor = [UIColor whiteColor];
        [_focusView addSubview:leftLittleLine];
    }
    
    return _focusView;
}

@end
