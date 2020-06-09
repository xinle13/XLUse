//
//  UploadVideoBtn.m
//  xinleTest
//
//  Created by xinleTest on 2020/5/11.
//  Copyright © 2020 xinleTest PROJECT. All rights reserved.
//

#import "UploadVideoBtn.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h> // 1. 导入头文件  iOS 9 新增
#import "WLCircleProgressView.h"

#define VIDEOCACHEPATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"videoCache"]
// 检测block是否可用
#define BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); }

@interface UploadVideoBtn ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIVideoEditorControllerDelegate>

@property (nonatomic, strong) WLCircleProgressView *progressView2;
@property (nonatomic, strong)UIImagePickerController *imagePicker;
@property (nonatomic, strong)NSString *filePath;

@end

@implementation UploadVideoBtn

-(void)dealloc{
    NSLog(@"~~~UploadVideoBtn销毁~~~");
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self addSubview:self.progressView2];
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self setImage:[UIImage imageNamed:(@"kyc_uploadVideo")] forState:(UIControlStateNormal)];
        [self addTarget:self action:@selector(actionVideo) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return self;
}

- (void)actionVideo {
    
    //1.0 点击播放视频的按钮 此处可以播放或者重新选择
    if (self.videoData) {
        [self play];
        return;
    }
    
    UIAlertController *alertController = \
    [UIAlertController alertControllerWithTitle:@""
                                        message:@"上传视频"
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *photoAction = \
    [UIAlertAction actionWithTitle:@"从视频库选择"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * _Nonnull action) {
        
        NSLog(@"从视频库选择");
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        self.imagePicker.allowsEditing = NO;
        
        [self.targetVC presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *cameraAction = \
    [UIAlertAction actionWithTitle:@"录像"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * _Nonnull action) {
        
        NSLog(@"录像");
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        self.imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;
        self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        self.imagePicker.allowsEditing = YES;
        
        [self.targetVC presentViewController:self.imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *cancelAction = \
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction * _Nonnull action) {
        
        NSLog(@"取消");
    }];
    
    [alertController addAction:photoAction];
    [alertController addAction:cameraAction];
    [alertController addAction:cancelAction];
    
    [self.targetVC presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UIImagePickerDelegate方法

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    //获取用户选择或拍摄的是照片还是视频
    UIVideoEditorController *videoEditor = nil;
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        
        NSURL *URL =  info[UIImagePickerControllerMediaURL];
        
        //1.0 如果是拍摄的视频, 则把视频保存在系统多媒体库中(方便后期查证)
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            NSLog(@"video path: %@", info[UIImagePickerControllerMediaURL]);
            NSURL *URL =  info[UIImagePickerControllerMediaURL];
            //ios 8.0+
            NSError *error;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:URL];
                NSLog(@"%@",error);
            } error:&error];
            
            if([UIVideoEditorController canEditVideoAtPath:URL.path]){
                videoEditor = [[UIVideoEditorController alloc]init];
                videoEditor.videoPath = URL.path;
                videoEditor.delegate = self;
            }
        }
        
        //3.0 写入本地缓存,方便播放使用
        NSString *mediaName = [self getVideoNameBaseCurrentTime];
        NSLog(@"将视频存入缓存 mediaName: %@", mediaName);
        self.filePath = [VIDEOCACHEPATH stringByAppendingPathComponent:mediaName];
        [self saveVideoFromPath:info[UIImagePickerControllerMediaURL] toCachePath:self.filePath];
        
        //2.0 压缩视频 & 保存视频数据 & 获取第一张图片
        UIImage *img = [self getVideoPreViewImageWithPath:URL];
        NSString *zipFileName = [NSString stringWithFormat:@"zip%@",mediaName];
        NSString *zipPath = [VIDEOCACHEPATH stringByAppendingPathComponent:zipFileName];
        [self compressVideoAccroding:info[UIImagePickerControllerMediaURL] withOutputUrl:zipPath SuccessBlock:^(NSData * videoData) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //主线程界面刷新
                if (videoData.length > 20 * 1024 * 1024) {
                    NSLog(@"~~~视频超过20M,请重新选择~~~");
                    return;
                }
                [self setImage:img forState:(UIControlStateNormal)];
                self.videoData = videoData;
                BLOCK_EXEC(self.uploadEndBlock,videoData);
            });
        }];
    }
    //[picker dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
 
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  视频压缩
 *  @param originFilePath       视频资源的原始路径
 *  @param outputPath      输出路径
 */
