//
//  ViewController.m
//  DEMO
//
//  Created by kylin on 16/10/21.
//  Copyright © 2016年 kylin. All rights reserved.
//  简书地址 http://www.jianshu.com/p/9d2abe9131d4
//  GITHUB https://github.com/KylinSpace/KLURLCache.git
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]];
    [self.view addSubview:webView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
