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
    // Do any additional setup after loading the view, typically from a nib.
    [self test];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)test {
    JvWaterfallFunc task1 = ^(id data, JvAsyncCallback callback) {
        NSLog(@"task1");
        callback(nil, @"A");
    };
    
    JvWaterfallFunc task2 = ^(id data, JvAsyncCallback callback) {
        NSLog(@"task2");
        NSString *str = [NSString stringWithFormat:@"%@B", data];
        callback(nil, str);
    };
    
    JvWaterfallFunc task3 = ^(id data, JvAsyncCallback callback) {
        NSLog(@"task3");
        NSString *str = [NSString stringWithFormat:@"%@C", data];
        callback(nil, str);
    };
    
    [[JvAsync async]waterfallTasks:@[task1,
                                    task2,
                                    task3]
                          callback:^(NSError *error, id data) {
                              if (error) {
                                  NSLog(@"Error:%@", error.domain);
                              }
                              if (data) {
                                  NSLog(@"Result:%@", data);
                              }
                          }];
}

@end
