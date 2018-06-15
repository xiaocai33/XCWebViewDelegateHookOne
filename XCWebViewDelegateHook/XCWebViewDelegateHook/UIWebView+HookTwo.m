//
//  UIWebView+HookTwo.m
//  XCWebViewDelegateHook
//
//  Created by Cai,Tengyuan on 2018/6/15.
//  Copyright © 2018年 Cai,Tengyuan. All rights reserved.
//

#import "UIWebView+HookTwo.h"
#import <objc/runtime.h>

// webView代理方法所有的C方法实现
void (*origin_shouldStartLoadWithRequest)(id, SEL, UIWebView*, NSURLRequest*, UIWebViewNavigationType);
void (*origin_webViewDidStartLoad)(id, SEL, UIWebView*);
void (*origin_webViewDidFinishLoad)(id, SEL, UIWebView*);
void (*origin_didFailLoadWithError)(id, SEL, UIWebView*, NSError*);

// 自定义的代理方法实现(C语言方式)
void exchange_shouldStartLoadWithRequest(id self, SEL _cmd, UIWebView * webView , NSURLRequest * request, UIWebViewNavigationType navigationType){
    if (origin_shouldStartLoadWithRequest) {
        origin_shouldStartLoadWithRequest(self, _cmd, webView, request, navigationType);
    }
    NSLog(@"--------exchange_shouldStartLoadWithRequest---------");
}

void exchange_webViewDidStartLoad(id self, SEL _cmd, UIWebView *webView){
    if (origin_webViewDidStartLoad) {
        origin_webViewDidStartLoad(self, _cmd, webView);
    }
    NSLog(@"--------exchange_webViewDidStartLoad---------");
}

void exchange_webViewDidFinishLoad(id self, SEL _cmd, UIWebView *webView){
    if (origin_webViewDidFinishLoad) {
        origin_webViewDidFinishLoad(self, _cmd, webView);
    }
    NSLog(@"--------exchange_webViewDidFinishLoad---------");
}

void exchange_didFailLoadWithError(id self, SEL _cmd, UIWebView *webView, NSError *error){
    if (origin_didFailLoadWithError) {
        origin_didFailLoadWithError(self, _cmd, webView, error);
    }
    NSLog(@"--------exchange_didFailLoadWithError---------");
}

static NSMutableArray *arrayM;

// 注: 这种方法 如果一个界面由两个webView则这种方法会有循环引用的问题, 或者第二个带有webView的界面第二次进入
@implementation UIWebView (HookTwo)

//+ (void)load{
//    Method originalMethod = class_getInstanceMethod([UIWebView class], @selector(setDelegate:));
//    Method swizzledMethod = class_getInstanceMethod([UIWebView class], @selector(hook_setDelegate:));
//    method_exchangeImplementations(originalMethod, swizzledMethod);
//    arrayM = [NSMutableArray array];
//}
//
//- (void)hook_setDelegate:(id<UIWebViewDelegate>)delegate{
//    [self hook_setDelegate:delegate];
//    // 获取delegate实际的类 (每个代理类只能调用一次 否则就会循环引用)
//    Class aClass = [delegate class];
//    NSLog(@"delegateClass = %@", aClass);
//    if ([arrayM containsObject:aClass]) {
//        NSLog(@"return class = %@", aClass);
//        return;
//    }else{
//        [arrayM addObject:aClass];
//    }
//    
//    // 保留原方法 并将新方法的IMP指向原方法
//    [self exchangeDelegateOfOriginClass:aClass];
//}

