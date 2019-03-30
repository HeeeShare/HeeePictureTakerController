//
//  HeeeAVPlayerViewController.h
//  PictureTaker
//
//  Created by diipo on 2018/8/9.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <AVKit/AVKit.h>

typedef void(^didSelectVideoBlock)(void);
typedef void(^didSelectSaveBlock)(void);

@interface HeeeAVPlayerViewController : AVPlayerViewController
@property (nonatomic,copy) didSelectVideoBlock didSelectVideo;
@property (nonatomic,copy) didSelectSaveBlock didSelectSave;

@end
