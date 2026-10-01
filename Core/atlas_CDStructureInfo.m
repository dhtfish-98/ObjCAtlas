// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDStructureInfo.h"

#import "atlas_CDType.h"
#import "atlas_CDTypeName.h"

// If it's used in a method, then it should be declared at the top. (name or typedef)

@implementation ObjCAtlasStructureInfo
{
    ObjCAtlasType *atlas__type;
    NSUInteger atlas__referenceCount;
    BOOL atlas__isUsedInMethod;
    NSString *atlas__typedefName;
}

// Preserve the original explicit property storage after renaming.
@synthesize type = atlas__type;
@synthesize atlas_referenceCount = atlas__referenceCount;
@synthesize atlas_isUsedInMethod = atlas__isUsedInMethod;
@synthesize atlas_typedefName = atlas__typedefName;

- (id)initAtlasWithType:(ObjCAtlasType *)atlas_type;
{
    if ((self = [super init])) {
        atlas__type = [atlas_type copy];
        atlas__referenceCount = 1;
        atlas__isUsedInMethod = NO;
        atlas__typedefName = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)atlas_zone;
{
    ObjCAtlasStructureInfo *atlas_copy = [[ObjCAtlasStructureInfo alloc] initAtlasWithType:self.type]; // type gets copied
    atlas_copy.atlas_referenceCount = self.atlas_referenceCount;
    atlas_copy.atlas_isUsedInMethod = self.atlas_isUsedInMethod;
    atlas_copy.atlas_typedefName = self.atlas_typedefName;
    
    return atlas_copy;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> depth: %lu, refcount: %lu, isUsedInMethod: %u, type: %p",
            NSStringFromClass([self class]), self,
            self.type.atlas_structureDepth, self.atlas_referenceCount, self.atlas_isUsedInMethod, self.type];
}

- (NSString *)atlas_shortDescription;
{
    return [NSString stringWithFormat:@"%lu %lu m?%u %@ %@", self.type.atlas_structureDepth, self.atlas_referenceCount, self.atlas_isUsedInMethod, self.type.atlas_bareTypeString, self.type.atlas_typeString];
}

#pragma mark -

- (void)atlas_addReferenceCount:(NSUInteger)atlas_count;
{
    self.atlas_referenceCount += atlas_count;
}

// Do this before generating member names.
- (void)atlas_generateTypedefName:(NSString *)atlas_baseName;
{
    NSString *atlas_digest = [self.type.atlas_typeString atlas_SHA1DigestString];
    NSUInteger atlas_length = [atlas_digest length];
    if (atlas_length > 8)
        atlas_digest = [atlas_digest substringFromIndex:atlas_length - 8];

    self.atlas_typedefName = [NSString stringWithFormat:@"%@%@", atlas_baseName, atlas_digest];
    //NSLog(@"typedefName: %@", self.typedefName);
}

- (NSString *)name;
{
    return [self.type.atlas_typeName description];
}

#pragma mark - Sorting

// Structure depth, reallyBareTypeString, typeString
- (NSComparisonResult)atlas_ascendingCompareByStructureDepth:(ObjCAtlasStructureInfo *)atlas_other;
{
    NSUInteger atlas_thisDepth = self.type.atlas_structureDepth;
    NSUInteger atlas_otherDepth = atlas_other.type.atlas_structureDepth;

    if (atlas_thisDepth < atlas_otherDepth) return NSOrderedAscending;
    if (atlas_thisDepth > atlas_otherDepth) return NSOrderedDescending;

    NSString *atlas_str1 = self.type.atlas_reallyBareTypeString;
    NSString *atlas_str2 = atlas_other.type.atlas_reallyBareTypeString;
    NSComparisonResult atlas_result = [atlas_str1 compare:atlas_str2];
    if (atlas_result == NSOrderedSame) {
        atlas_str1 = self.type.atlas_typeString;
        atlas_str2 = atlas_other.type.atlas_typeString;
        atlas_result = [atlas_str1 compare:atlas_str2];
    }

    return atlas_result;
}

- (NSComparisonResult)atlas_descendingCompareByStructureDepth:(ObjCAtlasStructureInfo *)atlas_other;
{
    NSUInteger atlas_thisDepth = self.type.atlas_structureDepth;
    NSUInteger atlas_otherDepth = atlas_other.type.atlas_structureDepth;

    if (atlas_thisDepth < atlas_otherDepth) return NSOrderedDescending;
    if (atlas_thisDepth > atlas_otherDepth) return NSOrderedAscending;

    NSString *atlas_str1 = self.type.atlas_reallyBareTypeString;
    NSString *atlas_str2 = atlas_other.type.atlas_reallyBareTypeString;
    NSComparisonResult atlas_result = -[atlas_str1 compare:atlas_str2];
    if (atlas_result == NSOrderedSame) {
        atlas_str1 = self.type.atlas_typeString;
        atlas_str2 = atlas_other.type.atlas_typeString;
        atlas_result = -[atlas_str1 compare:atlas_str2];
    }

    return atlas_result;
}

@end
