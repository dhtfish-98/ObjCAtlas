// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType;

@interface ObjCAtlasStructureInfo : NSObject <NSCopying>

- (id)initAtlasWithType:(ObjCAtlasType *)atlas_type;

- (NSString *)atlas_shortDescription;

@property (readonly) ObjCAtlasType *type;

@property (assign) NSUInteger atlas_referenceCount;
- (void)atlas_addReferenceCount:(NSUInteger)atlas_count;

@property (assign) BOOL atlas_isUsedInMethod;
@property (strong) NSString *atlas_typedefName;

- (void)atlas_generateTypedefName:(NSString *)atlas_baseName;

@property (nonatomic, readonly) NSString *name;

- (NSComparisonResult)atlas_ascendingCompareByStructureDepth:(ObjCAtlasStructureInfo *)atlas_other;
- (NSComparisonResult)atlas_descendingCompareByStructureDepth:(ObjCAtlasStructureInfo *)atlas_other;

@end
