//
//  TCHttpUtil.m
//  TXLiteAVDemo
//
//  Created by rushanting on 2017/11/10.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "TCHttpUtil.h"
#import <CommonCrypto/CommonDigest.h>

@implementation TCHttpUtil

+ (NSData *)dictionary2JsonData:(NSDictionary *)dict
{
    // 转成Json数据
    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if(error)
        {
            NSLog(@"[%@] Post Json Error", [self class]);
        }
        return data;
    }
    else
    {
        NSLog(@"[%@] Post Json is not valid", [self class]);
    }
    return nil;
}

+ (NSDictionary *)jsonData2Dictionary:(NSString *)jsonData
{
    if (jsonData == nil) {
        return nil;
    }
    NSData *data = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        NSLog(@"Json parse failed: %@", jsonData);
        return nil;
    }
    return dic;
}

+ (void)asyncSendHttpRequest:(NSString*)request
              httpServerAddr:(NSString *)httpServerAddr
                  HTTPMethod:(NSString *)HTTPMethod
                       param:(NSDictionary *)param
                     handler:(void (^)(int result, NSDictionary* resultDict))handler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString* strUrl = @"";
        if ([httpServerAddr isEqualToString:kHttpUGCServerAddr]) {
            NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
            UInt64 timestamp= (UInt64)[date timeIntervalSince1970];
            UInt64 msTimestamp = (UInt64)([date timeIntervalSince1970] * 1000);
            NSString *nonce = [self md5String:[NSString stringWithFormat:@"%llu",msTimestamp]];
            NSString *sig = [self md5String:[NSString stringWithFormat:@"%@%llu%@%@",UGCAppid,timestamp,nonce,UGCAppKey]];
            strUrl = [NSString stringWithFormat:@"%@/%@?timestamp=%llu&nonce=%@&sig=%@&appid=%@", httpServerAddr, request,timestamp,nonce,sig,UGCAppid];
        }else{
            strUrl = [NSString stringWithFormat:@"%@/%@", httpServerAddr, request];
        }
        
        NSURL *URL = [NSURL URLWithString:strUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        
        [request setHTTPMethod:HTTPMethod];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString getSafeStrWithStr:[[NSUserDefaults standardUserDefaults] objectForKey:ticketKey_plugin] showNull:@""] forHTTPHeaderField:@"ticket"];
        [request setTimeoutInterval:kHttpTimeout];
        
        NSError *error;
        NSData *body = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        [request setHTTPBody:body];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil)
            {
                NSLog(@"internalSendRequest failed，NSURLSessionDataTask return error code:%ld, des:%@", (long)[error code], [error description]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(kError_HttpError, nil);
                });
            }
            else
            {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary* resultDict = [TCHttpUtil jsonData2Dictionary:responseString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(0, resultDict);
                });
            }
        }];
        
        [task resume];
    });
}

+ (NSString *)md5String:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (uint32_t)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
    
}

@end
