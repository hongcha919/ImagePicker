//
//  CustomUploadVC.m
//  HelloCordova
//
//  Created by haoqi on 2019/7/24.
//

#import "CustomUploadVC.h"
#import "CustomUploadCell.h"
#import "LFImagePickerHeader.h"
#import "NSBundle+LFImagePicker.h"

#define U_CDV_PHOTO_PREFIX @"cdv_photo_"

@interface CustomUploadVC () <QCloudSignatureProvider, QCloudCredentailFenceQueueDelegate>
@property (nonatomic, strong) QCloudCredentailFenceQueue* credentialFenceQueue;
@end

@interface CustomUploadVC ()<UITableViewDataSource,UITableViewDelegate,QCloudSignatureProvider>
{
    NSString *bucket; //存储桶
    NSString *region;//存储区域
    NSString *authorization;//签名
    NSArray *keysArray; //上传key数组
    NSArray *mediaIds;//媒体id 用户上传完成以后获取媒体对象Medias输出给js
    NSString *sessionToken; //token
    NSString *tmpSecretId; //tmpSecretId
    NSString *tmpSecretKey; //tmpSecretKey
    
    NSMutableArray *imgFileArray; //处理后的上传图片数据
    
    NSMutableArray *mediasArray; //音频、图片上传后的媒体对象列表。传送给js侧
    
    UIButton *_progressHUD;
    UIView *_HUDContainer;
    UIActivityIndicatorView *_HUDIndicatorView;
    UILabel *_HUDLabel;
}

@property (weak, nonatomic) UITableView *uploadTableView;

@property (nonatomic, strong) NSMutableArray *resultArray; //上传结果，用于回调出去

@property (nonatomic, strong) NSMutableArray *uploadStatusArray; //上传状态

@end

@implementation CustomUploadVC

-(NSMutableArray *)resultArray {
    if (!_resultArray) {
        _resultArray = [NSMutableArray array];
    }
    
    return _resultArray;
}

-(NSMutableArray *)uploadStatusArray {
    if (!_uploadStatusArray) {
        _uploadStatusArray = [NSMutableArray array];
        for (id obj in self.uploadArray) {
            [_uploadStatusArray addObject:[NSNumber numberWithInt:0]];
        }
    }
    return _uploadStatusArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"上传进度";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initData];
    
    CGSize size = CGSizeMake(44, 44);
    CGFloat margin = 10.f;
    
    /** 左 */
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = (CGRect){{0,0}, size};
    leftButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [leftButton setImage:[NSBundle lf_MediaPickerUploadImage:@"navigationbar_back_black"] forState:UIControlStateNormal];
    [leftButton setTitle:@"返回" forState:UIControlStateNormal];
    [leftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [leftButton setImage:bundleImageNamed(@"navigationbar_back_arrow") forState:UIControlStateHighlighted];
    //    [leftButton setImage:bundleImageNamed(@"navigationbar_back_arrow") forState:UIControlStateSelected];
    [leftButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImageEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 10)];
    [leftButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 10)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.customView.alpha = 0.5;
    
    /** 右 */
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 50, 30);
    rightButton.layer.cornerRadius = 5;
    rightButton.layer.masksToBounds = YES;
    rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [rightButton setTitle:@"确定" forState:UIControlStateNormal];
    [rightButton setBackgroundColor:[UIColor colorWithRed:1.f/255.f green:194.f/255.f blue:162.f/255.f alpha:1]];
    [rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn.png") forState:UIControlStateNormal];
    //    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateHighlighted];
    //    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(okBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.customView.alpha = 0.5;
}

#pragma mark =============== 初始化数据 ===============
-(void)initData {
    imgFileArray = [NSMutableArray array];
    keysArray = [NSArray array];
    mediaIds = [NSArray array];
    mediasArray = [NSMutableArray array];
    [self getTicketMsg];
}

/**
 初始化腾讯云cos服务
 */
