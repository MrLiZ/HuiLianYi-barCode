//
//  BarcodeScannerViewController.m
//  barcode
//
//  Created by jingren on 16/9/11.
//  Copyright © 2016年 jieweifu. All rights reserved.
//
#import "UIView+Toast.h"
#import "BarcodeScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CustomScanView.h"
#import "Reachability.h"

#define kwidth [UIScreen mainScreen].bounds.size.width
#define kheight [UIScreen mainScreen].bounds.size.height

@interface BarcodeScannerViewController ()<AVCaptureMetadataOutputObjectsDelegate, BarcodeScannerDelegate>
@property (weak, nonatomic) IBOutlet UIView *renderView;
@property (weak, nonatomic) IBOutlet UIView *scanView;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;//扫描框上
@property (strong, nonatomic) AVAudioPlayer *beepPlayer;
@property BOOL isFlashLightOn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanNetHeightConstraint;
@property (nonatomic, strong) AVCaptureSession *session;
@property (weak, nonatomic) IBOutlet UIImageView *scanNetImage;
@property (strong, nonatomic) NSTimer *timerScan;
@property (weak, nonatomic) IBOutlet UIView *navigatorView;
@property BOOL isDismissViewController;
@property (weak, nonatomic) IBOutlet UILabel *bottomScanLabel;
@property (weak, nonatomic) IBOutlet UIView *writeView;
@property (weak, nonatomic) IBOutlet UILabel *writeLabel;

@property (nonatomic,strong) CustomScanView *customScanView;
@property (nonatomic,strong) NetWorkView *networkView;
@property (nonatomic,strong) NSURLSessionDataTask *dataTask;

@property (nonatomic,strong) UIView *loadingView;
@property (nonatomic,strong) CSToastStyle *toastStyle;
@end

@implementation BarcodeScannerViewController

- (IBAction)dimissScan:(id)sender {
    [self stopScanning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openFlashLight:(id)sender{
    [self setFlashOn:self.isFlashLightOn];
    self.isFlashLightOn = !self.isFlashLightOn;
}

- (void) setFlashOn: (BOOL)on{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}
#pragma mark lazyload
- (CustomScanView *)customScanView{
    if(_customScanView == nil){
        _customScanView = [[CustomScanView alloc] initWithFrame:CGRectMake(0, 64, kwidth, kheight-64)];
        _customScanView.hidden = YES;
    }
    return _customScanView;
}
- (NetWorkView *)networkView{
    if(_networkView == nil){
        _networkView = [[NetWorkView alloc] initWithFrame:CGRectMake(0, 64, kwidth, kheight-64)];
        _networkView.hidden = YES;
    }
    return _networkView;
}

- (CSToastStyle *)toastStyle{
    if(_toastStyle == nil){
        _toastStyle = [[CSToastStyle alloc] initWithDefaultStyle];
        _toastStyle.titleAlignment = NSTextAlignmentCenter;
        _toastStyle.titleNumberOfLines = 0;
        _toastStyle.titleFont = [UIFont systemFontOfSize:15];
        _toastStyle.messageFont = [UIFont systemFontOfSize:17];
    }
    return _toastStyle;
}

- (UIView *)loadingView{
    if(_loadingView == nil){
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, 40)];
        UILabel *loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 120, 30)];
        loadLabel.font = [UIFont systemFontOfSize:15];
        loadLabel.textColor = [UIColor whiteColor];
        loadLabel.textAlignment = NSTextAlignmentCenter;
        loadLabel.text = @"正在处理中...";
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(loadLabel.frame)+10, 5, 1, 30)];
        line.backgroundColor = [UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1];
        [_loadingView addSubview:line];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(CGRectGetMaxX(line.frame)+5, 5, 30, 30);
        [btn setTitle:@"X" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(closeToast) forControlEvents:UIControlEventTouchUpInside];
        [_loadingView addSubview:loadLabel];
        [_loadingView addSubview:btn];
        _loadingView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        _loadingView.layer.cornerRadius = 20;
        _loadingView.layer.masksToBounds = YES;
    }
    return _loadingView;
}

