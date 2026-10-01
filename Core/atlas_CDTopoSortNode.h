// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTopologicalSortProtocol.h"

typedef enum : NSUInteger {
    atlas_CDNodeColor_White = 0,
    atlas_CDNodeColor_Gray  = 1,
    atlas_CDNodeColor_Black = 2,
} atlas_CDNodeColor;

@interface ObjCAtlasTopoSortNode : NSObject

- (id)initWithObject:(id <ObjCAtlasTopologicalSort>)atlas_object;

@property (nonatomic, readonly) NSString *identifier;
@property (readonly) id <ObjCAtlasTopologicalSort> atlas_sortableObject;

- (NSArray *)atlas_dependancies;
- (void)atlas_addDependancy:(NSString *)atlas_identifier;
- (void)atlas_removeDependancy:(NSString *)atlas_identifier;
- (void)atlas_addDependanciesFromArray:(NSArray *)atlas_identifiers;
@property (nonatomic, readonly) NSString *atlas_dependancyDescription;

@property (assign) atlas_CDNodeColor atlas_color;

- (NSComparisonResult)atlas_ascendingCompareByIdentifier:(ObjCAtlasTopoSortNode *)atlas_other;
- (void)atlas_topologicallySortNodes:(NSDictionary *)atlas_nodesByIdentifier atlas_intoArray:(NSMutableArray *)atlas_sortedArray;

@end
