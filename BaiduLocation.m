//
//  BaiduLocation.m
//  App_iOS
//
//  Created by Dafiger on 16/12/15.
//  Copyright © 2016年 wpf. All rights reserved.
//

#import "BaiduLocation.h"


@interface BaiduLocation()<BMKGeneralDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, BMKRadarManagerDelegate, UIAlertViewDelegate>
{
    BMKMapManager *_mapManager;
    BMKLocationService *_locService;
    BMKGeoCodeSearch *_searcher;
    BMKRadarManager *_radarManager;
}
@end

@implementation BaiduLocation

#pragma mark - 获取单例
+ (BaiduLocation *)instance
{
    static dispatch_once_t predicate = 0;
    static BaiduLocation *instance = nil;
    dispatch_once( &predicate, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - 开始授权
- (void)startLBSAuth
{
    if (self.workStatus == 0) {
        _mapManager = [[BMKMapManager alloc] init];
        BOOL ret = [_mapManager start:BaiduLBSAK generalDelegate:self];
        if (!ret) {
            [self failLBSAuth];
        }
    }else {
        [self successLBSAuth];
    }
}

- (void)onGetNetworkState:(int)iError
{
    if (iError != 0) {
        [self failLBSAuth];
    }
}

- (void)onGetPermissionState:(int)iError
{
    if (iError != 0) {
        [self failLBSAuth];
    }else{
        [self successLBSAuth];
    }
}

#pragma mark - 停止授权
- (void)stopLBSAuth
{
    [_mapManager stop];
    _mapManager = nil;
}

#pragma mark - 授权失败
- (void)failLBSAuth
{
    [self stopLBSAuth];
    self.workStatus = 0;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：授权失败"];
    }
}

#pragma mark - 授权成功
- (void)successLBSAuth
{
    self.workStatus = 1;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：授权成功"];
    }
}

#pragma mark - 开始定位
- (void)startLocationAction
{
    self.workStatus = 2;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开始定位"];
    }
    _locService = [[BMKLocationService alloc] init];
    _locService.delegate = self;
    _locService.distanceFilter = 10.0f;
    _locService.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    [_locService startUserLocationService];
}

// 准备开始定位
- (void)willStartLocatingUser
{
    // NSSLog(@"百度地图准备开始定位");
}

// 处理方向变更信息
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    // NSSLog(@"百度地图定位目前方向：%@",userLocation.heading);
}

// 处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSString *codeStr = [NSString stringWithFormat:@"%f,%f",userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude];
    // NSSLog(@"百度地图定位的结果：%@",codeStr);
    self.locationStr = codeStr;
    
    self.workStatus = 3;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:codeStr];
    }
    // 停止定位
    [self stopLocationAction];
}

// 定位失败
- (void)didFailToLocateUserWithError:(NSError *)error
{
    [SVProgressHUD showInfoWithStatus:@"定位失败"];
    // NSSLog(@"百度地图定位失败的原因：%@",[error localizedDescription]);
    self.workStatus = 4;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：定位失败"];
    }
    // 停止定位
    [self stopLocationAction];
}

#pragma mark - 停止定位
- (void)stopLocationAction
{
    // NSSLog(@"百度地图开始停止定位");
    [_locService stopUserLocationService];
}

// 已经结束定位
- (void)didStopLocatingUser
{
    // NSSLog(@"百度地图已经结束定位");
    self.workStatus = 5;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：结束定位"];
    }
}

