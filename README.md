# JvAsync

**JvAsync**, written in Objective-C Language for iOS developers, is a utility module which provides some typical asynchronous-working functions from [**Async**(Javascript)](https://github.com/caolan/async).

*Tags: iOS | Async | Objective-C | Node.js | Nodejs*

#Start

Add **JvAsync.h** and **JvAsync.m** to your project.

```objective-c
#import "JvAsync.h"
```
#Provided Functions

* [`series`](#series)
* [`waterfall`](#waterfall)
* [`parallel`](#parallel)
* [`whilst`](#whilst)
* [`until`](#until)
* [`map`](#map)
* [`reduce`](#reduce)

#Usage

####*Here are the definitions of the used blocks*

```objective-c
typedef void(^JvCallback)		(NSError *error);
typedef void(^JvCallback2)		(NSError *error, id result);
typedef void(^JvFunc)			(JvCallback callback);
typedef void(^JvFunc2)			(JvCallback2 callback);
typedef void(^JvIteratee)		(id item, JvCallback callback);
typedef void(^JvIteratee2)		(id item, JvCallback2 callback);
typedef void(^JvIteratee3)		(id memo, id item, JvCallback2 callback);
typedef void(^JvWaterfallFunc)	(id data, JvCallback2 callback);
typedef BOOL(^JvTest)			();
```

<a name="series"></a>

##series

```objective-c
- (void)series_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;
```

Run the functions in the `tasks` collection in series, each one running once the previous function has completed. If any functions in the series pass an error to its callback, no more functions are run, and `callback` is immediately called with the value of the error. Otherwise, `callback` receives an array of results when tasks have completed.

####Example

```objective-c
[[JvAsync async]series_tasks:@[
	^(JvCallback2 callback) {
		NSLog(@"task1");
		callback(nil, @"A");
	},
	^(JvCallback2 callback) {
		NSLog(@"task2");
		callback(nil, @"B");
	},
	^(JvCallback2 callback) {
		NSLog(@"task3");
		callback(nil, @"C");
	}]
	callback:^(NSError *error, id result) {
		if (error) {
			NSLog(@"Error:%@", error.domain);
		}
		if (result) {
			NSLog(@"Result:%@", result);
		}
	}];
	
/* 
	[Output]:
	task1
	task2
	task3
	Result:("A","B","C")
*/
```

<a name="waterfall"></a>

##waterfall

```objective-c
- (void)waterfall_tasks:(NSArray<JvWaterfallFunc> *)tasks callback:(JvCallback2)callback;
```

Runs the `tasks` array of functions in series, each passing their results to the next in the array. However, if any of the `tasks` pass an error to their own callback, the next function is not executed, and the main `callback` is immediately called with the error.

####Example

```objective-c
[[JvAsync async]waterfall_tasks:@[
	^(id data, JvCallback2 callback) {
		NSLog(@"task1");
		callback(nil, @"A");
	},
	^(id data, JvCallback2 callback) {
		NSLog(@"task2");
		NSString *str = [NSString stringWithFormat:@"%@B", data];
		callback(nil, str);
	},
	^(id data, JvCallback2 callback) {
		NSLog(@"task3");
		NSString *str = [NSString stringWithFormat:@"%@C", data];
		callback(nil, str);
	}]
	callback:^(NSError *error, id result) {
		if (error) {
			NSLog(@"Error:%@", error.domain);
		}
		if (result) {
			NSLog(@"Result:%@", result);
		}
	}];
	
/* 
	[Output]:
	task1
	task2
	task3
	Result:"ABC"
*/
```

<a name="parallel"></a>

##parallel

```objective-c
 - (void)parallel_tasks:(NSArray<JvFunc2> *)tasks callback:(JvCallback2)callback;
```

Run the `tasks` collection of functions in parallel, without waiting until the previous function has completed. If any of the functions pass an error to its callback, the main `callback` is immediately called with the value of the error. Once the tasks have completed, the results are passed to the final `callback` as an array.

####Example

```objective-c
[[JvAsync async]parallel_tasks:@[
	^(JvCallback2 callback) {[NSThread sleepForTimeInterval:2]; NSLog(@"task1"); callback(nil, @"A");},
	^(JvCallback2 callback) {[NSThread sleepForTimeInterval:6]; NSLog(@"task2"); callback(nil, @"B");},
	^(JvCallback2 callback) {[NSThread sleepForTimeInterval:5]; NSLog(@"task3"); callback(nil, @"C");},
	^(JvCallback2 callback) {[NSThread sleepForTimeInterval:3]; NSLog(@"task4"); callback(nil, @"D");},
	^(JvCallback2 callback) {[NSThread sleepForTimeInterval:4]; NSLog(@"task5"); callback(nil, @"E");},
	] 
	callback:^(NSError *error, id result) {
		if (error) {
			NSLog(@"Error:%@", error.domain);
		}
		if (result) {
			NSLog(@"Result:%@", result);
		}
	}];
	
/* 
	[Output]:
	task1
	task4
	task5
	task3
	task2
	Result:("A","B","C","D","E")
*/
```

<a name="whilst"></a>

##whilst

```objective-c
- (void)whilst_test:(JvTest)test fn:(JvFunc)fn callback:(JvCallback)callback;
```

Repeatedly call `fn`, while `test` returns `YES`. Calls `callback` when stopped, or an error occurs.

####Example

```objective-c
__block int count = 5;

[[JvAsync async]whilst_test:^BOOL{
		return count > 0;
	}
	fn:^(JvCallback callback) {
		[NSThread sleepForTimeInterval:0.5];
		NSLog(@"count:%d", count--);
		callback(nil);
	}
	callback:^(NSError *error) {
		if (error) {
			NSLog(@"Error:%@", error.domain);
		}
	}];
	
/* 
	[Output]:
	count:5
	count:4
	count:3
	count:2
	count:1
*/
```

<a name="until"></a>

##until

Repeatedly call `fn` until `test` returns `YES`. Calls `callback` when stopped, or an error occurs. `callback` will be passed an error and any arguments passed to the final `fn`'s callback.

The inverse of [`whilst`](#whilst).

<a name="map"></a>

##map

```objective-c
- (void)map_coll:(NSArray *)coll iteratee:(JvIteratee2)iteratee callback:(JvCallback2)callback;
```

Produces a new collection of values by mapping each value in `coll` through the `iteratee` function. The `iteratee` is called with an item from `coll` and a callback for when it has finished processing. Each of these callback takes 2 arguments: an `error`, and the transformed item from `coll`. If `iteratee` passes an error to its callback, the main `callback` (for the `map` function) is immediately called with the error.

Note, that since this function applies the `iteratee` to each item in parallel, there is no guarantee that the `iteratee` functions will complete in order. However, the results array will be in the same order as the original `coll`.

####Example

```objective-c
[[JvAsync async]map_coll:@[@3,@4,@6,@2,@1] iteratee:^(id item, JvCallback2 callback) {
		[NSThread sleepForTimeInterval:[item floatValue]];
		NSLog(@"Processed:%@", item);
		NSInteger ret = -[item integerValue];
		callback(nil, @(ret));
	}
	callback:^(NSError *error, id result) {
		if (error) {
			NSLog(@"Error:%@", error.domain);
		}
		if (result) {
			NSLog(@"Result:%@", result);
		}	
	}];

/* 
	[Output]:
	Processed:1
	Processed:2
	Processed:3
	Processed:4
	Processed:6
	Result:("-3","-4","-6","-2","-1")
*/
```	

<a name="reduce"></a>

##reduce

```objective-c
- (void)reduce_coll:(NSArray *)coll memo:(id)memo iteratee:(JvIteratee3)iteratee callback:(JvCallback2)callback;
```

Reduces `coll` into a single value using an async `iteratee` to return each successive step. `memo` is the initial state of the reduction. This function only operates in series.

####Example

```objective-c
[[JvAsync async]reduce_coll:@[@1, @2, @3, @4, @5] memo:@0.5 iteratee:^(id memo, id item, JvCallback2 callback) {
        [NSThread sleepForTimeInterval:0.5];
        float result = [memo floatValue] + [item floatValue];
        NSLog(@"memo:%@ item:%@ result:%@", memo, item, @(result));
        callback(nil, @(result));
    } callback:^(NSError *error, id result) {
        if (error) {
            NSLog(@"Error:%@", error.domain);
        }
        if (result) {
            NSLog(@"Result:%@", result);
        }
    }];

/* 
	[Output]:
	memo:0.5 item:1 result:1.5
	memo:1.5 item:2 result:3.5
	memo:3.5 item:3 result:6.5
	memo:6.5 item:4 result:10.5
	memo:10.5 item:5 result:15.5
	Result:15.5
*/
```	