-(void)compressVideoAccroding:(NSURL *)originFilePath withOutputUrl:(NSString *)outputPath SuccessBlock:(void(^)(NSData *))successBlock {
    //转码配置
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:originFilePath options:nil];
    AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exportSession.status;
        NSLog(@"转码状态:%d",exportStatus);
        
        switch (exportStatus)         {
            case AVAssetExportSessionStatusFailed:
            {
                // log error to text view
                NSError *exportError = exportSession.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                if (outputPath) {
                    NSURL *url = [NSURL fileURLWithPath:outputPath];
                    NSData *videoData = [NSData dataWithContentsOfURL:url];
                    NSLog(@"视频转码成功:%@",[self getSizeWithData:videoData]);
                    BLOCK_EXEC(successBlock,videoData)
                }
            }
        }
    }];
}

//以当前时间合成视频名称
- (NSString *)getVideoNameBaseCurrentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    return [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@".MP4"];
}

#pragma mark - videoEditorControllerDelegate方法
- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath{
    NSLog(@"%@",editedVideoPath);
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:editedVideoPath]];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"保存成功");
        }
        
        if (error) {
            NSLog(@"%@",error);
        }
    }];
    
    [editor dismissViewControllerAnimated:YES completion:nil];
}

//获取视频的第一帧截图, 返回UIImage (需要导入AVFoundation.h)
- (UIImage*) getVideoPreViewImageWithPath:(NSURL *)videoPath
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoPath options:nil];
    
    AVAssetImageGenerator *gen         = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time      = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error   = nil;
    
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img     = [[UIImage alloc] initWithCGImage:image];
    
    return img;
}

#pragma mark -- 缓存到本地
//将视频保存到缓存路径中
- (void)saveVideoFromPath:(NSString *)videoPath toCachePath:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:VIDEOCACHEPATH]) {
        
        NSLog(@"路径不存在, 创建路径");
        [fileManager createDirectoryAtPath:VIDEOCACHEPATH
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    } else {
        
        NSLog(@"路径存在");
    }
    
    NSError *error;
    [fileManager copyItemAtPath:videoPath toPath:path error:&error];
    if (error) {
        NSLog(@"文件保存到缓存失败");
    }
}

-(void)removeTempVideoData{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:&error];
    if (error) {
        NSLog(@"temp文件删除失败:%@",error);
    }else{
        NSLog(@"temp文件删除成功");
    }
}

#pragma mark -- 播放视频
-(void)play{
     // 本地资源文件
    NSString *filePath = self.filePath;
     // 2. 创建视频播放控制器
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    // 3. 设置视频播放器 (这里为了简便,使用了URL方式,同样支持playerWithPlayerItem:的方式)
    playerViewController.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    // 4. modal展示
    [self.targetVC presentViewController:playerViewController animated:YES completion:nil];
    // 5. 开始播放 : 默认不会自动播放
    [playerViewController.player play];
}


#pragma mark -- 加载的loading
-(WLCircleProgressView *)progressView2{
    if (_progressView2 == nil) {
        WLCircleProgressView *circleProgress2 = [WLCircleProgressView viewWithFrame:CGRectMake(0, 0, 30, 30) circlesSize:CGRectMake(28, 2, 24, 24)];
        circleProgress2.layer.cornerRadius = 10;
        //阴影
        circleProgress2.backgroundColor = [UIColor clearColor];
        circleProgress2.backCircle.shadowColor = [UIColor grayColor].CGColor;
        circleProgress2.backCircle.shadowRadius = 3;
        circleProgress2.backCircle.shadowOffset = CGSizeMake(0, 0);
        circleProgress2.backCircle.shadowOpacity = 1;
        circleProgress2.backCircle.fillColor = [UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:0.8].CGColor;
        circleProgress2.backCircle.strokeColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1].CGColor;
        circleProgress2.foreCircle.lineCap = @"butt";
        circleProgress2.foreCircle.strokeColor = [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1].CGColor;;
        circleProgress2.progressValue = 0.2;
        circleProgress2.hidden = YES;
        _progressView2 = circleProgress2;
    }
    return _progressView2;
}

-(void)setProgressValue:(CGFloat)progressValue{
    dispatch_async(dispatch_get_main_queue(), ^{
        //主线程界面刷新
        _progressValue = progressValue;
        if (progressValue == 0 || progressValue >= 1.0) {
            self.progressView2.hidden = YES;
        }else{
            self.progressView2.hidden = NO;
            self.progressView2.progressValue = progressValue;
        }
    });
}

/**获取文件大小*/
-(NSString *)getSizeWithData:(NSData *)data{
    
    double convertedValue = data.length;
    int multiplyFactor = 0;
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB", @"ZB", @"YB",nil];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    return [NSString stringWithFormat:@"%.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

@end