#pragma mark - 反向地理编码检索
- (void)startReverseGeocoderWithWithLocation:(NSString *)locationString
{
    NSArray *location_ary = @[];
    // 经纬度为空，就默认使用定位的
    if (locationString.length == 0 || locationString == nil) {
        location_ary = [self.locationStr componentsSeparatedByString:@","];
    }else{
        location_ary = [locationString componentsSeparatedByString:@","];
    }
    if (location_ary.count != 2) {
        return;
    }
    self.workStatus = 6;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开始反地理编码"];
    }
    
    // CLLocationCoordinate2D pt = (CLLocationCoordinate2D){lat, lon};
    CLLocationCoordinate2D pt = CLLocationCoordinate2DMake([location_ary[0] floatValue], [location_ary[1] floatValue]);
    
    //初始化检索对象
    _searcher =[[BMKGeoCodeSearch alloc] init];
    _searcher.delegate = self;
    
    BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
    reverseGeoCodeSearchOption.reverseGeoPoint = pt;
    BOOL flag = [_searcher reverseGeoCode:reverseGeoCodeSearchOption];
    if(flag) {
        // NSSLog(@"百度地图反地理编码检索发送成功");
    }else {
        // NSSLog(@"百度地图反地理编码检索发送失败");
        _searcher.delegate = nil;
        self.workStatus = 7;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：反地理编码失败"];
        }
    }
}

-(void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher
                          result:(BMKReverseGeoCodeResult *)result
                       errorCode:(BMKSearchErrorCode)error
{
    // 停止地理编码
    _searcher.delegate = nil;
    if (error == BMK_SEARCH_NO_ERROR) {
        // NSSLog(@"百度地图反地理编码检索成功");
        self.addressMsgStr = result.address;
        self.cityMsgStr = result.addressDetail.city;

//        BMKAddressComponent *addressDetail = result.addressDetail;
//        NSSLog(@"地址详情-->:%@ %@ %@ %@ %@",addressDetail.province,addressDetail.city,addressDetail.district,addressDetail.streetName,addressDetail.streetNumber );
//        NSSLog(@"地址名称-->:%@",result.address);
//        NSSLog(@"商圈名称-->:%@",result.businessCircle);
//        NSSLog(@"地址坐标-->:%f, %f",result.location.latitude, result.location.longitude);
//        for (BMKPoiInfo *info in result.poiList) {
//            NSSLog(@"地址周边POI信息-->:%@",info.name);
//        }
        
        self.workStatus = 8;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:result.addressDetail.city];
        }
    }else {
        self.workStatus = 7;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：反地理编码失败"];
        }
    }
}

#pragma mark - 正向地理编码检索
- (void)startGeocoderWithCity:(NSString *)city
                      address:(NSString *)address
{
    if (city.length == 0 || city == nil || address.length == 0 || address == nil) {
        return;
    }
    self.workStatus = 9;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开始正向地理编码"];
    }
    //初始化检索对象
    _searcher =[[BMKGeoCodeSearch alloc] init];
    _searcher.delegate = self;
    BMKGeoCodeSearchOption *geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    geoCodeSearchOption.city= city;
    geoCodeSearchOption.address = address;
    BOOL flag = [_searcher geoCode:geoCodeSearchOption];
    if(flag) {
        // NSSLog(@"百度地图正向地理编码检索发送成功");
    }else {
        // NSSLog(@"百度地图正向地理编码检索发送失败");
        _searcher.delegate = nil;
        self.workStatus = 10;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：正向地理编码失败"];
        }
    }
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher
                    result:(BMKGeoCodeResult *)result
                 errorCode:(BMKSearchErrorCode)error
{
    // 停止地理编码
    _searcher.delegate = nil;
    if (error == BMK_SEARCH_NO_ERROR) {
        // NSSLog(@"百度地图正向地理编码检索成功");
        NSString *codeStr = [NSString stringWithFormat:@"%f,%f",result.location.latitude, result.location.longitude];
        self.locationStr = codeStr;
        
//        NSSLog(@"地理编码地址-->:%@",result.address);
//        NSSLog(@"地理编码地址-->:%f, %f",result.location.latitude, result.location.longitude);
        
        self.workStatus = 11;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:codeStr];
        }
    }else {
        // NSSLog(@"百度地图正向地理编码检索失败");
        self.workStatus = 10;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：正向地理编码失败"];
        }
    }
}