/**交互原类中相关的代理方法*/
- (void)exchangeDelegateOfOriginClass:(Class)cls{
    // shouldStartLoadWithRequest
    SEL originSel = @selector(webView:shouldStartLoadWithRequest:navigationType:);
    Method originMethod = class_getInstanceMethod(cls, originSel);
    origin_shouldStartLoadWithRequest = (void*)method_getImplementation(originMethod);
//    NSLog(@"%s - %s - %s - %s",@encode(BOOL),@encode(UIWebView),@encode(NSURLRequest),@encode(UIWebViewNavigationType));
    // B返回bool值, @表示id类型, :表示方法类型, b表示long long类型, 所以 B(返回值)@:@(第一个参数)@(第二个参数)b(第三个参数)
    if (!class_addMethod(cls, originSel, (IMP)exchange_shouldStartLoadWithRequest, "B@:@@b")) {// 没有添加成功, 表示方法已经在原类中存在了
        method_setImplementation(originMethod, (IMP)exchange_shouldStartLoadWithRequest);
    }
    
    // webViewDidStartLoad
    SEL originSelStartLoad = @selector(webViewDidStartLoad:);
    Method originMethodStartLoad = class_getInstanceMethod(cls, originSelStartLoad);
    origin_webViewDidStartLoad = (void*)method_getImplementation(originMethodStartLoad);
    // v表示无返回值, @表示id类型, v(返回值)@:@(第一个参数)
    if (!class_addMethod(cls, originSelStartLoad, (IMP)exchange_webViewDidStartLoad, "v@:@")) {// 没有添加成功, 表示方法已经在原类中存在了
        method_setImplementation(originMethodStartLoad, (IMP)exchange_webViewDidStartLoad);
    }
    
    // webViewDidFinishLoad
    SEL originSelFinishLoad = @selector(webViewDidFinishLoad:);
    Method originMethodFinishLoad = class_getInstanceMethod(cls, originSelFinishLoad);
    origin_webViewDidFinishLoad = (void *)method_getImplementation(originMethodFinishLoad);
    // v表示无返回值, @表示id类型, v(返回值)@:@(第一个参数)
    if (!class_addMethod(cls, originSelFinishLoad, (IMP)exchange_webViewDidFinishLoad, "v@:@")) {// 没有添加成功, 表示方法已经在原类中存在了
        method_setImplementation(originMethodFinishLoad, (IMP)exchange_webViewDidFinishLoad);
    }
    
    
    // didFailLoadWithError
    SEL originSelFailLoad = @selector(webView:didFailLoadWithError:);
    Method originMethodFailLoad = class_getInstanceMethod(cls, originSelFailLoad);
    origin_didFailLoadWithError = (void *)method_getImplementation(originMethodFailLoad);
    // v表示无返回值, @表示id类型, v(返回值)@:@(第一个参数)
    if (!class_addMethod(cls, originSelFailLoad, (IMP)exchange_didFailLoadWithError, "v@:@@")) {// 没有添加成功, 表示方法已经在原类中存在了
        method_setImplementation(originMethodFailLoad, (IMP)exchange_didFailLoadWithError);
    }
}

//- (void)exchange:(Class)cls{
//    SEL originSel = @selector(webView:shouldStartLoadWithRequest:navigationType:);
//    Method originMethod = class_getInstanceMethod(cls, originSel);
//    // B返回bool值, @表示id类型, :表示方法类型, b表示long long类型, 所以 B(返回值)@:@(第一个参数)@(第二个参数)b(第三个参数)
//    if (!class_addMethod(cls, originSel, (IMP)exchange_shouldStartLoadWithRequest, "B@:@@b")) {// 没有添加成功, 表示方法已经在原类中存在了
//        method_setImplementation(originMethod, (IMP)exchange_shouldStartLoadWithRequest);
//    }
//}

/**
 注: 参考博客地址 https://blog.csdn.net/shjsir/article/details/52625415
    class_addMethod 函数
     BOOL: 返回值，yes-------方法添加成功     no--------方法添加失败
     Class cls: 将要给添加方法的类，传的类型 ［类名  class］
     SEL name: 将要添加的方法名，传的类型   @selector(方法名)
     IMP imp：实现这个方法的函数 ，传的类型   1，C语言写法：（IMP）方法名    2，OC的写法：class_getMethodImplementation(self,@selector(方法名：))
     "v@:@"：v表示是添加方法无返回值,     @表示是id(也就是要添加的类); ：表示添加的方法类型   @表示：参数类型
 
    class_addMethod(cls, originSelFailLoad, (IMP)exchange_didFailLoadWithError, "v@:@@")
    表示将exchange_didFailLoadWithError的IMP指针强制指向了originSelFailLoad这个的方法.
 */

@end
