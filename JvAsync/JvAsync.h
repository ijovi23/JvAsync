//
//  JvAsync.h
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JvCallback)(NSError *error);
typedef void(^JvCallback2)(NSError *error, id result);
typedef void(^JvFunc)(JvCallback callback);
typedef void(^JvFunc2)(JvCallback2 callback);
typedef void(^JvWaterfallFunc) (id data, JvCallback2 callback);
typedef BOOL(^JvTest)();

@interface JvAsync : NSObject

+ (instancetype)async;

- (void)seriesTasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;

- (void)waterfallTasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvCallback2)callback;

- (void)parallelTasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;

- (void)whilstTest:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback;

- (void)untilTest:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback;

@end