#pragma mark - 比较两个经纬度之间的距离
- (float)compareLocation:(NSString *)str_first
                   second:(NSString *)str_second
{
    NSArray *firstAry = [str_first componentsSeparatedByString:@","];
    NSArray *secondAry = [str_second componentsSeparatedByString:@","];
    if (firstAry.count != 2 || secondAry.count != 2) {
        return -1;
    }
    // 百度的计算方法
    BMKMapPoint point1 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake([firstAry[0] floatValue], [firstAry[1] floatValue]));
    BMKMapPoint point2 = BMKMapPointForCoordinate(CLLocationCoordinate2DMake([secondAry[0] floatValue], [secondAry[1] floatValue]));
    CLLocationDistance distance1 = BMKMetersBetweenMapPoints(point1,point2);

    // 苹果的计算方法
    CLLocation *location_first = [[CLLocation alloc] initWithLatitude:[firstAry[0] floatValue] longitude:[firstAry[1] floatValue]];
    CLLocation *location_second = [[CLLocation alloc] initWithLatitude:[secondAry[0] floatValue] longitude:[secondAry[1] floatValue]];
    CLLocationDistance distance2 = [location_first distanceFromLocation:location_second];
    
    NSSLog(@"百度地图计算两点之间的距离：%f，苹果方法计算结果：%f",distance1, distance2);
    return (float)distance1;
}

#pragma mark - 周边雷达功能
- (void)startNearRadarManagerWithUserIdStr:(NSString *)userIdStr
{
    _radarManager = [BMKRadarManager getRadarManagerInstance];
    // 不设置自动生成userId
    if (userIdStr.length == 0 || userIdStr == nil) {
        // 自动生成userID
    }else{
        self.userIdStr = userIdStr;
        _radarManager.userId = userIdStr;
    }
    // 获取自动上传时的位置信息
    [_radarManager addRadarManagerDelegate:self];
    
    self.workStatus = 12;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开启周边雷达"];
    }
//    [self clearMyLocation];
}

#pragma mark - 停止周边雷达功能
- (void)releaseManager
{
    // 不用需移除，否则影响内存释放
    [_radarManager removeRadarManagerDelegate:self];
    // 在不需要时，通过下边的方法使引用计数减1
    [BMKRadarManager releaseRadarManagerInstance];
    
    self.workStatus = 13;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：停止周边雷达"];
    }
}

#pragma mark - 单次上传个人位置信息
- (void)uploadMyInfoWithUserName:(NSString *)userName
                     locationStr:(NSString *)locationStr
{
    if (userName.length == 0 || userName == nil) {
        userName = @"匿名用户";
    }
    self.userNameStr = userName;
    NSArray *location_ary = @[];
    // 经纬度为空，就默认使用定位的
    if (locationStr.length == 0 || locationStr == nil) {
        location_ary = [self.locationStr componentsSeparatedByString:@","];
    }else{
        location_ary = [locationStr componentsSeparatedByString:@","];
    }
    if (location_ary.count != 2) {
        return;
    }
    
    self.workStatus = 14;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达开始单次上传个人位置"];
    }
    self.isSingleUploadLocation = YES;
    
    // 构造我的位置信息
    BMKRadarUploadInfo *myinfo = [[BMKRadarUploadInfo alloc] init];
    // 扩展信息
    myinfo.extInfo = userName;
    // 我的地理坐标
    myinfo.pt = CLLocationCoordinate2DMake([location_ary[0] floatValue], [location_ary[1] floatValue]);
    // 上传我的位置信息
    BOOL res = [_radarManager uploadInfoRequest:myinfo];
    if (res) {
        // NSSLog(@"百度地图周边雷达功能单次上传个人位置信息发送成功");
    } else {
        // NSSLog(@"百度地图周边雷达功能单次上传个人位置信息发送失败");
        self.workStatus = 15;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达单次上传个人位置结果：失败"];
        }
    }
}

