//
//  BQDisplayView.h
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTextData.h"

/**
 *  富文本展示类，高度设置无效会自动获取高度
 */
@interface BQDisplayView : UIView

/**  绘制文本的数据信息 */
@property (nonatomic, strong) CoreTextData *data;

@end