#pragma mark liftcycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initResource];
    [self initCapture];
    [self initSubViews];
    self.subtitle.text = self.messageDic[@"title"];
    self.bottomScanLabel.text = self.messageDic[@"tipScan"];
    self.firstSubLabel.text = self.messageDic[@"footerFirst"];
    self.secondSubLabel.text = self.messageDic[@"footerSecond"];
    self.writeView.backgroundColor = [UIColor colorWithRed:146/255.0 green:146/255.0 blue:146/255.0 alpha:1];
    self.writeLabel.text = self.messageDic[@"tipInput"];
    self.writeView.layer.cornerRadius = 15;
    [self.writeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)]];
}

- (void)initResource{
    self.isFlashLightOn = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    NSString * wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:wavPath];
    self.beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
}

- (void)initSubViews{
    [self startScanning];
    [CSToastManager setTapToDismissEnabled:NO];
//    [CSToastManager setQueueEnabled:NO];
    
    [self.view addSubview:self.networkView];
    [self.view addSubview:self.customScanView];
    [_customScanView.openBtn addTarget:self action:@selector(openAction) forControlEvents:UIControlEventTouchUpInside];
    _customScanView.firstLabel.text = self.messageDic[@"footerFirst"];
    _customScanView.secondLabel.text = self.messageDic[@"footerSecond"];
    NetworkStatus status = [self getNetWorkStatus];
    if(status == NotReachable){//没有网络
        _scanView.hidden = YES;
        _customScanView.hidden = YES;
        _networkView.hidden = NO;
        _networkView.msgLabel.text = self.messageDic[@"tipNetworkError"];
    }else if ([_operationType isEqualToString:@"REVIEW"]){
        [self handle_REVIEW:nil];
    }
    
}