-(void)initCosData {
    [self setupCOSXMLShareService];
    self.credentialFenceQueue = [QCloudCredentailFenceQueue new];
    self.credentialFenceQueue.delegate = self;
    
//    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
//    configuration.appID = [[NSBundle mainBundle] bundleIdentifier];
//    configuration.signatureProvider = self;
//    QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
//    endpoint.regionName = [NSString getSafeStrWithStr:region showNull:@"re-beijing"];//服务地域名称，可用的地域请参考注释
//    configuration.endpoint = endpoint;
//    [QCloudCOSXMLService registerDefaultCOSXMLWithConfiguration:configuration];
//    [QCloudCOSTransferMangerService registerDefaultCOSTransferMangerWithConfiguration:configuration];
}
#pragma QCloudCredentailFenceQueueDelegate
- (void) fenceQueue:(QCloudCredentailFenceQueue *)queue requestCreatorWithContinue:(QCloudCredentailFenceQueueContinue)continueBlock
{
    QCloudCredential* credential = [QCloudCredential new];
    credential.secretID = [NSString getSafeStrWithStr:tmpSecretId showNull:@""];
    credential.secretKey = [NSString getSafeStrWithStr:tmpSecretKey showNull:@""];
    credential.token = [NSString getSafeStrWithStr:sessionToken showNull:@""];
    
    NSDate *currentDate = [NSDate date];
    credential.startDate = currentDate;
    int hours = 1;    // n小时后
    credential.experationDate = [currentDate initWithTimeIntervalSinceNow:hours * 60 * 60];;
    
    QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc] initWithCredential:credential];
    continueBlock(creator, nil);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self setupUI];
//    });
}
#pragma QCloudSignatureProvider
- (void) signatureWithFields:(QCloudSignatureFields*)fileds
                     request:(QCloudBizHTTPRequest*)request
                  urlRequest:(NSMutableURLRequest*)urlRequst
                   compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock
{
    [self.credentialFenceQueue performAction:^(QCloudAuthentationCreator *creator, NSError *error) {
        if (error) {
            continueBlock(nil, error);
        } else {
            QCloudSignature* signature =  [creator signatureForData:urlRequst];
            continueBlock(signature, nil);
        }
    }];
}

- (void) setupCOSXMLShareService {
    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
    configuration.appID = [self getCosAppId];
    configuration.signatureProvider = self;
    QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
    endpoint.regionName = [NSString getSafeStrWithStr:region showNull:@"re-beijing"];
//    endpoint.serviceName = @"";
    configuration.endpoint = endpoint;
    
    [QCloudCOSXMLService registerDefaultCOSXMLWithConfiguration:configuration];
    [QCloudCOSTransferMangerService registerDefaultCOSTransferMangerWithConfiguration:configuration];
}

#pragma mark =========== 初始化UI ===========
-(void)setupUI{
    [self hideProgressHUD];
    
    UITableView *uploadTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, C_SCREEN_WIDTH, C_SCREEN_HEIGHT) style:UITableViewStylePlain];
    uploadTableView.backgroundColor = [UIColor colorWithRed:246.f/255.f green:247.f/255.f blue:249.f/255.f alpha:1];
    uploadTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    uploadTableView.dataSource = self;
    uploadTableView.delegate = self;
    uploadTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    [uploadTableView registerClass:[CustomUploadCell class] forCellReuseIdentifier:@"CustomUploadCell"];
    [self.view addSubview:uploadTableView];
    _uploadTableView = uploadTableView;
}

#pragma mark - action
- (void)cancel:(UIButton *)button
{
    __weak __typeof__(self) weakSelf = self;
//    if (self.resultArray.count != self.uploadArray.count) {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"资源正在上传,请稍后"] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
//        [alertView show];
//        return;
//    }
//    if (self.resultArray.count == self.uploadArray.count) {
//        [self.navigationController dismissViewControllerAnimated:YES completion:^{
//            if (weakSelf.doneButtonClickBlock) {
//                weakSelf.doneButtonClickBlock(weakSelf.resultArray);
//            }
//        }];
//        return;
//    }
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.backButtonClickBlock) {
            weakSelf.backButtonClickBlock();
        }
    }];
}

- (void)okBtn:(UIButton *)button
{
//    if (self.resultArray.count != self.uploadArray.count) {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"资源未上传完成,无法提交"] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
//        [alertView show];
//        return;
//    }
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (self.doneButtonClickBlock) {
            self.doneButtonClickBlock(self.resultArray);
        }
    }];
    self.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - 网络请求接口

