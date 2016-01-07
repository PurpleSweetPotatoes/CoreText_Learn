//
//  CTFrameParser.m
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import "CTFrameParser.h"
#import <CoreText/CoreText.h>
#import "CoreTextImageData.h"
#import "CoreTextLinkData.h"

#pragma mark - CTRunDelegateCallback 代理回调函数

/**
 *  上升高度回调函数
 */
static CGFloat ascentCallback(void *ref) {
    return [(NSNumber *)[(__bridge NSDictionary *)ref objectForKey:@"height"] floatValue];
}

/**
 *  下降高度回调函数
 */
static CGFloat descentCallback(void *ref) {
    return 0;
}

/**
 *  文本宽度回调函数
 */
static CGFloat widthCallback(void *ref) {
    return [(NSNumber *)[(__bridge NSDictionary *)ref objectForKey:@"width"] floatValue];
}


@implementation CTFrameParser

/**
 *  根据文件路径和配置文件生成CoreTextData对象(模拟网络请求)
 *
 *  @param path   文件路径
 *  @param config 配置信息对象
 *
 *  @return CoreTextData对象
 */
+ (CoreTextData *)parseTemplateFile:(NSString *)path
                             config:(CTFrameParserConfig *)config {
    NSMutableArray *imageArray = [NSMutableArray array];
    NSMutableArray *linkArray = [NSMutableArray array];
    NSAttributedString *content = [self loadTemplateFile:path config:config imageArray:imageArray linkArray:linkArray];
    CoreTextData *data = [self parseAttributedContent:content config:config];
    data.imageArray = imageArray;
    data.linkArray = linkArray;
    return data;
}

/**
 *  根据属性文字对象和配置信息对象生成CoreTextData对象
 *
 *  @param content 属性文字对象
 *  @param config  配置信息对象
 *
 *  @return CoreTextData对象
 */
+ (CoreTextData *)parseAttributedContent:(NSAttributedString *)content
                                  config:(CTFrameParserConfig *)config {
    //创建CTFrameSetterRef实例
    CTFramesetterRef ctFrameSetterRef = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)content);
    //获取要绘制的区域信息
    CGSize restrictSize = CGSizeMake(config.width, CGFLOAT_MAX);
    CGSize coreTextSize = CTFramesetterSuggestFrameSizeWithConstraints(ctFrameSetterRef, CFRangeMake(0, 0), NULL, restrictSize, NULL);
    CGFloat textHeight = coreTextSize.height;
    //配置ctframeRef信息
    CTFrameRef ctFrame = [self createFrameWithFramesetting:ctFrameSetterRef config:config height:textHeight];
    //配置coreTextData数据
    CoreTextData *data = [[CoreTextData alloc] init];
    data.ctFrame = ctFrame;
    data.height = textHeight;
    //释放内存
    CFRelease(ctFrame);
    CFRelease(ctFrameSetterRef);
    return data;
}
/**
 *  根据文件路径和配置信息对象进行数据的解析和属性文字生成
 *
 *  @param path   文件路径
 *  @param config 配置信息对象
 *  @param imageArray 存储图片数组
 *
 *  @return 属性文字
 */
+ (NSAttributedString *)loadTemplateFile:(NSString *)path
                                  config:(CTFrameParserConfig *)config
                              imageArray:(NSMutableArray *)imageArray
                               linkArray:(NSMutableArray *)linkArray {
    
    NSMutableAttributedString *attStringM = [[NSMutableAttributedString alloc] init];
#warning 此处直接用一个数组(数组嵌字典)表示。(具体解析方式应根据网络接口传回的数据来设置)
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    for (NSDictionary *dict in array) {
        NSString *type = dict[@"type"];
        if ([type isEqualToString:@"txt"]) {
            NSAttributedString *attString = [self parseAttributedContentFromNSDictionary:dict config:config];
            [attStringM appendAttributedString:attString];
        }else if ([type isEqualToString:@"image"]) {
            CoreTextImageData *imageData = [[CoreTextImageData alloc] init];
            imageData.name = dict[@"content"];
            [imageArray addObject:imageData];
            //创建空白占位符，并设置它的CTRunDelegate信息
            NSAttributedString *attString = [self parseImageDataFromNSDictionary:dict config:config];
            [attStringM appendAttributedString:attString];
        }else if ([type isEqualToString:@"link"]) {
            //得到属性文字的起始点
            NSUInteger startPos = attStringM.length;
            NSAttributedString *attString = [self parseAttributedLinkFromNSDictionary:dict config:config];
            [attStringM appendAttributedString:attString];
            //获取链接文字属性的范围
            NSRange linkRange = NSMakeRange(startPos, attString.length);
            
            //将链接文字属性信息保存到数组中
            CoreTextLinkData *linkdata = [[CoreTextLinkData alloc] init];
            linkdata.range = linkRange;
            linkdata.urlString = dict[@"content"];
            
            [linkArray addObject:linkdata];
        }
    }
    
    return attStringM;
}

/**
 *  根据解析数据和配置信息对象配置属性文字
 *
 *  @param dict   解析数据字典
 *  @param config 配置对象信息
 *
 *  @return 返回的属性文字
 */
