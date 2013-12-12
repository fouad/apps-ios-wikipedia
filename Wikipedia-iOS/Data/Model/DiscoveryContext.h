//
//  DiscoveryContext.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/11/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class History;

@interface DiscoveryContext : NSManagedObject

@property (nonatomic, retain) NSNumber * isPrefix;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) History *history;

@end