/**
 获取用户标识
 */
-(void)getTicketMsg {
    NSString *ticket = [[NSUserDefaults standardUserDefaults] objectForKey:ticketKey_plugin];
    
    __weak __typeof__(self) weakSelf = self;
    if ([ticket isEqualToString:@""]) {
        [self showProgressHUD];
        [TCHttpUtil asyncSendHttpRequest:@"user/loginTest" httpServerAddr:[[NSUserDefaults standardUserDefaults] objectForKey:serverUrlKey_plugin] HTTPMethod:@"POST" param:@{@"phone":@"18627795677",@"pwd":@"6234ef5192de321f27b0d7b18ba02f8166af27df",@"type":[NSNumber numberWithInt:2]} handler:^(int result, NSDictionary *resultDict) {
            if (result == 0 && resultDict){
                NSDictionary *dataDict = resultDict;
                if (dataDict) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSString getSafeStrWithStr:dataDict[@"ticket"] showNull:@""] forKey:ticketKey_plugin];
                    
                    if ([self isAudio_ImgFileUpload]) { //如果是图片、音频上传，则使用腾讯云cos服务
                        [self getCosAuthorMsgCallback:^(NSString *authorization, NSString *errorStr) {
                            if (![[NSString getSafeStrWithStr:authorization showNull:@""] isEqualToString:@""]) {
                                [self initCosData];
                                [self getMediasMsg];
                                [self performSelector:@selector(setupUI) withObject:nil afterDelay:3];
                                
                            }else{
                                [self hideProgressHUD];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"cos签名获取失败，无法上传"] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                                    [alertView show];
                                });
                                weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
                                weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
                                weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
                                return ;
                            }
                        }];
                    }else{
                        [self hideProgressHUD];
                        [self setupUI];
                    }
                    return ;
                }
            }
            [self hideProgressHUD];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"用户标识获取失败，无法上传"] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alertView show];
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
            
        }];
    }else{
        if ([self isAudio_ImgFileUpload]) { //如果是图片、音频上传，则使用腾讯云cos服务
            [self getCosAuthorMsgCallback:^(NSString *authorization, NSString *errorStr) {
                if (![[NSString getSafeStrWithStr:authorization showNull:@""] isEqualToString:@""]) {
                    [self initCosData];
                    [self getMediasMsg];
                    [self performSelector:@selector(setupUI) withObject:nil afterDelay:3];
                    
                }else{
                    [self hideProgressHUD];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"cos签名获取失败，无法上传"] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                        [alertView show];
                    });
                    weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
                    weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
                    weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
                    return ;
                }
            }];
        }else{
            [self hideProgressHUD];
            [self setupUI];
        }
    }
    
}

/**
 获取云存储cos签名信息
 */
-(void)getCosAuthorMsgCallback:(void (^)(NSString *authorization, NSString *errorStr))callback {
    __weak __typeof__(self) weakSelf = self;
    [self getDealAudio_ImageMsgCallback:^(NSArray *audio_imgArray, NSString *errorStr) {
        if (audio_imgArray && audio_imgArray.count>0) {
            NSNumber *orgId = [[NSUserDefaults standardUserDefaults] objectForKey:orgIdKey_plugin];
            [TCHttpUtil asyncSendHttpRequest:@"fileUpload/getAuthorization" httpServerAddr:[[NSUserDefaults standardUserDefaults] objectForKey:serverUrlKey_plugin] HTTPMethod:@"POST" param:@{@"orgId":orgId,@"files":audio_imgArray} handler:^(int result, NSDictionary *resultDict) {
                if (result == 0 && resultDict){
                    self->bucket = [NSString getSafeStrWithStr:resultDict[@"bucket"] showNull:@""];
                    self->region = [NSString getSafeStrWithStr:resultDict[@"region"] showNull:@""];
                    self->authorization = [NSString getSafeStrWithStr:resultDict[@"authorization"] showNull:@""];
                    self->keysArray = [NSArray arrayWithArray:resultDict[@"keys"]];
                    self->mediaIds = [NSArray arrayWithArray:resultDict[@"mediaIds"]];
                    self->sessionToken = [NSString getSafeStrWithStr:resultDict[@"sessionToken"] showNull:@""];//token
                    self->tmpSecretId = [NSString getSafeStrWithStr:resultDict[@"tmpSecretId"] showNull:@""]; //tmpSecretId
                    self->tmpSecretKey = [NSString getSafeStrWithStr:resultDict[@"tmpSecretKey"] showNull:@""];//tmpSecretKey
                    
                    if (callback) {
                        callback(self->authorization, @"");
                    }
                    
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"cos签名获取失败,错误码：%d",result] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                        [alertView show];
                    });
                    weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
                    weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
                    weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
                }
            }];
        }
    }];
}

