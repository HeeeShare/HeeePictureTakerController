//
//  HeeePictureTakerAnimateButton.h
//  PictureTaker
//
//  Created by hgy on 2018/8/8.
//  Copyright © 2018年 hgy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^longPressStartBlock)(void);
typedef void(^longPressEndBlock)(void);

@interface HeeePictureTakerAnimateButton : UIButton
- (instancetype)initWithPictureMode:(BOOL)pictureMode;
- (void)reset;

@property (nonatomic,copy) longPressStartBlock longPressStart;
@property (nonatomic,copy) longPressEndBlock longPressEnd;

@end
