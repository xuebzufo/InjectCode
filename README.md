# InjectCode
重签证书和代码注入
#如何预防此类代码注入[[IOS端监测APP被代码注入点击查看](https://www.jianshu.com/p/d7f29e912058)
]
##本文介绍的是ios的简单代码注入实现，这次的APP用大千影视，来实现代码注入去广告功能。这次代码注入主要分为几个部分：
1. 使用一台越狱手机，通过frida-ios-dump砸壳大千影视.app获得解密后的ipa包。

2. 通过mach-o view，reveal,hopper-disassembler等软件对该软件进行分析，找到相关方法，进行hook。

3. 编写sh脚本，重新签名app。

如何通过rida-ios-dump砸壳，网上有许多教程，十分简单，就不演示了。我们先编写下sh脚本，来将导出的mach-o重新签名变成自己的app。代码如下
```
# ${SRCROOT} 它是工程文件所在的目录
TEMP_PATH="${SRCROOT}/Temp"
#资源文件夹，我们提前在工程目录下新建一个APP文件夹，里面放ipa包
ASSETS_PATH="${SRCROOT}/APP"
#目标ipa包路径
TARGET_IPA_PATH="${ASSETS_PATH}/*.ipa"
#清空Temp文件夹
rm -rf "${SRCROOT}/Temp"
mkdir -p "${SRCROOT}/Temp"



#----------------------------------------
# 1. 解压IPA到Temp下
unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
# 拿到解压的临时的APP的路径
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app;echo "$1")
# echo "路径是:$TEMP_APP_PATH"


#----------------------------------------
# 2. 将解压出来的.app拷贝进入工程下
# BUILT_PRODUCTS_DIR 工程生成的APP包的路径
# TARGET_NAME target名称
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "app路径:$TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH"
mkdir -p "$TARGET_APP_PATH"
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"



#----------------------------------------
# 3. 删除extension和WatchAPP.个人证书没法签名Extention
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"



#----------------------------------------
# 4. 更新info.plist文件 CFBundleIdentifier
#  设置:"Set : KEY Value" "目标文件路径"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"


#----------------------------------------
# 5. 给MachO文件上执行权限
# 拿到MachO文件的路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"



#----------------------------------------
# 6. 重签名第三方 FrameWorks
TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do

#签名
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi


```
将sh文件放到代码根目录下，再创建一个APP文件夹，然后将导出的app包放入APP文件夹下。如图1：
***$\color{HotPink}{注意：在脚本添加之前，请先将工程安装在真机设备上。}$***


