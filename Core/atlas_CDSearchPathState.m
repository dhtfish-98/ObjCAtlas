// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDSearchPathState.h"

@interface ObjCAtlasSearchPathState ()
@property (readonly) NSMutableArray *atlas_searchPathStack;
@end

#pragma mark -

@implementation ObjCAtlasSearchPathState
{
    NSString *atlas__executablePath;
    NSMutableArray *atlas__searchPathStack;
}

// Preserve the original explicit property storage after renaming.
@synthesize executablePath = atlas__executablePath;
@synthesize atlas_searchPathStack = atlas__searchPathStack;

- (id)init;
{
    if ((self = [super init])) {
        atlas__executablePath = nil;
        atlas__searchPathStack = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark -

- (void)atlas_pushSearchPaths:(NSArray *)atlas_searchPaths;
{
    [self.atlas_searchPathStack addObject:atlas_searchPaths];
}

- (void)atlas_popSearchPaths;
{
    if ([self.atlas_searchPathStack count] > 0) {
        [self.atlas_searchPathStack removeLastObject];
    } else {
        NSLog(@"Warning: Unbalanced popSearchPaths");
    }
}

- (NSArray *)atlas_searchPaths;
{
    NSMutableArray *atlas_result = [NSMutableArray array];
    for (NSArray *atlas_group in self.atlas_searchPathStack) {
        [atlas_result addObjectsFromArray:atlas_group];
    }

    return [atlas_result copy];
}

@end
