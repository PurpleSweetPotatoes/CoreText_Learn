//
//  CTFrameParserConfig.h
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  CTFrame配置信息类
 */
@interface CTFrameParserConfig : NSObject

/** 文本宽度 */
@property (nonatomic, assign) CGFloat width;

/** 字体大小 */
@property (nonatomic, assign) CGFloat fontSize;

/** 字体行间距 */
@property (nonatomic, assign) CGFloat lineSpace;

/** 字体颜色 */
@property (nonatomic, strong) UIColor *textColor;

@end
