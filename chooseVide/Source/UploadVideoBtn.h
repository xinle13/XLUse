//
//  UploadVideoBtn.h
//  xinleTest
//
//  Created by xinleTest on 2020/5/11.
//  Copyright © 2020 xinleTest PROJECT. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^UploadEndBlock)(NSData *videoData);

@interface UploadVideoBtn : UIButton

@property (nonatomic, weak)UIViewController *targetVC;
@property (nonatomic, strong)NSData *videoData;
@property (nonatomic, copy)UploadEndBlock uploadEndBlock;
@property (nonatomic, assign)CGFloat progressValue;

@end

NS_ASSUME_NONNULL_END