+ (NSAttributedString *)parseAttributedContentFromNSDictionary:(NSDictionary *)dict
                                                        config:(CTFrameParserConfig *)config {
    NSMutableDictionary *attributes = [self attributesWithConfig:config];
    //设置颜色
    UIColor *color = [self colorFromTemplate:dict[@"color"]];
    if(color != nil) {
        attributes[(id)kCTForegroundColorAttributeName] = (id)color.CGColor;
    }
    //设置字体大小
    CGFloat fontSize = [dict[@"size"] floatValue];
    if (fontSize > 0) {
        CTFontRef fontRef = CTFontCreateWithName((CFStringRef)@"ArialMT", fontSize, NULL);
        attributes[(id)kCTFontAttributeName] = (__bridge id)fontRef;
        CFRelease(fontRef);
    }
    //配置文字
    NSString *content = dict[@"content"];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:content attributes:attributes];
    
    return attString;
}

/**
 *  返回空白的占位符文字
 *
 *  @param dict   字典信息包含图片宽高等信息
 *  @param config 配置信息对象
 *
 *  @return 空白占位符(有宽高)
 */
+ (NSAttributedString *)parseImageDataFromNSDictionary:(NSDictionary *)dict
                                config:(CTFrameParserConfig *)config {
    //配置CTRun代理回调函数
    CTRunDelegateCallbacks callbacks;
    //为callbacks开辟内存空间
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    //设置代理版本
    callbacks.version = kCTRunDelegateVersion1;
    //配置代理回调函数
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    //根据配置的代理信息创建代理
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void*)dict);
    //使用0xFFFC作为空白占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString *content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    NSDictionary * attributes = [self attributesWithConfig:config];
    NSMutableAttributedString *space = [[NSMutableAttributedString alloc] initWithString:content attributes:attributes];
    //为属性文字设置代理
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)space, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return space;
}
+ (NSAttributedString *)parseAttributedLinkFromNSDictionary:(NSDictionary *)dict
                                                        config:(CTFrameParserConfig *)config {
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithAttributedString:[self parseAttributedContentFromNSDictionary:dict config:config]];
    [attString addAttribute:(id)kCTUnderlineColorAttributeName value:(id)[self colorFromTemplate:dict[@"color"]].CGColor range:NSMakeRange(0, attString.length)];
    [attString addAttribute:(id)kCTUnderlineStyleAttributeName value:(id)[NSNumber numberWithInt:kCTUnderlineStyleSingle] range:NSMakeRange(0, attString.length)];
    
    return attString;
}
/**
 *  根据名字获取颜色
 *
 *  @param name 颜色名字
 *
 *  @return 颜色对象
 */
+ (UIColor *)colorFromTemplate:(NSString *)name {
    if ([name isEqualToString:@"red"]) {
        return [UIColor redColor];
    }else if ([name isEqualToString:@"blue"]) {
        return [UIColor blueColor];
    }else if ([name isEqualToString:@"black"]) {
        return [UIColor blackColor];
    }else {
        return nil;
    }
}

/**
 *  根据配置信息对象和文字生成对应的CoreTextData对象
 *
 *  @param content 文本内容
 *  @param config  文本配置信息
 *
 *  @return CoreText对象
 */
+ (CoreTextData *)parseContent:(NSString *)content config:(CTFrameParserConfig *)config {
    //创建文字并配置属性
    NSDictionary *attributes = [self attributesWithConfig:config];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:content attributes:attributes];
    return [self parseAttributedContent:attString config:config];
}

/**
 *  根据传入配置信息配置文字属性字典
 *
 *  @param config 配置信息对象
 *
 *  @return 配置文字属性字典
 */
+ (NSMutableDictionary *)attributesWithConfig:(CTFrameParserConfig *)config {
    //配置字体信息
    CGFloat fontSize = config.fontSize;
    CTFontRef ctFont = CTFontCreateWithName((CFStringRef)@"ArialMT", fontSize, NULL);
    //配置间距
    CGFloat lineSpace = config.lineSpace;
    const CFIndex kNumberOfSettings = 3;
    CTParagraphStyleSetting theSettings[kNumberOfSettings] = {
        {
            kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(CGFloat), &lineSpace
        },
        {
            kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat), &lineSpace
        },
        {
            kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat), &lineSpace
        }
    };
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, kNumberOfSettings);
    //配置颜色
    UIColor *textColor = config.textColor;
    //将配置信息加入字典
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[(id)kCTForegroundColorAttributeName] = (id)textColor.CGColor;
    dict[(id)kCTFontAttributeName] = (__bridge id)ctFont;
    dict[(id)kCTParagraphStyleAttributeName] = (__bridge id)theParagraphRef;
    //释放变量
    CFRelease(theParagraphRef);
    CFRelease(ctFont);
    
    return dict;
}

/**
 *  根据CTFramesetterRef、配置信息对象和高度生成对应的CTFrameRef
 *
 *  @param frameSetter CTFramesetterRef
 *  @param config      配置信息对象
 *  @param height      CTFrame高度
 *
 *  @return CTFrameRef
 */
+ (CTFrameRef)createFrameWithFramesetting:(CTFramesetterRef)frameSetter
                                   config:(CTFrameParserConfig *)config
                                   height:(CGFloat)height {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, config.width, height));
    CTFrameRef ctframeRef = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);
    CFRelease(path);
    return ctframeRef;
}

@end
