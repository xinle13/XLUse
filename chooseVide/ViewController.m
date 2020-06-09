//
//  ViewController.m
//  chooseVide
//
//  Created by xinleTest on 2020/5/13.
//  Copyright © 2020 xinleTest. All rights reserved.
//

#import "ViewController.h"
#import "UploadVideoBtn.h"

#define WEAK_SELF       __weak typeof(self) weakSelf = self;

@interface ViewController ()

@property (nonatomic, strong)UploadVideoBtn *imgBtn1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    WEAK_SELF
    _imgBtn1 = [[UploadVideoBtn alloc] init];
    _imgBtn1.frame = CGRectMake(100, 100, 160, 80);
    _imgBtn1.targetVC = weakSelf;
    _imgBtn1.uploadEndBlock = ^(NSData * _Nonnull videoData) {
        NSLog(@"~~~此处选择的视频文件~~~");
    };
    [self.view addSubview:_imgBtn1];
    
    
}


@end
