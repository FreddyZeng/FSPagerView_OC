//
//  ViewController.m
//  FSPagerView_OC
//
//  Created by  张礼栋 on 2019/6/14.
//  Copyright © 2019 mobile. All rights reserved.
//

#import "ViewController.h"
#import "FSPagerView.h"

@interface ViewController ()<FSPagerViewDelegate,FSPagerViewDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    FSPagerView *pagerView = [[FSPagerView alloc] initWithFrame:CGRectMake(0, 100, 320, 132)];
    pagerView.delegate = self;
    pagerView.dataSource = self;
    pagerView.isInfinite = NO;
    pagerView.itemSize = CGSizeMake(220, 132);
    pagerView.interitemSpacing = 12;
    [pagerView registerClass:NSClassFromString(@"FSPagerViewCell") forCellWithReuseIdentifier:@"Cell"];
    
    FSPagerViewTransformer *transformer = [[FSPagerViewTransformer alloc] initWithType:FSPagerViewTransformerTypeHorizontalOnlyAlpha];
    pagerView.transformer = transformer;
    [self.view addSubview:pagerView];
}

- (NSInteger)numberOfItemsInPagerView:(FSPagerView *)pagerView
{
    return 5;
}

- (FSPagerViewCell *)pagerView:(FSPagerView *)pagerView cellForItemAtIndex:(NSInteger)index
{
    FSPagerViewCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:@"Cell" atIndex:index];
    cell.backgroundColor = [UIColor grayColor];
    //    FSHotelModel *model=[self.pagerList objectAtIndex:index];
    //    cell.hoteModel=model;
    //    [cell.imageView setImage:@""];
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@",@(index),@(index)];
    return cell;
}


@end