![图一](https://upload-images.jianshu.io/upload_images/13002035-19b373d6c11688c2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


接下来我们在BuildPhases内添加脚本，
![image.png](https://upload-images.jianshu.io/upload_images/13002035-8423240847aea044.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
然后添加脚本路径，${SRCROOT}是本身代码路径的环境变量。
![image.png](https://upload-images.jianshu.io/upload_images/13002035-158634f2926435e3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
最后选择真机运行，代码就会替换之前的app，将大千影视的app包重新签名替换原来的mach-o文件。这样我们的机子上就安装了一个重签了我们自己的证书的应用
![image.png](https://upload-images.jianshu.io/upload_images/13002035-4a294efadec79052.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
接下来我们通过xcode来调试下这个应用
![image.png](https://upload-images.jianshu.io/upload_images/13002035-a6158d2f56109974.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在这个播放页面我们通过xcode 的view debug来查看广告的窗口
![image.png](https://upload-images.jianshu.io/upload_images/13002035-4e26abde0abeca29.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
通过class-dump导出头文件
***class-dump路径 -H 需要导出的框架路径 -o 导出的头文件存放路***
我们将这个导出的文件放到Sublime Text中
![image.png](https://upload-images.jianshu.io/upload_images/13002035-9a97fccf917844ce.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

接下来我们需要新建一个动态库framework和这个app包相关联。
![image.png](https://upload-images.jianshu.io/upload_images/13002035-74c16c0b2c70d079.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
我们创建一个SQHook的framework。
![image.png](https://upload-images.jianshu.io/upload_images/13002035-819820f6bd613661.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
添加一个类InjectDelAD 
```
#import "InjectDelAD.h"

@implementation InjectDelAD
+(void)load{
    NSLog(@"你好！!~!!!!!!!!~~~~~~~");
}
@end

```
![image.png](https://upload-images.jianshu.io/upload_images/13002035-1f38d85bed6dc9c2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

然后在脚本的最后添加
```
#注入
yololib "$TARGET_APP_PATH/$APP_BINARY" "Frameworks/SQHook.framework/SQHook"
```
yololib会将动态库添的链接添加到mach-o的动态库申明中。
现在load commands中没有我们的动态库声明
![image.png](https://upload-images.jianshu.io/upload_images/13002035-76f9ea309eb37ad1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
保存好脚本重新编译,这时候可以打印出来了。(注：要下载yololib源码编译出可执行文件后放到/usr/local/bin下)
![image.png](https://upload-images.jianshu.io/upload_images/13002035-fffa08f3c4abc8e4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这时候再看mach-o文件，动态库已经挂载上去了。
![image.png](https://upload-images.jianshu.io/upload_images/13002035-fca616413ffb3b97.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
接下来我们开始调试，在广告页面我们点view debug

![image.png](https://upload-images.jianshu.io/upload_images/13002035-30d072dbe8e83619.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
我们看到广告页面使用的是SaveAllSentientBeingsABeforeOrEndPlayADView，我们去刚刚导出的.h文件中查找这个类
```
//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Sep 17 2017 16:24:48).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <UIKit/UIImageView.h>

@class GCDTimerTool, NewADModel, UIButton, UILabel;

@interface SaveAllSentientBeingsABeforeOrEndPlayADView : UIImageView
{
    UILabel *_timerLabel;
    UILabel *_noticeLabel;
    NewADModel *_model;
    GCDTimerTool *_timer;
    UIButton *_fullScreenBtn;
    UIButton *_backBtn;
    UIImageView *_shadow;
}

+ (void)showWithPlayEndFlag:(_Bool)arg1 willPlayNext:(_Bool)arg2 PlayerView:(id)arg3 withModel:(id)arg4 closeHandler:(CDUnknownBlockType)arg5;
@property(retain, nonatomic) UIImageView *shadow; // @synthesize shadow=_shadow;
@property(retain, nonatomic) UIButton *backBtn; // @synthesize backBtn=_backBtn;
@property(retain, nonatomic) UIButton *fullScreenBtn; // @synthesize fullScreenBtn=_fullScreenBtn;
@property(retain, nonatomic) GCDTimerTool *timer; // @synthesize timer=_timer;
@property(retain, nonatomic) NewADModel *model; // @synthesize model=_model;
@property(retain, nonatomic) UILabel *noticeLabel; // @synthesize noticeLabel=_noticeLabel;
@property(retain, nonatomic) UILabel *timerLabel; // @synthesize timerLabel=_timerLabel;
- (void).cxx_destruct;
- (void)dealloc;
- (void)setBtnHidden;
- (void)layoutSubviews;
- (id)initWithCloseHandler:(CDUnknownBlockType)arg1;

@end


```
我们看到这个初始化方法- (id)initWithCloseHandler:(CDUnknownBlockType)arg1;这时候我们设置返回空，是不是就没广告呢。这个方法是oc方法可以用runtime方法交换进行hook。
```
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
@implementation InjectDelAD
+(void)load{
    NSLog(@"你好！!~!!!!!!!!~~~~~~~");
    Method initADView = class_getInstanceMethod(objc_getClass("SaveAllSentientBeingsABeforeOrEndPlayADView"), @selector(initWithCloseHandler:));
    method_exchangeImplementations(initADView, class_getInstanceMethod(self, @selector(initWithCloseHandlerHook:)));
    
}
-(instancetype)initWithCloseHandlerHook:(id)arg{
     NSLog(@"交换方法执行~~~~~~~~~!!!");
    return nil;
}
@end


```
再编译下看下效果发现广告没了。。。
![image.png](https://upload-images.jianshu.io/upload_images/13002035-381ce77b9f2dd222.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

结束语：通过上述方法也可以去掉开机广告等，这部分的代码注入只能hook掉oc方法，对于一些系统的函数什么的要使用其他的方式，如fishhook什么的，一些静态函数需要更改mach-o文件等。