/**
 获取媒体对象列表
 */
-(void)getMediasMsg {
    __weak __typeof__(self) weakSelf = self;
    [TCHttpUtil asyncSendHttpRequest:@"fileUpload/getMedias" httpServerAddr:[[NSUserDefaults standardUserDefaults] objectForKey:serverUrlKey_plugin] HTTPMethod:@"POST" param:@{@"mediaIds":mediaIds} handler:^(int result, NSDictionary *resultDict) {
        if (result == 0 && resultDict){
            if ([resultDict[@"medias"] isKindOfClass:[NSArray class]]) {
                self->mediasArray = [NSMutableArray arrayWithArray:resultDict[@"medias"]];
                return ;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[NSString stringWithFormat:@"媒体对象列表获取失败,错误码：%d",result] delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alertView show];
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
        });
    }];
}

#pragma mark - 私有方法
/**
 获取处理后的文件（图片音频）信息（数组）
 
 @param callback 回调方法
 */
-(void)getDealAudio_ImageMsgCallback:(void (^)(NSArray *audio_imgArray, NSString *errorStr))callback {
    if (self.uploadArray.count>0) {
        NSMutableArray *newFileArray = [NSMutableArray array];
        
        LFResultObject *result = self.uploadArray[0];
        if ([result isKindOfClass:[LFResultImage class]]) {
            
            //将获取的图片写入沙盒中，获取对应图片路径、名称
            for (NSInteger i = 0; i < self.uploadArray.count; i++) {
                LFResultObject *result = self.uploadArray[i];
                if ([result isKindOfClass:[LFResultImage class]]) {
                    NSMutableDictionary *fileMsg = [NSMutableDictionary dictionary];
                    [fileMsg setObject:[NSNumber numberWithInt:1] forKey:@"type"];
                    
                    LFResultImage *resultImage = (LFResultImage *)result;
                    
                    NSString* tempPath = QCloudTempFilePathWithExtension(@"jpg");
                    NSData* data = [self imageWithCompressImage:resultImage.originalImage];
                    [data writeToFile:tempPath atomically:YES];
                    
                    [fileMsg setObject:[NSString getSafeStrWithStr:[tempPath lastPathComponent] showNull:[NSString stringWithFormat:@"%@.jpg",[NSString uuidString]]] forKey:@"name"];
                    [fileMsg setObject:tempPath forKey:@"url"];
                    
                    [newFileArray addObject:fileMsg];
                    
                    if (newFileArray.count == self.uploadArray.count) {
                        if (callback) {
                            if (imgFileArray) {
                                [imgFileArray removeAllObjects];
                            }
                            imgFileArray = [NSMutableArray arrayWithArray:newFileArray];
                            callback(newFileArray, @"");
                            return;
                        }
                    }
                }
            }
        }else{
            if (_isAudio) {
                
                for (NSInteger i = 0; i < self.uploadArray.count; i++) {
                    LFResultObject *result = self.uploadArray[i];
                    
                    NSMutableDictionary *fileMsg = [NSMutableDictionary dictionary];
                    
                    LFResultVideo *audioObj = (LFResultVideo *)result;
                    [fileMsg setObject:[NSNumber numberWithInt:2] forKey:@"type"];
                    [fileMsg setObject:[NSString getSafeStrWithStr:audioObj.info.name showNull:[NSString stringWithFormat:@"%@.amr",[NSString uuidString]]] forKey:@"name"];
                    [newFileArray addObject:fileMsg];
                }
                
                if (newFileArray.count == self.uploadArray.count) {
                    if (callback) {
                        callback(newFileArray, @"");
                        return;
                    }
                }
            }
        }
    }
}

