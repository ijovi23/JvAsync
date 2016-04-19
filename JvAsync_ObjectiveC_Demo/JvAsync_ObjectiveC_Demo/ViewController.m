//
//  ViewController.m
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import "ViewController.h"
#import "JvAsync.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.bounds = CGRectMake(0, 0, 100, 30);
    btn.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [btn setTitle:@"StartTest" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnPressed:(UIButton *)sender {
    [self whilst_test];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)series_test {
    JvFunc2 task1 = ^(JvCallback2 callback) {
        NSLog(@"task1");
        callback(nil, @"A");
    };
    
    JvFunc2 task2 = ^(JvCallback2 callback) {
        NSLog(@"task2");
        callback(nil, @"B");
    };
    
    JvFunc2 task3 = ^(JvCallback2 callback) {
        NSLog(@"task3");
        callback(nil, @"C");
    };
    
    [[JvAsync async]seriesTasks:@[task1, task2, task3] callback:^(NSError *error, id result) {
        if (error) {
            NSLog(@"Error:%@", error.domain);
        }
        if (result) {
            NSLog(@"Result:%@", result);
        }
    }];
}

- (void)waterfall_test {
    JvWaterfallFunc task1 = ^(id data, JvCallback2 callback) {
        NSLog(@"task1");
        callback(nil, @"A");
    };
    
    JvWaterfallFunc task2 = ^(id data, JvCallback2 callback) {
        NSLog(@"task2");
        NSString *str = [NSString stringWithFormat:@"%@B", data];
        callback(nil, str);
    };
    
    JvWaterfallFunc task3 = ^(id data, JvCallback2 callback) {
        NSLog(@"task3");
        NSString *str = [NSString stringWithFormat:@"%@C", data];
        callback(nil, str);
    };
    
    [[JvAsync async]waterfallTasks:@[task1,
                                    task2,
                                    task3]
                          callback:^(NSError *error, id result) {
                              if (error) {
                                  NSLog(@"Error:%@", error.domain);
                              }
                              if (result) {
                                  NSLog(@"Result:%@", result);
                              }
                          }];
}

- (void)parallel_test {
    [[JvAsync async]parallelTasks:@[
                                    ^(JvCallback2 callback) {[NSThread sleepForTimeInterval:2]; NSLog(@"task1"); callback(nil, @"A");},
                                    ^(JvCallback2 callback) {[NSThread sleepForTimeInterval:6]; NSLog(@"task2"); callback([NSError errorWithDomain:@"HAHA" code:123 userInfo:nil], @"B");},
                                    ^(JvCallback2 callback) {[NSThread sleepForTimeInterval:5]; NSLog(@"task3"); callback(nil, @"C");},
                                    ^(JvCallback2 callback) {[NSThread sleepForTimeInterval:3]; NSLog(@"task4"); callback(nil, @"D");},
                                    ^(JvCallback2 callback) {[NSThread sleepForTimeInterval:4]; NSLog(@"task5"); callback([NSError errorWithDomain:@"HAHA" code:123 userInfo:nil], @"E");},
                                    ] callback:^(NSError *error, id result) {
        if (error) {
            NSLog(@"Error:%@", error.domain);
        }
        if (result) {
            NSLog(@"Result:%@", result);
        }
    }];
}

- (void)whilst_test {
    __block int count = 10;
    
    [[JvAsync async]whilstTest:^BOOL{
        return count > 0;
    } fn:^(JvCallback callback) {
        [NSThread sleepForTimeInterval:0.5];
        NSLog(@"count:%d", count--);
        callback(nil);
    } callback:^(NSError *error) {
        if (error) {
            NSLog(@"Error:%@", error.domain);
        }
    }];
}

@end
