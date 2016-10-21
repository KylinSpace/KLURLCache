//
//  KLURLCache.m
//  test
//
//  Created by kylin on 16/10/10.
//  Copyright © 2016年 Apple. All rights reserved.
//  简书地址 http://www.jianshu.com/p/9d2abe9131d4
//  GITHUB https://github.com/KylinSpace/KLURLCache.git
#import "KLURLCache.h"
#import "Util.h"
#import "Reachability.h"
@interface KLURLCache()
/**磁盘路径 */
@property (nonatomic,copy)NSString *diskPath;
/**文件管理者 */
@property (nonatomic,strong)NSFileManager *fileManager;
/**cachedUrlResponse */
@property (nonatomic,strong)NSCachedURLResponse *cacheUrlResponse;
/**response的请求其它的信息 */
@property (nonatomic,strong)NSMutableDictionary *responseInfoDict;
/** */
@property (nonatomic,strong) NSURLSessionDataTask *dataTask;
@end
static NSString *const UrlCaheFolder = @"URLCache";
static double const expireTime = 7;
@implementation KLURLCache

- (NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    
    return _fileManager;
}


// 重写初始化方法
- (instancetype)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path{
    if (self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path]) {
        
        if (!path) {
            _diskPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
            _responseInfoDict = [NSMutableDictionary  dictionaryWithCapacity:0];
        }else{
            _diskPath = path;
            
        }
    }
    return self;
}


// 删除所有的cache缓存
- (void)removeCachedResponseForRequest:(NSURLRequest *)request {
    [super removeCachedResponseForRequest:request];
    
    NSString *url = request.URL.absoluteString;
    NSString *fileName = [self cacheRequestFileName:url];
    NSString *otherInfoFileName = [self cacheRequestOtherInfoFileName:url];
    NSString *filePath = [self cacheFilePath:fileName];
    NSString *otherInfoPath = [self cacheFilePath:otherInfoFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
    [fileManager removeItemAtPath:otherInfoPath error:nil];
}
// 删除所有缓存
- (void)removeAllCachedResponses{
    [self deleteCacheFolder];
}

- (void)deleteCacheFolder {
    NSString *path = [NSString stringWithFormat:@"%@/%@", self.diskPath, UrlCaheFolder];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:nil];
}


// 生成独立路径
- (NSString *)cacheFilePath:(NSString *)file {
    NSString *path = [NSString stringWithFormat:@"%@/%@", self.diskPath, UrlCaheFolder];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        
    } else {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [NSString stringWithFormat:@"%@/%@", path, file];
}



// 判断是否是GET请求 只有GET请求才能缓存
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request{
    
    NSLog(@"%@",request.HTTPMethod);
    if ([request.HTTPMethod compare:@"GET"] != NSOrderedSame) {
    
         return [super cachedResponseForRequest:request];
       
    }else{
        return [self KL_CacheResponseDataFromRequest:request];
    }

}
- (NSString *)cacheRequestFileName:(NSString *)requestUrl {
    return [Util md5Hash:requestUrl];
}

- (NSString *)cacheRequestOtherInfoFileName:(NSString *)requestUrl {
    return [Util md5Hash:[NSString stringWithFormat:@"%@-otherInfo", requestUrl]];
}

// 处理请求的数据
- (NSCachedURLResponse *)KL_CacheResponseDataFromRequest:(NSURLRequest *)request{

    
    NSLog(@"请求的数据是---%@",request.mainDocumentURL);
    NSString *url = request.URL.absoluteString;
    NSString *fileName = [self cacheRequestFileName:url];
    NSString *otherInfoFileName = [self cacheRequestOtherInfoFileName:url];
    NSString *filePath = [self cacheFilePath:fileName];
    NSString *otherInfoPath = [self cacheFilePath:otherInfoFileName];
    NSDate *date = [NSDate date];
    // 如果请求的URL存在就返回缓存的数据
    if ([self.fileManager fileExistsAtPath:filePath]) {
        
        if ([self isExpireCahceWithCreateTime:otherInfoPath]) { // 过期判断
            NSLog(@"data from Cache\n......地址是----%@",request.URL);
           NSDictionary *otherInfo = [[NSDictionary alloc]initWithContentsOfFile:otherInfoPath];
            NSData *cacheData = [NSData dataWithContentsOfFile:filePath];
            
            NSURLResponse *response = [[NSURLResponse alloc]initWithURL:request.URL MIMEType:[otherInfo objectForKey:@"MIMEType"] expectedContentLength:cacheData.length textEncodingName:[otherInfo objectForKey:@"textEncodingName"]];
            
            NSCachedURLResponse *cacheUrlResponse = [[NSCachedURLResponse alloc]initWithResponse:response data:cacheData];
            
            return cacheUrlResponse;
    
        }else{
            [self.fileManager removeItemAtPath:filePath error:nil];
            [self.fileManager removeItemAtPath:otherInfoPath error:nil];
        }

    }
    
    
//    if (![[AFNetworkReachabilityManager sharedManager]isReachable]) { // 网络不可用时
//        
//        return nil;
//    }
    
    if (![Reachability networkAvailable]) { // 网络不可用时
        return nil;
    }
    
    __block NSCachedURLResponse *cachedResponse = nil;
    
    BOOL isExistFile = [self.responseInfoDict objectForKey:fileName]; //
 
        if (!isExistFile) { // 文件没有存在就执行下面代码

            [self.responseInfoDict setValue:[NSNumber numberWithBool:TRUE] forKey:fileName];
           
            NSLog(@"data from request\n地址是------%@",request.URL);
            
             NSURLSession *session = [NSURLSession sharedSession];
             NSURLSessionTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                if (response && data) {
                   [self.responseInfoDict removeObjectForKey:fileName];
                }
                
                if (error) {
                    cachedResponse = nil;
                }
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [date timeIntervalSince1970]], @"time",response.MIMEType,@"MIMEType",response.textEncodingName,@"textEncodingName" ,nil];
         
                [dict writeToFile:otherInfoPath atomically:YES];
                 
                [data writeToFile:filePath atomically:YES];
                cachedResponse = [[NSCachedURLResponse alloc]initWithResponse:response data:data];
                
            }];
            
            [dataTask resume];
            return cachedResponse;
        }
    
    return nil;
}


// 获取时间差 超过七天就重新加载
- (BOOL)isExpireCahceWithCreateTime:(NSString *)infoPath{
    
    NSDictionary *otherInfoDict = [NSDictionary dictionaryWithContentsOfFile:infoPath];
   
    NSTimeInterval createTime = [[otherInfoDict objectForKey:@"time"] intValue];
    
    NSDate *nowDate = [NSDate date];
    
    NSDate *oldDate = [NSDate dateWithTimeIntervalSince1970:createTime];
    
    NSTimeInterval time = [nowDate timeIntervalSinceDate:oldDate];
    
    if (time > expireTime) {
       return YES;
    }else{
        return NO;
    }
    
}
- (void)dealloc{
    [_dataTask cancel];
}
@end