-(NSString *)getCosAppId {
    NSString *appid = [[NSUserDefaults standardUserDefaults] objectForKey:appIdKey_plugin];
    if ([appid isEqualToString:@""]) {
        NSArray *array = [bucket componentsSeparatedByString:@"-"];
        if (array.count == 2) {
            return [NSString getSafeStrWithStr:array[1] showNull:@""];
        }
        return @"";
    }
    return appid;
}

- (NSData *)imageWithCompressImage:(UIImage *)image {
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    float value = data.length/1024;
    float maxSize = 2*1024;
    if (value>maxSize) {
        for (int i=9; i>0; --i) {
            float compressionQuality = i/10.0;
            NSData *data1 = UIImageJPEGRepresentation(image, compressionQuality);
            value = data1.length/1024;
            if (value<maxSize) {
                data = data1;
                break;
            }
        }
    }
    
    return data;
}

/**
 是否是上传图片、音频文件

 @return 是否
 */
-(BOOL) isAudio_ImgFileUpload {
    BOOL isAudo_Img = NO;
    if (self.uploadArray.count>0) {
        LFResultObject *result = self.uploadArray[0];
        if ([result isKindOfClass:[LFResultImage class]]) {
            isAudo_Img = YES;
        }else{
            if (_isAudio) {
                isAudo_Img = YES;
            }
        }
    }
    
    return isAudo_Img;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark ===============UITableViewDelegate===============
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.uploadArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identifier = [NSString stringWithFormat:@"cell%ld%ld", (long)indexPath.section, (long)indexPath.row];
    CustomUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell==nil) {
        cell = [[CustomUploadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.tag = indexPath.row;
    __weak __typeof__(self) weakSelf = self;
    cell.videoCompletionBlock = ^(TXPublishResult * _Nullable result, NSString * _Nonnull mediaId, NSInteger index, NSString * _Nonnull errorStr) {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
        if (result) {
            [resultDic setObject:[NSString getSafeStrWithStr:mediaId showNull:@""] forKey:@"mediaId"];
            [resultDic setObject:[NSString getSafeStrWithStr:result.videoId showNull:@""] forKey:@"fileId"];
            [resultDic setObject:[NSString getSafeStrWithStr:result.videoURL showNull:@""] forKey:@"videoUrl"];
            [resultDic setObject:[NSString getSafeStrWithStr:[result.videoURL lastPathComponent] showNull:@""] forKey:@"videoFileName"];
            [resultDic setObject:[NSNumber numberWithInt:0] forKey:@"mediaType"];
            [weakSelf.uploadStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:2]];
        }else{
            [weakSelf.uploadStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:3]];
        }
        [weakSelf.resultArray addObject:resultDic];
        if (weakSelf.resultArray.count < weakSelf.uploadArray.count) {
            weakSelf.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = NO;
            weakSelf.navigationItem.rightBarButtonItem.enabled = NO;
            weakSelf.navigationItem.rightBarButtonItem.customView.alpha = 0.5;
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = NO;
            weakSelf.navigationItem.leftBarButtonItem.enabled = NO;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 0.5;
        }else{
            weakSelf.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            weakSelf.navigationItem.rightBarButtonItem.customView.alpha = 1;
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
        }
    };
    cell.photo_AudioCompletionBlock = ^(QCloudUploadObjectResult * _Nullable result, NSInteger index, NSString * _Nonnull errorStr) {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
        if (result) {
            [weakSelf.uploadStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:2]];
        }else{
            [weakSelf.uploadStatusArray replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:3]];
        }
        [weakSelf.resultArray addObject:resultDic];
        if (weakSelf.resultArray.count < weakSelf.uploadArray.count) {
            weakSelf.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = NO;
            weakSelf.navigationItem.rightBarButtonItem.enabled = NO;
            weakSelf.navigationItem.rightBarButtonItem.customView.alpha = 0.5;
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = NO;
            weakSelf.navigationItem.leftBarButtonItem.enabled = NO;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 0.5;
        }else{
            weakSelf.navigationItem.rightBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            weakSelf.navigationItem.rightBarButtonItem.customView.alpha = 1;
            weakSelf.navigationItem.leftBarButtonItem.customView.userInteractionEnabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.enabled = YES;
            weakSelf.navigationItem.leftBarButtonItem.customView.alpha = 1;
            [weakSelf.resultArray removeAllObjects];
            weakSelf.resultArray = [self->mediasArray mutableCopy];
        }
    };
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSInteger sendStaus = [self.uploadStatusArray[indexPath.row] integerValue];
    if (sendStaus == 1 || sendStaus == 2 || sendStaus == 3) {
        return cell;
    }
    LFResultObject *result = self.uploadArray[indexPath.row];
    if ([result isKindOfClass:[LFResultImage class]]) {
        NSDictionary *imgDic = imgFileArray[indexPath.row];
        [cell setCellMsgWithResultImage:imgDic cosMsg:@{@"bucket":[NSString getSafeStrWithStr:bucket showNull:@""],
                                                        @"region":[NSString getSafeStrWithStr:region showNull:@""],
                                                        @"authorization":[NSString getSafeStrWithStr:authorization showNull:@""],
                                                        @"keys":keysArray
                                                        }];
    }else{
        if (_isAudio) {
            [cell setCellMsgWithResultAudio:(LFResultVideo *)result cosMsg:@{@"bucket":[NSString getSafeStrWithStr:bucket showNull:@""],
                                                                             @"region":[NSString getSafeStrWithStr:region showNull:@""],
                                                                             @"authorization":[NSString getSafeStrWithStr:authorization showNull:@""],
                                                                             @"keys":keysArray
                                                                             }];
        }else{
            [cell setCellMsgWithResultVideo:(LFResultVideo *)result];
        }
    }
    [weakSelf.uploadStatusArray replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithInt:1]];
    
    return cell;
}

