//
//  BaiduLocation.h
//  App_iOS
//
//  Created by Dafiger on 16/12/15.
//  Copyright © 2016年 wpf. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BaiduMapAPI_Base/BMKBaseComponent.h>//引入base相关所有的头文件
#import <BaiduMapAPI_Location/BMKLocationComponent.h>//引入定位功能所有的头文件
#import <BaiduMapAPI_Search/BMKSearchComponent.h>//引入检索功能所有的头文件
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>//引入计算工具所有的头文件
#import <BaiduMapAPI_Radar/BMKRadarComponent.h>//引入周边雷达功能所有的头文件
//#import <BaiduMapAPI_Cloud/BMKCloudSearchComponent.h>//引入云检索功能所有的头文件
#import <BaiduMapAPI_Map/BMKMapComponent.h>//引入地图功能所有的头文件
//#import <BaiduMapAPI_Map/BMKMapView.h>//只引入所需的单个头文件

@protocol BaiduLocationDelegate <NSObject>

@optional
// 0、授权失败
// 1、授权成功
- (void)workResult:(int)reslut msg:(NSString *)msg;

@end

@interface BaiduLocation : NSObject

@property (nonatomic, weak) id<BaiduLocationDelegate> delegate;
@property (nonatomic, assign) int workStatus;

@property (nonatomic, strong) NSString *locationStr;
@property (nonatomic, strong) NSString *addressMsgStr;
@property (nonatomic, strong) NSString *cityMsgStr;

@property (nonatomic, strong) NSString *userIdStr;
@property (nonatomic, strong) NSString *userNameStr;
@property (nonatomic, assign) BOOL isSingleUploadLocation;

#pragma mark - 获取单例
+ (BaiduLocation *)instance;

#pragma mark - 开始授权
- (void)startLBSAuth;

#pragma mark - 停止授权
- (void)stopLBSAuth;

#pragma mark - 开始定位
- (void)startLocationAction;

#pragma mark - 停止定位
- (void)stopLocationAction;

#pragma mark - 反向地理编码检索
// 经纬度为nil，就默认使用定位的
- (void)startReverseGeocoderWithWithLocation:(NSString *)locationString;

#pragma mark - 正向地理编码检索
- (void)startGeocoderWithCity:(NSString *)city
                      address:(NSString *)address;

#pragma mark - 比较两个经纬度之间的距离
- (float)compareLocation:(NSString *)str_first
                  second:(NSString *)str_second;

#pragma mark - 周边雷达
// userID可以为nil
- (void)startNearRadarManagerWithUserIdStr:(NSString *)userIdStr;

#pragma mark - 停止周边雷达
- (void)releaseManager;

#pragma mark - 单次上传个人的位置
// 经纬度为nil，就默认使用定位的, userName必填
- (void)uploadMyInfoWithUserName:(NSString *)userName
                     locationStr:(NSString *)locationStr;

#pragma mark - 开启自动上传位置
- (void)startAutoUplodaMyLocationWithUserName:(NSString *)userName;

#pragma mark - 停止自动上传位置
- (void)stopAutoUpload;

#pragma mark - 周边位置检索
// 经纬度为nil，就默认使用定位的
- (void)nearBySearchWithLocation:(NSString *)locationString
                        nearArea:(int)area
                       pageIndex:(int)pageIndex;

#pragma - 清除位置的功能
- (void)clearMyLocation;

#pragma - 检查定位开关
- (BOOL)checkLocation;

@end


//BaiduLocation *baiduLocation = [BaiduLocation instance];
//[[BaiduLocation instance] startLBSAuth];
//baiduLocation.delegate = self;

//#pragma mark - 百度定位代理方法
//- (void)locationResult:(int)reslut msg:(NSString *)msg
//{
//#ifdef App_Log
//    NSLog(@"%d, %@",reslut, msg);
//#endif
//    if (reslut == -1) {
//        // 定位授权出错
//        [MBProgressHUDTool showInView:self.view text:@"定位授权失败"];
//    }else if (reslut == 9) {
//        // 定位授权成功
//        // 1、准备开始定位
//        [[BaiduLocation instance] startLocationAction];
//        // 2、正向地理编码
//        // [[BaiduLocation instance] startGeocoderWithCity:@"上海市" address:@"浦东新区东方路1217号"];
//    }else if (reslut == 0) {
//        // 开始定位
//        [MBProgressHUDTool showInView:self.view text:@"定位中..." background:NO autoHide:NO];
//    }else if (reslut == 10) {
//        // 结束定位
//        [MBProgressHUDTool hideAllHudInView:self.view];
//    }else if (reslut == 1) {
//        // 定位成功
//        [MBProgressHUDTool showInView:self.view text:@"定位成功"];
//        // 1、使用反地理编码
//        // [[BaiduLocation instance] startReverseGeocoderWithWithLocation:nil];
//        // 2、使用周边雷达功能并上传位置
//        [[BaiduLocation instance] startNearRadarManagerWithUserIdStr:@"ID2017"];
//        // 单次上传位置
//        [[BaiduLocation instance] uploadMyInfoWithLocation:msg
//                                                  userName:@"用户名2017"];
//        // 开启自动上传位置，适当的时间关闭
//        // [[BaiduLocation instance] startAutoUplodaMyLocation];
//    }else if (reslut == 2) {
//        // 定位失败
//        [MBProgressHUDTool showInView:self.view text:@"定位失败"];
//    }else if (reslut == 3) {
//        // 获取地址成功，反地理编码成功
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"获取地址成功"];
//    }else if (reslut == 4) {
//        // 获取地址失败，反地理编码失败
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"获取地址失败"];
//    }else if (reslut == 5) {
//        // 获取坐标成功，理编码成功
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"获取坐标成功"];
//    }else if (reslut == 6) {
//        // 获取坐标失败，地理编码失败
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"获取坐标失败"];
//    }else if (reslut == 11) {
//        // 雷达周边，上传位置回调成功
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"上传位置回调成功"];
//        // 1.开始周边位置检索
//        // [[BaiduLocation instance] startNearRadarManagerWithUserIdStr:@"ID2017"];
//        [[BaiduLocation instance] nearBySearchWithLocation:nil];
//    }else if (reslut == 12) {
//        // 雷达周边，上传位置回调失败
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"上传位置回调失败"];
//    }else if (reslut == 13) {
//        // 周边位置检索回调成功
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"周边位置检索回调成功"];
//    }else if (reslut == 14) {
//        // 周边位置检索回调失败
//        [MBProgressHUDTool hideAllHudInView:self.view];
//        [MBProgressHUDTool showInView:self.view text:@"周边位置检索回调失败"];
//    }
//}
