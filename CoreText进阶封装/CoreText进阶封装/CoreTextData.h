//
//  CoreTextData.h
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface CoreTextData : NSObject

/** 文本绘制的区域大小 */
@property (nonatomic, assign) CTFrameRef ctFrame;

/** 文本绘制区域高度 */
@property (nonatomic, assign) CGFloat height;

/** 文本中存储图片信息数组 */
@property (nonatomic, strong) NSMutableArray *imageArray;

/** 文本中存储链接信息数组 */
@property (nonatomic, strong) NSMutableArray *linkArray;
@end
