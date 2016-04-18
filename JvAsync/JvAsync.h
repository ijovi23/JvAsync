//
//  JvAsync.h
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JvAsyncCallback)(NSError *error, id result);
typedef void(^JvAsyncCallback_data)(NSError *error, id result, id data);
typedef void(^JvFunc)(JvAsyncCallback callback);
typedef void(^JvFunc_data) (id data, JvAsyncCallback_data callback);
typedef void(^JvWaterfallFunc) (id data, JvAsyncCallback callback);

@interface JvAsync : NSObject

+ (instancetype)async;

- (void)seriesTasks:(NSArray<JvFunc> *)tasks callback:(JvAsyncCallback)callback;

- (void)waterfallTasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvAsyncCallback)callback;

- (void)parallelTasks:(NSArray<JvFunc> *)tasks callback:(JvAsyncCallback)callback;

@end
