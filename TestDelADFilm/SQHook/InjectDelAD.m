//
//  InjectDelAD.m
//  SQHook
//
//  Created by Sem on 2020/8/26.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "InjectDelAD.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
@implementation InjectDelAD
+(void)load{
//    NSLog(@"你好！!~!!!!!!!!~~~~~~~");
//    int count = _dyld_image_count();
//    for (int i =0; i<count; i++) {
//     const  char*  imageName = _dyld_get_image_name(i);
//        printf("name: %s \n",imageName);
//        
//    }
    Method initADView = class_getInstanceMethod(objc_getClass("SaveAllSentientBeingsABeforeOrEndPlayADView"), @selector(initWithCloseHandler:));
    method_exchangeImplementations(initADView, class_getInstanceMethod(self, @selector(initWithCloseHandlerHook:)));
    Method showHook = class_getClassMethod(objc_getClass("SaveAllSentientBeingsAForTheFirstTimeRedPacketView"), @selector(show));
    method_exchangeImplementations(showHook, class_getClassMethod(InjectDelAD.class, @selector(showNew)));
    
    Method showInPlayerView = class_getClassMethod(objc_getClass("SaveAllSentientBeingsAPlayPauseADView"), @selector(showInPlayerView:withModel:));
       method_exchangeImplementations(showInPlayerView, class_getClassMethod(InjectDelAD.class, @selector(showInPlayerViewNew:withModel:)));
}
+ (id)showInPlayerViewNew:(id)arg1 withModel:(id)arg2{
    return nil;
}
+(void)showNew{
    
}
-(instancetype)initWithCloseHandlerHook:(id)arg{
     NSLog(@"交换方法执行~~~~~~~~~!!!");
    return nil;
}
@end
