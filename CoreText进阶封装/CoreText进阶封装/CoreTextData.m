//
//  CoreTextData.m
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import "CoreTextData.h"
#import "CoreTextImageData.h"

@implementation CoreTextData

- (void)setCtFrame:(CTFrameRef)ctFrame {
    if (_ctFrame != nil && _ctFrame != ctFrame) {
        CFRelease(_ctFrame);
    }
    CFRetain(ctFrame);
    _ctFrame = ctFrame;
}

- (void)setImageArray:(NSMutableArray *)imageArray {
    _imageArray = imageArray;
    [self fillImagePosition];
}

- (void)fillImagePosition {
    if (self.imageArray.count == 0) {
        return;
    }
    
    /**
     *  在CTFrame内部是由多个CTline组成，每行CTline又是由多个CTRun组成
     *  每个CTRun代表一组风格一致的文本(CTline和CTRun的创建不需要我们管理)
     *  在CTRun中我们可以设置代理来指定绘制此组文本的宽高和排列方式等信息
     *  此处利用CTRun代理设置一个空白的字符给定宽高，最后在利用CGContextDrawImage将其绘制
     */
    
    //获取CTFrame中所有的CTline
    NSArray *lines = (NSArray *)CTFrameGetLines(self.ctFrame);
    NSInteger lineCount = lines.count;
    //利用CGPoint数组获取所有CTline的起始坐标
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    //获取图片信息数组中第一个图片信息
    NSInteger imgIndex = 0;
    CoreTextImageData *imageData = self.imageArray[imgIndex];
    
    //遍历每行CTline查找是否含有CTRun代理
    for (int i = 0; i < lineCount; i ++) {
        
#pragma mark 不存在图片信息直接退出
        if (imageData == nil) {
            break;
        }
#pragma mark 存在图片信息则需要获取图片具体位置信息
        //得到一行的信息
        CTLineRef line = (__bridge CTLineRef)lines[i];
        //等到该行CTRun信息
        NSArray * runObjArray = (NSArray *)CTLineGetGlyphRuns(line);
        //遍历该行CTRun信息
        for (id runObj in runObjArray) {
            //判断该CTRun是否设置有代理,若无代理直接进行下次循环
            CTRunRef run = (__bridge CTRunRef)runObj;
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            //若CTRun有代理，则获取代理信息，代理信息若不为字典直接进行下次循环
            NSDictionary *metaDic = CTRunDelegateGetRefCon(delegate);
            if (![metaDic isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            //找到代理则开始计算图片位置信息
            CGRect runBounds;
            CGFloat ascent;
            CGFloat desent;
            //获取CTRunDelegate中的宽度并给上升和下降高度赋值
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &desent, NULL);
            //height = 上升高度 + 下降高度
            runBounds.size.height = ascent + desent;
            //获取此CTRun在x上的偏移量
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            //设置起始坐标点
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y - desent;
            //获取CTFrame的路径
            CGPathRef pathRef = CTFrameGetPath(self.ctFrame);
            //利用路径获取绘制视图的Rect
            CGRect colRect = CGPathGetBoundingBox(pathRef);
            //根据runBounds配置图片在绘制视图中的实际位置
            CGRect delegateBounds;
            if (imgIndex == 0) {
                //让第一张图片居中显示
                delegateBounds = CGRectOffset(runBounds, colRect.origin.x + (colRect.size.width - runBounds.size.width) * 0.5, colRect.origin.y);
            }else {
                delegateBounds = CGRectOffset(runBounds, colRect.origin.x, colRect.origin.y);
            }
            //保存图片的位置信息
            imageData.imagePosition = delegateBounds;
            imgIndex++;
            
            if (imgIndex == self.imageArray.count) {
                imageData = nil;
                break;
            }else {
                imageData = self.imageArray[imgIndex];
            }
            
        }
    }
}

- (void)dealloc {
    if (_ctFrame != nil) {
        CFRelease(_ctFrame);
        _ctFrame = nil;
    }
}
@end
