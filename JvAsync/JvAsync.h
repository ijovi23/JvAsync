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
typedef void(^JvIterator) (id item, JvCallback callback);
typedef void(^JvIterator2) (id item, JvCallback2 callback);
typedef void(^JvWaterfallFunc) (id data, JvCallback2 callback);
typedef BOOL(^JvTest)();

@interface JvAsync : NSObject

+ (instancetype)async;

- (void)series_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;

- (void)waterfall_tasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvCallback2)callback;

- (void)parallel_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;

- (void)whilst_test:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback;

- (void)until_test:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback;

- (void)map_coll:(NSArray *)coll iteratee:(JvIterator2)iteratee callback:(JvCallback2)callback;

@end
