//
//  JvAsync.m
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import "JvAsync.h"

typedef void(^JvCallback3)(NSError *error, id result, id idx);
typedef void(^JvFunc_idx) (id idx, JvCallback3 callback);
typedef void(^JvFunc2_idx) (id idx, id data, JvCallback3 callback);

@interface JvAsync ()

@property (copy, nonatomic) JvFunc task;
@property (strong, nonatomic) NSMutableArray *taskStack;

@property (strong, nonatomic) NSMutableArray *collection;

@property (copy, nonatomic) JvCallback callback;
@property (copy, nonatomic) JvCallback2 callback2;

@property (copy, nonatomic) JvTest test;

@property (copy, nonatomic) JvIteratee3 iteratee3;

@property (strong, atomic) id result;
@property (strong, nonatomic) NSMutableArray *results;

@property (strong, atomic) id currentError;


@end

@implementation JvAsync

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initProperties];
    }
    return self;
}

+ (instancetype)async {
    JvAsync *instance = [[JvAsync alloc]init];
    return instance;
}

- (void)initProperties {
    self.task = NULL;
    self.taskStack = [NSMutableArray array];
    self.results = [NSMutableArray array];
    self.callback = NULL;
    self.callback2 = NULL;
    self.test = NULL;
    self.result = nil;
    self.currentError = nil;
}

- (void)dealloc {
    NSLog(@"----- JvAsync Dealloc -----");
}

#pragma mark - series

- (void)series_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback {
    [self initProperties];
    self.callback2 = callback;
    self.result = self.results;
    
    if ([self setTaskStackWithTasks:tasks]) {
        [self series_doTask];
    }else{
        [self doCallback2];
    }
    
}

- (void)series_doTask {
    JvFunc2 func = (JvFunc2)[self popTaskStack];
    
    if (func == NULL) {
        [self doCallback2];
        return;
    }
    
    //enter a child thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        func(^(NSError *error, id result){
            
            //return the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                [self addResultsObject:result];
                if (self.currentError) {
                    [self doCallback2];
                }else{
                    [self series_doTask];
                }
            });
            
        });
    });
}

#pragma mark - waterfall

- (void)waterfall_tasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvCallback2)callback {
    [self initProperties];
    self.callback2 = callback;
    
    if ([self setTaskStackWithTasks:tasks]) {
        [self waterfall_doTask];
    }else{
        [self doCallback2];
    }
    
}

- (void)waterfall_doTask {
    
    JvWaterfallFunc func = (JvWaterfallFunc)[self popTaskStack];
    
    if (func == NULL) {
        [self doCallback2];
        return;
    }
    
    //enter a child thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        func(self.result, ^(NSError *error, id result){
            
            //return the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                self.result = result;
                if (self.currentError) {
                    [self doCallback2];
                }else{
                    [self waterfall_doTask];
                }
                
            });
            
        });
    });
    
}

#pragma mark - parallel

- (void)parallel_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback {
    [self initProperties];
    self.callback2 = callback;
    self.result = self.results;
    
    if (!(tasks && tasks.count)) {
        [self doCallback2];
    }
    
    [self fillResultsWithCount:tasks.count];
    
    NSMutableArray<JvFunc_idx> *tasks_pl = [NSMutableArray array];
    for (JvFunc2 func in tasks) {
        JvFunc_idx func_pl = ^(id idx, JvCallback3 callback) {
            func(^(NSError *error, id result) {
                if (callback) {
                    callback(error, result, idx);
                }
            });
        };
        [tasks_pl addObject:func_pl];
    }
    
    __block NSInteger tasksLeftCount = tasks.count;
    
    dispatch_queue_t queue = dispatch_queue_create("jv.concurrent.parallel", DISPATCH_QUEUE_CONCURRENT);
    
    for (NSUInteger idx = 0; idx < tasks.count; idx++) {
        JvFunc_idx func_pl = tasks_pl[idx];
        dispatch_async(queue, ^{
            func_pl(@(idx), ^(NSError *error, id result, id idx){
                if (self.currentError) {
                    //When an error occurred during running a task, throw away the incomplete tasks' resuls;
                    return;
                }
                //return the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentError = error;
                    NSUInteger func_idx = [idx integerValue];
                    [self replaceObjectInResultsAtIndex:func_idx withObject:result];
                    tasksLeftCount--;
                    if (self.currentError || tasksLeftCount <= 0) {
                        [self doCallback2];
                    }
                });
                
            });
        });
    }
}

#pragma mark - whilst & until

