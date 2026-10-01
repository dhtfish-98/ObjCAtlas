// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTopoSortNode.h"

@implementation ObjCAtlasTopoSortNode
{
    id <ObjCAtlasTopologicalSort> atlas__sortableObject;
    
    NSMutableSet *atlas__dependancies;
    atlas_CDNodeColor atlas__color;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_sortableObject = atlas__sortableObject;
@synthesize atlas_color = atlas__color;

- (id)initWithObject:(id <ObjCAtlasTopologicalSort>)atlas_object;
{
    if ((self = [super init])) {
        atlas__sortableObject = atlas_object;
        atlas__dependancies = [[NSMutableSet alloc] init];
        atlas__color = atlas_CDNodeColor_White;

        [self atlas_addDependanciesFromArray:[atlas__sortableObject atlas_dependancies]];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@ (%lu) depends on %@", self.identifier, self.atlas_color, self.atlas_dependancyDescription];
}

#pragma mark -

- (NSString *)identifier;
{
    return self.atlas_sortableObject.identifier;
}

- (NSArray *)atlas_dependancies;
{
    return [atlas__dependancies allObjects];
}

- (void)atlas_addDependancy:(NSString *)atlas_identifier;
{
    [atlas__dependancies addObject:atlas_identifier];
}

- (void)atlas_removeDependancy:(NSString *)atlas_identifier;
{
    [atlas__dependancies removeObject:atlas_identifier];
}

- (void)atlas_addDependanciesFromArray:(NSArray *)atlas_identifiers;
{
    [atlas__dependancies addObjectsFromArray:atlas_identifiers];
}

- (NSString *)atlas_dependancyDescription;
{
    return [[atlas__dependancies allObjects] componentsJoinedByString:@", "];
}

#pragma mark - Sorting

- (NSComparisonResult)atlas_ascendingCompareByIdentifier:(ObjCAtlasTopoSortNode *)atlas_other;
{
    return [self.identifier compare:atlas_other.identifier];
}

- (void)atlas_topologicallySortNodes:(NSDictionary *)atlas_nodesByIdentifier atlas_intoArray:(NSMutableArray *)atlas_sortedArray;
{
    NSArray *atlas_dependantIdentifiers = [self atlas_dependancies];

    for (NSString *atlas_identifier in atlas_dependantIdentifiers) {
        ObjCAtlasTopoSortNode *atlas_node = atlas_nodesByIdentifier[atlas_identifier];
        if (atlas_node.atlas_color == atlas_CDNodeColor_White) {
            atlas_node.atlas_color = atlas_CDNodeColor_Gray;
            [atlas_node atlas_topologicallySortNodes:atlas_nodesByIdentifier atlas_intoArray:atlas_sortedArray];
        } else if (atlas_node.atlas_color == atlas_CDNodeColor_Gray) {
            NSLog(@"Warning: Possible circular reference? %@ -> %@", self.identifier, atlas_node.identifier);
        }
    }

    [atlas_sortedArray addObject:[self atlas_sortableObject]];
    self.atlas_color = atlas_CDNodeColor_Black;
}

@end
