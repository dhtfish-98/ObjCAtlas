// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface NSArray (CDExtensions)

- (NSArray *)atlas_reversedArray;

@end

@interface NSArray (CDTopoSort)

- (NSArray *)atlas_topologicallySortedArray;

@end

@interface NSMutableArray (CDTopoSort)

- (void)atlas_sortTopologically;

@end
