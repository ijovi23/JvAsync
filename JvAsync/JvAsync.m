//
//  JvAsync.m
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import "JvAsync.h"

@interface JvAsync ()

@property (strong, atomic) NSMutableArray<JvWaterfallFunc> *taskStack;

@property (copy, nonatomic) JvAsyncCallback callback;

@property (strong, atomic) id currentData;

@property (strong, atomic) id currentError;

@property (copy, nonatomic) JvWaterfallFunc nextFunc;

@end

@implementation JvAsync

+ (instancetype)async {
    JvAsync *instance = [[JvAsync alloc]init];
    return instance;
}

- (void)dealloc {
    NSLog(@"----- JvAsync Dealloc -----");
}

- (void)waterfallTasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvAsyncCallback)callback {
    
    if (tasks.count <= 0) {
        callback(nil, nil);
        return;
    }
    
    self.taskStack = [NSMutableArray array];
    for (NSInteger i = tasks.count - 1; i >= 0; i--) {
        [self.taskStack addObject:tasks[i]];
    }
    
    self.callback = callback;
    
    [self doTask];
}

- (JvWaterfallFunc)nextFunc {
    if (self.taskStack && self.taskStack.count) {
        JvWaterfallFunc retFunc = self.taskStack.lastObject;
        [self.taskStack removeLastObject];
        return retFunc;
    }
    
    return NULL;
}

- (void)doTask {
    
    JvWaterfallFunc func = [self nextFunc];
    
    if (func == NULL) {
        if (self.callback) {
            self.callback(self.currentError, self.currentData);
        }
        return;
    }
    
//    __weak typeof(self) ws = self;
    
    //enter a child thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        func(self.currentData, ^(NSError *error, id data){
            
            //return the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                self.currentData = data;
                if (self.currentError) {
                    if (self.callback) {
                        self.callback(self.currentError, self.currentData);
                    }
                }else{
                    [self doTask];
                }
                
            });
            
        });
    });
    
}

@end