#pragma mark ===============UITableViewDataSource===============

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [CustomUploadCell cellHeight];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


#pragma mark - private
- (void)showProgressHUDText:(NSString *)text isTop:(BOOL)isTop needProcess:(BOOL)needProcess
{
    [self hideProgressHUD];
    
    if (!_progressHUD) {
        _progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        [_progressHUD setBackgroundColor:[UIColor clearColor]];
        _progressHUD.frame = [UIScreen mainScreen].bounds;
        
        _HUDContainer = [[UIView alloc] init];
        _HUDContainer.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width - 120) / 2, ([[UIScreen mainScreen] bounds].size.height - 90) / 2, 120, 90);
        _HUDContainer.layer.cornerRadius = 8;
        _HUDContainer.clipsToBounds = YES;
        _HUDContainer.backgroundColor = [UIColor darkGrayColor];
        _HUDContainer.alpha = 0.7;
        
        _HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        
        _HUDLabel = [[UILabel alloc] init];
        _HUDLabel.frame = CGRectMake(0,40, 120, 50);
        _HUDLabel.textAlignment = NSTextAlignmentCenter;
        _HUDLabel.font = [UIFont systemFontOfSize:15];
        _HUDLabel.textColor = [UIColor whiteColor];
        
        [_HUDContainer addSubview:_HUDLabel];
        [_HUDContainer addSubview:_HUDIndicatorView];
        [_progressHUD addSubview:_HUDContainer];
    }
    
    _HUDLabel.text = text;
    
    [_HUDIndicatorView startAnimating];
    UIView *view = isTop ? [[UIApplication sharedApplication] keyWindow] : self.view;
    [view addSubview:_progressHUD];
}

- (void)showProgressHUDText:(NSString *)text
{
    [self showProgressHUDText:text isTop:NO needProcess:NO];
}

- (void)showProgressHUD
{
    [self showProgressHUDText:@"处理中" isTop:NO needProcess:NO];
}

- (void)hideProgressHUD {
    if (_progressHUD) {
        [_HUDIndicatorView stopAnimating];
        [_progressHUD removeFromSuperview];
    }
}

- (void)showProgressVideoHUD
{
    [self showProgressHUDText:nil isTop:NO needProcess:YES];
}


@end