//获取当前的网络状态 0:无网 1:WIFI 2:蜂窝网络
- (NetworkStatus)getNetWorkStatus{
    Reachability *reachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
    return [reachability currentReachabilityStatus];
}
#pragma mark  operation type
//财务审核通过扫码
- (void)handle_AUDIT_PASS:(NSString *)code{
    NSDictionary *dic = [_requestList firstObject];
    [self.view showToast:self.loadingView duration:MAXFLOAT position:[NSValue valueWithCGPoint:CGPointMake(kwidth/2, kheight/2)] completion:nil];
    NSMutableDictionary *body = [dic[@"data"] mutableCopy];
    [body setObject:code forKey:@"code"];
    __weak BarcodeScannerViewController *weakSelf = self;
    _dataTask = [NetWorkTool request:dic[@"url"] header:dic[@"headers"] method:dic[@"method"] params:body success:^(id response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view hideToasts];
        });
        if(response){
            if([[NSString stringWithFormat:@"%@",response[@"code"]] isEqualToString:@"0000"]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.view makeToast:response[@"msg"] duration:1.0f position:CSToastPositionCenter title:[NSString stringWithFormat:@"%@\n%@",response[@"expenseReport"][@"createdName"],response[@"expenseReport"][@"businessCode"]] image:nil style:weakSelf.toastStyle completion:^(BOOL didTap) {
                        [weakSelf startScanning];
                    }];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.view makeToast:response[@"msg"] duration:1.0f position:CSToastPositionCenter title:nil image:nil style:nil completion:^(BOOL didTap) {
                        [weakSelf startScanning];
                    }];
                });
            }
        }
    } failure:^(NSError *error) {
        
    }];
}
//财务审核收到扫码
- (void)handle_RECEIVE:(NSString *)code{
    NSDictionary *dic = [_requestList firstObject];
    [self.view showToast:self.loadingView duration:MAXFLOAT position:[NSValue valueWithCGPoint:CGPointMake(kwidth/2, kheight/2)] completion:nil];
    NSMutableDictionary *body = [dic[@"data"] mutableCopy];
    [body setObject:code forKey:@"code"];
    __weak BarcodeScannerViewController *weakSelf = self;
    _dataTask = [NetWorkTool request:dic[@"url"] header:dic[@"headers"] method:dic[@"method"] params:body success:^(id response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view hideToasts];
        });
        if(response){
            dispatch_async(dispatch_get_main_queue(), ^{
               [weakSelf.view makeToast:response[@"msg"] duration:1.0 position:CSToastPositionCenter title:nil image:nil style:nil completion:^(BOOL didTap) {
                   [weakSelf startScanning];
               }];
            });
        }
        
    } failure:^(NSError *error) {
        
    }];
}
//财务审核驳回扫码
- (void)handle_AUDIT:(NSString *)code{
    NSDictionary *dic = [_requestList firstObject];
    [self.view showToast:self.loadingView duration:MAXFLOAT position:[NSValue valueWithCGPoint:CGPointMake(kwidth/2, kheight/2)] completion:nil];
    NSMutableDictionary *body = [dic[@"data"] mutableCopy];
    [body setObject:code forKey:@"code"];
    __weak BarcodeScannerViewController *weakSelf = self;
    _dataTask = [NetWorkTool request:dic[@"url"] header:dic[@"headers"] method:dic[@"method"] params:body success:^(id response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view hideToasts];
        if(response){
            if([[NSString stringWithFormat:@"%@",response[@"code"]] isEqualToString:@"0000"]){
                [weakSelf.view makeToast:response[@"msg"] duration:1.0 position:CSToastPositionCenter title:nil image:nil style:nil completion:^(BOOL didTap) {
                    if([weakSelf.delegate respondsToSelector:@selector(reader:)]){
                        [weakSelf.delegate reader:@{@"type":weakSelf.operationType}];
                    }
                }];
            }else{
                [weakSelf.view makeToast:response[@"msg"] duration:1.0f position:CSToastPositionCenter];
                [weakSelf startScanning];
            }
        }
     });
    } failure:^(NSError *error) {
        
    }];
}
//检查是否web在线
- (void)handle_REVIEW:(NSString *)code{
    __weak BarcodeScannerViewController *weakSelf = self;
    NSDictionary *webDic = self.requestList[1];
    [self.view showToast:self.loadingView duration:MAXFLOAT position:[NSValue valueWithCGPoint:CGPointMake(kwidth/2, kheight/2)] completion:nil];
    _dataTask = [NetWorkTool request:webDic[@"url"] header:webDic[@"headers"] method:webDic[@"method"] params:webDic[@"data"] success:^(id response) {
        if(response){
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view hideToasts];
                if([[NSString stringWithFormat:@"%@",response[@"online"]] isEqualToString:@"1"]){
                    weakSelf.scanView.hidden = NO;
                    weakSelf.networkView.hidden = YES;
                    weakSelf.customScanView.hidden = YES;
                    if(code){
                        [weakSelf handle_REVIEW_Open:code];
                    }else{
                        [weakSelf startScanning];
                    }
                }else{
                    weakSelf.scanView.hidden = YES;
                    weakSelf.networkView.hidden = YES;
                    weakSelf.customScanView.hidden = NO;
                }
            });
        }
    } failure:^(NSError *error) {
        
    }];
}
//财务读图审核扫码
- (void)handle_REVIEW_Open:(NSString *)code{
    __weak BarcodeScannerViewController *weakSelf = self;
    NSDictionary *webDic = [self.requestList firstObject];
    NSMutableDictionary *body = [webDic[@"data"] mutableCopy];
    [body setObject:code forKey:@"code"];
    [self.view showToast:self.loadingView duration:MAXFLOAT position:[NSValue valueWithCGPoint:CGPointMake(kwidth/2, kheight/2)] completion:nil];
    _dataTask = [NetWorkTool request:webDic[@"url"] header:webDic[@"headers"] method:webDic[@"method"] params:body success:^(id response) {
        if(response){
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view hideToasts];
                if([[NSString stringWithFormat:@"%@",response[@"code"]] isEqualToString:@"0000"]){
                    [weakSelf.view makeToast:response[@"msg"] duration:1.0 position:CSToastPositionCenter title:nil image:nil style:nil completion:^(BOOL didTap) {
                        if([weakSelf.delegate respondsToSelector:@selector(reader:)]){
                            [weakSelf.delegate reader:@{@"type":weakSelf.operationType}];
                        }
                    }];
                }else{
                    [weakSelf.view makeToast:response[@"msg"] duration:1.0f position:CSToastPositionCenter title:nil image:nil style:nil completion:^(BOOL didTap) {
                        [weakSelf startScanning];
                    }];
                }
            });
        }
    } failure:^(NSError *error) {
        
    }];
}

