//
//  JvAsync.m
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import "JvAsync.h"

@interface JvAsync ()

@property (strong, nonatomic) NSMutableArray *taskStack;

@property (copy, nonatomic) JvAsyncCallback callback;

@property (strong, atomic) id currentData;
@property (strong, nonatomic) NSMutableArray *results;

@property (strong, atomic) id currentError;


@end

@implementation JvAsync

- (instancetype)init {
    self = [super init];
    if (self) {
        self.results = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)async {
    JvAsync *instance = [[JvAsync alloc]init];
    return instance;
}

- (void)dealloc {
    NSLog(@"----- JvAsync Dealloc -----");
}

#pragma mark - series

- (void)seriesTasks:(NSArray<JvFunc> *)tasks callback:(JvAsyncCallback)callback {
    
    self.callback = callback;
    
    if ([self setTaskStackWithTasks:tasks]) {
        [self series_doTask];
    }else{
        [self doCallback];
    }
    
}

- (void)series_doTask {
    JvFunc func = (JvFunc)[self popTaskStack];
    
    if (func == NULL) {
        [self doCallback];
        return;
    }
    
    //enter a child thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        func(^(NSError *error, id data){
            
            //return the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                [self addToResultsWithData:data];
                if (self.currentError) {
                    [self doCallback];
                }else{
                    [self series_doTask];
                }
            });
            
        });
    });
}

#pragma mark - waterfall

- (void)waterfallTasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvAsyncCallback)callback {
    
    self.callback = callback;
    
    if ([self setTaskStackWithTasks:tasks]) {
        [self waterfall_doTask];
    }else{
        [self doCallback];
    }
    
}

- (void)waterfall_doTask {
    
    JvWaterfallFunc func = (JvWaterfallFunc)[self popTaskStack];
    
    if (func == NULL) {
        [self doCallback];
        return;
    }
    
    //enter a child thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        func(self.currentData, ^(NSError *error, id data){
            
            //return the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                self.currentData = data;
                if (self.currentError) {
                    [self doCallback];
                }else{
                    [self waterfall_doTask];
                }
                
            });
            
        });
    });
    
}

#pragma mark - parallel

- (void)parallelTasks:(NSArray<JvFunc> *)tasks callback:(JvAsyncCallback)callback {
    
    self.callback = callback;
    
    
    
}

#pragma mark - General

- (BOOL)setTaskStackWithTasks:(NSArray *)tasks {
    if ((!tasks) || tasks.count <= 0) {
        return NO;
    }
    
    self.taskStack = [NSMutableArray array];
    for (NSInteger i = tasks.count - 1; i >= 0; i--) {
        [self.taskStack addObject:tasks[i]];
    }
    
    return YES;
}

- (void(^)())popTaskStack {
    if (self.taskStack && self.taskStack.count) {
        void(^retFunc)() = self.taskStack.lastObject;
        [self.taskStack removeLastObject];
        return retFunc;
    }
    
    return NULL;
}

- (void)addToResultsWithData:(id)data {
    if (data) {
        [self.results addObject:data];
    }else{
        [self.results addObject:[NSNull null]];
    }
}

- (void)doCallback {
    if (self.callback) {
        self.callback(self.currentError, self.currentData);
    }
}

@end
