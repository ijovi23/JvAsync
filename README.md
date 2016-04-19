# JvAsync

**JvAsync**, written in Objective-C Language for iOS developers, is a utility module which provides some typical asynchronous-working functions from [**Async**(Javascript)](https://github.com/caolan/async).

*Tags: iOS | Async | Objective-C | Node.js | Nodejs*

##Start

Add *JvAsync.h* and *JvAsync.m* to your project.

```objective-c
#import "JvAsync.h"
```
##Provided Functions

* [`series`](#series)
* [`waterfall`](#waterfall)
* [`parallel`](#parallel)
* [`whilst`](#whilst)
* [`until`](#until)
* [`map`](#map)

##Usage

###series

<a name="series"></a>

Run the functions in the tasks collection in series, each one running once the previous function has completed. If any functions in the series pass an error to its callback, no more functions are run, and callback is immediately called with the value of the error. Otherwise, callback receives an array of results when tasks have completed.

**Example**

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
	
// [Output]:
// task1
// task2
// task3
// Result:("A","B","C")
```

###waterfall

<a name="waterfall"></a>

Runs the tasks array of functions in series, each passing their results to the next in the array. However, if any of the tasks pass an error to their own callback, the next function is not executed, and the main callback is immediately called with the error.

**Example**

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
	
// [Output]:
// task1
// task2
// task3
// Result:"ABC"
```
