//
//  CTFrameParserConfig.m
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import "CTFrameParserConfig.h"

@implementation CTFrameParserConfig
- (instancetype)init
{
    self = [super init];
    if (self) {
        _width = 200.0f;
        _fontSize = 16.0f;
        _lineSpace = 8.0f;
        _textColor = [UIColor blackColor];
    }
    return self;
}
@end