#pragma mark action
- (void)openAction{
    [self handle_REVIEW:nil];
}
//手动输入
- (void)tapAction{
    if([self.delegate respondsToSelector:@selector(reader:)]){
        [self.delegate reader:@{@"type":@"INPUT"}];
        dispatch_async(dispatch_get_main_queue(), ^{

            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

//停止处理..
- (void)closeToast{
    [_dataTask cancel];
    [self.view hideToasts];
}

//开始扫描
- (void)startScanning
{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
    
    if(self.timerScan)
    {
        [self.timerScan invalidate];
        self.timerScan = nil;
    }
    
    self.timerScan = [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(scanAnimate) userInfo:nil repeats:YES];
}

- (void) scanAnimate{
    [UIView animateWithDuration:0.8
                     animations:^{
                         self.scanNetHeightConstraint.constant = self.scanView.bounds.size.height;
                         [self.scanNetImage layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                         self.scanNetHeightConstraint.constant = 0;
                         [self.scanNetImage layoutIfNeeded];
                     }];
}
//停止扫描
- (void)stopScanning;
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    if(self.timerScan)
    {
        [self.timerScan invalidate];
        self.timerScan = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//初始化设备
- (void)initCapture
{
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置有效扫描区域
    
    CGRect scanCrop=[self getScanCrop:self.scanView.bounds readerViewBounds:self.renderView.frame];
    output.rectOfInterest = scanCrop;
    //初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [self.session addInput:input];
    [self.session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    //    layer.frame=self.view.layer.bounds;
//    NSLog(@"%@", NSStringFromCGRect(self.renderView.frame));
    layer.frame=self.renderView.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate Methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *result = @"";
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            result = [(AVMetadataMachineReadableCodeObject *) current stringValue];
            [self.beepPlayer play];
            break;
        }
    }
    [self stopScanning];
    if([self getNetWorkStatus] == 0){
        self.scanView.hidden = YES;
        self.customScanView.hidden = YES;
        self.networkView.hidden = NO;
        return;
    }
    if(result){
        if([[_operationType uppercaseString] isEqualToString:@"AUDIT_PASS"]){
            [self handle_AUDIT_PASS:result];
        }else if ([[_operationType uppercaseString] isEqualToString:@"RECEIVE"]){
            [self handle_RECEIVE:result];
        }else if ([[_operationType uppercaseString] isEqualToString:@"AUDIT"]){
            [self handle_AUDIT:result];
        }else if ([[_operationType uppercaseString] isEqualToString:@"REVIEW"]){
            [self handle_REVIEW:result];
        }
    }
    
}

#pragma mark-> 获取扫描区域的比例关系
-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    
    CGFloat x,y,width,height;
    
    x = (CGRectGetHeight(readerViewBounds)-CGRectGetHeight(rect))/2/CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds)-CGRectGetWidth(rect))/2/CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect)/CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect)/CGRectGetWidth(readerViewBounds);
    
    return CGRectMake(x, y, width, height);
    
}

#pragma mark  屏幕方向处理
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
