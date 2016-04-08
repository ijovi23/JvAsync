//
//  JvAsync.h
//  JvAsync_ObjectiveC_Demo
//
//  Created by Jovi Du on 4/8/16.
//  Copyright © 2016 Jovi Du. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^JvAsyncCallback)(NSError *error, id data);
typedef void(^JvWaterfallFunc) (id data, JvAsyncCallback callback);

@interface JvAsync : NSObject

+ (instancetype)async;

- (void)waterfallTasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvAsyncCallback)callback;

@end
