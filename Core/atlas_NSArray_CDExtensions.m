// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_NSArray_CDExtensions.h"

@implementation NSArray (CDExtensions)

- (NSArray *)atlas_reversedArray;
{
    return [[self reverseObjectEnumerator] allObjects];
}

@end

#pragma mark -

@implementation NSArray (CDTopoSort)

- (NSArray *)atlas_topologicallySortedArray;
{
    NSMutableDictionary *atlas_nodesByName = [[NSMutableDictionary alloc] init];

    for (id <ObjCAtlasTopologicalSort> atlas_object in self) {
        ObjCAtlasTopoSortNode *atlas_node = [[ObjCAtlasTopoSortNode alloc] initWithObject:atlas_object];
        [atlas_node atlas_addDependanciesFromArray:[atlas_object atlas_dependancies]];

        if (atlas_nodesByName[atlas_node.identifier] != nil)
            NSLog(@"Warning: Duplicate identifier (%@) in %s", atlas_node.identifier, atlas___cmd);
        atlas_nodesByName[atlas_node.identifier] = atlas_node;
    }

    NSMutableArray *atlas_sortedArray = [NSMutableArray array];

    NSArray *atlas_allNodes = [[atlas_nodesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByIdentifier:)];
    for (ObjCAtlasTopoSortNode *atlas_node in atlas_allNodes) {
        if (atlas_node.atlas_color == atlas_CDNodeColor_White)
            [atlas_node atlas_topologicallySortNodes:atlas_nodesByName atlas_intoArray:atlas_sortedArray];
    }


    return atlas_sortedArray;
}

@end

#pragma mark -

@implementation NSMutableArray (CDTopoSort)

- (void)atlas_sortTopologically;
{
    NSArray *atlas_sortedArray = [self atlas_topologicallySortedArray];
    assert([self count] == [atlas_sortedArray count]);

    [self removeAllObjects];
    [self addObjectsFromArray:atlas_sortedArray];
}

@end