// 上传个人位置信息回调结果
- (void)onGetRadarUploadResult:(BMKRadarErrorCode)error
{
    if (error == BMK_RADAR_NO_ERROR) {
        // NSSLog(@"百度地图周边雷达功能上传位置返回结果：成功");
        self.workStatus = 16;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            if (self.isSingleUploadLocation) {
                [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达单次上传个人位置结果：成功"];
            }else{
                [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达上传位置结果：成功"];
            }
        }
    }else {
        // NSSLog(@"百度地图周边雷达功能上传位置返回结果：失败");
        self.workStatus = 15;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            if (self.isSingleUploadLocation) {
                [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达单次上传个人位置结果：失败"];
            }else{
                [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达上传位置结果：失败"];
            }
        }
    }
    // 关闭代理，清理内存
//    if (self.isSingleUploadLocation) {
//        [self releaseManager];
//    }
}

#pragma mark - 开启自动上传位置信息功能
- (void)startAutoUplodaMyLocationWithUserName:(NSString *)userName
{
    if (userName.length == 0 || userName == nil) {
        userName = @"匿名用户";
    }
    self.userNameStr = userName;
    
    self.workStatus = 17;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达开启自动上传位置"];
    }
    self.isSingleUploadLocation = NO;
    
    // 启动自动上传用户位置信息，时间不能小于5s
    [_radarManager startAutoUpload:10];
    // 需要实现getRadarAutoUploadInfo获取我的位置信息
    // 可以设置自动关闭时间
    [self performSelector:@selector(stopAutoUpload)
               withObject:nil
               afterDelay:30.0];
}

- (BMKRadarUploadInfo *)getRadarAutoUploadInfo
{
    // 先开启定位功能，再实现上传功能；实现实时定位功能，userName必填
    // [self startLocationAction];
    NSArray *location_ary = [self.locationStr componentsSeparatedByString:@","];
    if (location_ary.count != 2) {
        return nil;
    }
    // 构造我的位置信息
    BMKRadarUploadInfo *myinfo = [[BMKRadarUploadInfo alloc] init];
    // 扩展信息
    myinfo.extInfo = self.userNameStr;
    // 我的地理坐标
    myinfo.pt = CLLocationCoordinate2DMake([location_ary[0] floatValue], [location_ary[1] floatValue]);
    return myinfo;
}

#pragma mark - 停止自动上传位置信息功能
- (void)stopAutoUpload
{
    [_radarManager stopAutoUpload];
    self.workStatus = 18;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：周边雷达停止自动上传位置"];
    }
    
//    // 关闭代理，清理内存
//    [self releaseManager];
}

#pragma mark - 周边位置检索
- (void)nearBySearchWithLocation:(NSString *)locationString
                        nearArea:(int)area
                       pageIndex:(int)pageIndex
{
    NSArray *location_ary = @[];
    if (locationString.length == 0 || locationString == nil) {
        location_ary = [self.locationStr componentsSeparatedByString:@","];
    }else{
        location_ary = [locationString componentsSeparatedByString:@","];
    }
    if (location_ary.count != 2) {
        return;
    }
    
    self.workStatus = 19;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开启周边位置检索"];
    }
    
    BMKRadarNearbySearchOption *option = [[BMKRadarNearbySearchOption alloc] init];
    // 检索半径，单位m
    option.radius = 100000;
    // 排序方式
    option.sortType = BMK_RADAR_SORT_TYPE_DISTANCE_FROM_NEAR_TO_FAR;
    // 检索中心点
    option.centerPt = CLLocationCoordinate2DMake([location_ary[0] floatValue], [location_ary[1] floatValue]);
    // 可以设置分页显示
    option.pageIndex = pageIndex;
    option.pageCapacity = 10;
    // 发起检索
    BOOL res = [_radarManager getRadarNearbySearchRequest:option];
    if (res) {
        // NSSLog(@"周边位置检索发送成功");
    } else {
        [SVProgressHUD showInfoWithStatus:@"同城好友检索失败"];
        self.workStatus = 20;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：周边位置检索：失败"];
        }
    }
}

