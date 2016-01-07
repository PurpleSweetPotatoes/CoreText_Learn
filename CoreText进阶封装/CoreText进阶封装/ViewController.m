//
//  ViewController.m
//  CoreText进阶封装
//
//  Created by baiqiang on 16/1/5.
//  Copyright © 2016年 baiqiang. All rights reserved.
//

#import "ViewController.h"
#import "BQDisplayView.h"
#import "CTFrameParserConfig.h"
#import "CTFrameParser.h"

@interface ViewController ()
@property (nonatomic, strong) NSString *netWorkPath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initData];
    [self initUI];
    NSString *str;
    NSMutableString *mStr;
    
    [str copy];
    [str mutableCopy];
    [mStr copy];
    [mStr mutableCopy];
    
}

- (void)initData {
    _netWorkPath = [[NSBundle mainBundle] pathForResource:@"NetWorkData" ofType:@"plist"];
}
- (void)initUI {
    BQDisplayView *displayView = [[BQDisplayView alloc] initWithFrame:CGRectMake(10, 20, self.view.bounds.size.width - 20, 0)];
    displayView.backgroundColor = [UIColor orangeColor];
    
    //配置文本属性信息
    CTFrameParserConfig *config = [[CTFrameParserConfig alloc] init];
    config.width = displayView.bounds.size.width;
    config.textColor = [UIColor redColor];
    
    //得到视图文本数据
    displayView.data = [CTFrameParser parseTemplateFile:_netWorkPath config:config];
    
    
    [self.view addSubview:displayView];
}


@end