- (void)whilst_test:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback {
    [self initProperties];
    self.task = fn;
    self.test = test;
    self.callback = callback;
    
    if (test == NULL || fn == NULL) {
        [self doCallback];
    }
    
    [self whilst_doTask_whenTestReturn:YES];
}

- (void)until_test:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback {
    [self initProperties];
    self.task = fn;
    self.test = test;
    self.callback = callback;
    
    if (test == NULL || fn == NULL) {
        [self doCallback];
    }
    
    [self whilst_doTask_whenTestReturn:NO];
}

- (void)whilst_doTask_whenTestReturn:(BOOL)testRet {
    if (self.test() == testRet) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            self.task(^(NSError *error){
                
                //return the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentError = error;
                    if (self.currentError) {
                        [self doCallback];
                    }else{
                        [self whilst_doTask_whenTestReturn:testRet];
                    }
                });
                
            });
        });
        
    }else{
        [self doCallback];
    }
}

#pragma mark - each & eachLimit

#pragma mark - map

- (void)map_coll:(NSArray *)coll iteratee:(JvIteratee2)iteratee callback:(JvCallback2)callback {
    [self initProperties];
    self.callback2 = callback;
    self.result = self.results;
    
    if (!(coll && coll.count && iteratee != NULL)) {
        [self doCallback2];
    }
    
    [self fillResultsWithCount:coll.count];
    
    JvFunc2_idx func_pl = ^(id idx, id data, JvCallback3 callback) {
        iteratee(data, ^(NSError *error, id result) {
            if (callback) {
                callback(error, result, idx);
            }
        });
    };
    
    __block NSInteger tasksLeftCount = coll.count;
    
    dispatch_queue_t queue = dispatch_queue_create("jv.concurrent.map", DISPATCH_QUEUE_CONCURRENT);
    
    for (NSUInteger idx = 0; idx < coll.count; idx++) {
        id curItem = coll[idx];
        dispatch_async(queue, ^{
            func_pl(@(idx), curItem, ^(NSError *error, id result, id idx) {
                if (self.currentError) {
                    //When an error occurred during running a task, throw away the incomplete tasks' resuls;
                    return;
                }
                //return the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentError = error;
                    NSUInteger item_idx = [idx integerValue];
                    [self replaceObjectInResultsAtIndex:item_idx withObject:result];
                    tasksLeftCount--;
                    if (self.currentError || tasksLeftCount <= 0) {
                        [self doCallback2];
                    }
                });
            });
        });
    }
}

#pragma mark - reduce

- (void)reduce_coll:(NSArray *)coll memo:(id)memo iteratee:(JvIteratee3)iteratee callback:(JvCallback2)callback {
    [self initProperties];
    self.callback2 = callback;
    self.result = memo;
    
    if (!(coll && coll.count && iteratee != NULL)) {
        [self doCallback2];
    }
    
    self.iteratee3 = iteratee;
    self.collection = [coll mutableCopy];
    
    if (!self.result) {
        self.result = self.collection.firstObject;
        [self.collection removeObjectAtIndex:0];
    }
    
    [self reduce_doIteratee];
    
}

- (void)reduce_doIteratee {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.iteratee3(self.result, self.collection.firstObject, ^(NSError *error, id result) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.currentError = error;
                self.result = result;
                
                [self.collection removeObjectAtIndex:0];
                
                if (self.currentError || self.collection.count <= 0) {
                    [self doCallback2];
                }else{
                    [self reduce_doIteratee];
                }
                
            });
            
        });
    });
}

#pragma mark - General

- (BOOL)setTaskStackWithTasks:(NSArray *)tasks {
    if ((!tasks) || tasks.count <= 0) {
        return NO;
    }
    
    [self.taskStack removeAllObjects];
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

- (void)fillResultsWithCount:(NSUInteger)count {
    [self.results removeAllObjects];
    for (NSUInteger i = 0; i < count; i++) {
        [self.results addObject:[NSNull null]];
    }
}

- (void)replaceObjectInResultsAtIndex:(NSUInteger)index withObject:(id)object {
    if (!object) {
        object = [NSNull null];
    }
    [self.results replaceObjectAtIndex:index withObject:object];
}

- (void)addResultsObject:(id)obj {
    if (obj) {
        [self.results addObject:obj];
    }else{
        [self.results addObject:[NSNull null]];
    }
}

- (void)doCallback {
    if (self.callback) {
        self.callback(self.currentError);
    }
}

- (void)doCallback2 {
    if (self.callback2) {
        self.callback2(self.currentError, self.result);
    }
}

@end