- (void)onGetRadarNearbySearchResult:(BMKRadarNearbyResult *)result
                               error:(BMKRadarErrorCode)error
{
    // NSSLog(@"百度地图：周边位置检索返回回调结果：-->%d",error);
    if (error == BMK_RADAR_NO_ERROR) {
        NSSLog(@"周边人数总数:%ld",(long)result.totalNum);
        NSSLog(@"显示总页数:%ld",(long)result.pageNum);
        NSSLog(@"当前结果数:%ld",(long)result.currNum);
        NSSLog(@"当前页索引:%ld",(long)result.pageIndex);
        
        NSMutableArray *dataAry = [NSMutableArray array];
        
        for (BMKRadarNearbyInfo *info in result.infoList) {
            NSSLog(@"用户id-->:%@",info.userId);
            NSSLog(@"地址坐标-->:%f, %f",info.pt.latitude, info.pt.longitude);
            NSSLog(@"距离-->:%lu",(unsigned long)info.distance);
            NSSLog(@"扩展信息-->:%@",info.extInfo);
            NSSLog(@"设备类型-->:%@",info.mobileType);
            NSSLog(@"设备系统-->:%@",info.osType);
            NSSLog(@"时间戳-->:%f",info.timeStamp);
            
            NSString *localStr = [NSString stringWithFormat:@"%f,%f",info.pt.latitude, info.pt.longitude];
            NSString *distanceStr = [NSString stringWithFormat:@"%0.1f km",info.distance/1000.0];
            NSDictionary *tmpDic = @{@"userid":info.userId,
                                     @"local":localStr,
                                     @"distance":distanceStr,
                                     @"username":info.extInfo};
            [dataAry addObject:tmpDic];
        }
        
        NSDictionary *dataDic = @{@"totalperson":@(result.totalNum),
                                  @"allpage":@(result.pageNum),
                                  @"curperson":@(result.currNum),
                                  @"curindex":@(result.pageIndex),
                                  @"dataary":dataAry};
        NSString *dataJson = [ToolForCoding objectToJsonStr:dataDic];
        
        self.workStatus = 21;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            // @"百度地图：周边位置检索：成功"
            [_delegate workResult:self.workStatus msg:dataJson];
        }
    }else {
        [SVProgressHUD showInfoWithStatus:@"同城好友检索失败"];
        self.workStatus = 20;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：周边位置检索：失败"];
        }
    }
//    // 关闭代理，清理内存
//    [self releaseManager];
}

#pragma - 清除位置的功能
- (void)clearMyLocation
{
    [_radarManager clearMyInfoRequest];
    self.workStatus = 22;
    if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
        [_delegate workResult:self.workStatus msg:@"百度地图：开始清除位置"];
    }
}

- (void)onGetRadarClearMyInfoResult:(BMKRadarErrorCode) error
{
    if (error == 0) {
        self.workStatus = 23;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：清除位置：成功"];
        }
    }else{
        self.workStatus = 24;
        if ([_delegate respondsToSelector:@selector(workResult:msg:)]) {
            [_delegate workResult:self.workStatus msg:@"百度地图：清除位置：失败"];
        }
    }
}

#pragma - 检查定位开关
- (BOOL)checkLocation
{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"建议您开启定位服务" message:@"请在系统设置中开启定位服务(设置>隐私>定位服务>开启)" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置" , nil];
        alertView.delegate = self;
        alertView.tag = 1;
        [alertView show];
        return NO;
    }else{
        return YES;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            //跳转到定位权限页面
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if( [[UIApplication sharedApplication]canOpenURL:url] ) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
}

#pragma mark - 检查通知开关
- (void)checkNotification
{
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
    }
}


@end
