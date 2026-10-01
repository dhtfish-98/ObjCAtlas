// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDSymbol.h"

#import <mach-o/nlist.h>
#import <mach-o/loader.h>
#import "atlas_CDMachOFile.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDSection.h"

NSString *const atlas_ObjCClassSymbolPrefix = @"_OBJC_CLASS_$_";

@interface ObjCAtlasSymbol ()
@property (weak, readonly) ObjCAtlasMachOFile *atlas_machOFile;
@end

#pragma mark -

@implementation ObjCAtlasSymbol
{
    struct nlist_64 atlas__nlist;
    BOOL atlas__is32Bit;
    NSString *atlas__name;
    __weak ObjCAtlasMachOFile *atlas__machOFile;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_machOFile = atlas__machOFile;

- (id)initAtlasWithName:(NSString *)atlas_name atlas_machOFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_nlist32:(struct nlist)atlas_nlist32;
{
    if ((self = [super init])) {
        atlas__is32Bit = YES;
        atlas__name = atlas_name;
        atlas__machOFile = atlas_machOFile;
        atlas__nlist.n_un.n_strx = 0; // We don't use it.
        atlas__nlist.n_type      = atlas_nlist32.n_type;
        atlas__nlist.n_sect      = atlas_nlist32.n_sect;
        atlas__nlist.n_desc      = atlas_nlist32.n_desc;
        atlas__nlist.n_value     = atlas_nlist32.n_value;
    }

    return self;
}

- (id)initAtlasWithName:(NSString *)atlas_name atlas_machOFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_nlist64:(struct nlist_64)atlas_nlist64;
{
    if ((self = [super init])) {
        atlas__is32Bit = NO;
        atlas__name = atlas_name;
        atlas__machOFile = atlas_machOFile;
        atlas__nlist.n_un.n_strx = 0; // We don't use it.
        atlas__nlist.n_type      = atlas_nlist64.n_type;
        atlas__nlist.n_sect      = atlas_nlist64.n_sect;
        atlas__nlist.n_desc      = atlas_nlist64.n_desc;
        atlas__nlist.n_value     = atlas_nlist64.n_value;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    NSString *atlas_valueString;

    if (self.atlas_isDefined) {
        atlas_valueString = [NSString stringWithFormat:(atlas__is32Bit ? @"%08llx" : @"%016llx"), self.value];
    } else {
        atlas_valueString = [@" " stringByPaddingToLength:(atlas__is32Bit ? 8 : 16) withString:@" " startingAtIndex:0];
    }

    return [NSString stringWithFormat:@"%@ %@ %@", atlas_valueString, [self atlas_shortTypeDescription], self.name];
}

#pragma mark -

+ (NSString *)atlas_classNameFromSymbolName:(NSString *)atlas_symbolName;
{
    if ([atlas_symbolName hasPrefix:atlas_ObjCClassSymbolPrefix])
        return [atlas_symbolName substringFromIndex:[atlas_ObjCClassSymbolPrefix length]];
    else
        return nil;
}

- (uint64_t)value;
{
    return atlas__nlist.n_value;
}

- (ObjCAtlasSection *)atlas_section;
{
    // We might be tempted to do [[self.machOFile segmentContainingAddress:nlist.n_value] sectionContainingAddress:nlist.n_value]
    // but this does not work for __mh_dylib_header for example (n_value == 0, but it is in the __TEXT,__text section)
    NSMutableArray *atlas_sections = [NSMutableArray array];
    for (ObjCAtlasLCSegment *atlas_segment in self.atlas_machOFile.atlas_segments) {
        for (ObjCAtlasSection *atlas_section in [atlas_segment atlas_sections])
            [atlas_sections addObject:atlas_section];
    }

    // n_sect is 1-indexed (NO_SECT == 0)
    NSUInteger atlas_sectionIndex = atlas__nlist.n_sect - 1;
    if (atlas_sectionIndex < [atlas_sections count])
        return atlas_sections[atlas_sectionIndex];
    else
        return nil;
}

- (ObjCAtlasLCDylib *)atlas_dylibLoadCommand;
{
    NSUInteger atlas_libraryOrdinal = GET_LIBRARY_ORDINAL(atlas__nlist.n_desc);
    return [self.atlas_machOFile atlas_dylibLoadCommandForLibraryOrdinal:atlas_libraryOrdinal];
}

- (BOOL)isExternal;
{
    return (atlas__nlist.n_type & N_EXT) == N_EXT;
}

- (BOOL)atlas_isPrivateExternal;
{
    return (atlas__nlist.n_type & N_PEXT) == N_PEXT;
}

- (NSUInteger)atlas_stab;
{
    return atlas__nlist.n_type & N_STAB;
}

- (NSUInteger)type;
{
    return atlas__nlist.n_type & N_TYPE;
}

- (BOOL)atlas_isDefined;
{
    return self.type != N_UNDF;
}

- (BOOL)atlas_isAbsolute;
{
    return self.type == N_ABS;
}

- (BOOL)atlas_isInSection;
{
    return self.type == N_SECT;
}

- (BOOL)atlas_isPrebound;
{
    return self.type == N_PBUD;
}

- (BOOL)atlas_isIndirect;
{
    return self.type == N_INDR;
}

- (BOOL)atlas_isCommon;
{
    return !self.atlas_isDefined && self.isExternal && atlas__nlist.n_value != 0;
}

- (BOOL)atlas_isInTextSection;
{
    ObjCAtlasSection *atlas_section = self.atlas_section;
    return [atlas_section.atlas_segmentName isEqualToString:@"__TEXT"] && [atlas_section.atlas_sectionName isEqualToString:@"__text"];
}

- (BOOL)atlas_isInDataSection;
{
    ObjCAtlasSection *atlas_section = self.atlas_section;
    return [atlas_section.atlas_segmentName isEqualToString:@"__DATA"] && [atlas_section.atlas_sectionName isEqualToString:@"__data"];
}

- (BOOL)atlas_isInBssSection;
{
    ObjCAtlasSection *atlas_section = self.atlas_section;
    return [atlas_section.atlas_segmentName isEqualToString:@"__DATA"] && [atlas_section.atlas_sectionName isEqualToString:@"__bss"];
}

- (NSUInteger)atlas_referenceType;
{
    return (atlas__nlist.n_desc & REFERENCE_TYPE);
}

- (NSString *)atlas_referenceTypeName
{
    switch (self.atlas_referenceType) {
        case REFERENCE_FLAG_UNDEFINED_NON_LAZY:         return @"undefined non lazy";
        case REFERENCE_FLAG_UNDEFINED_LAZY:             return @"undefined lazy";
        case REFERENCE_FLAG_DEFINED:                    return @"defined";
        case REFERENCE_FLAG_PRIVATE_DEFINED:            return @"private defined";
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: return @"private undefined non lazy";
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:     return @"private undefined lazy";
    }
    return nil;
}

- (NSComparisonResult)compare:(ObjCAtlasSymbol *)atlas_other;
{
    if (atlas_other.value > self.value) return NSOrderedAscending;
    if (atlas_other.value < self.value) return NSOrderedDescending;

    return NSOrderedSame;
}

- (NSComparisonResult)atlas_compareByName:(ObjCAtlasSymbol *)atlas_other;
{
    return [self.name compare:atlas_other.name];
}

- (NSString *)atlas_shortTypeDescription;
{
    NSString *atlas_c;

    if (self.atlas_stab)                               atlas_c = @"-";
    else if (self.atlas_isCommon)                      atlas_c = @"c";
    else if (!self.atlas_isDefined || self.atlas_isPrebound) atlas_c = @"u";
    else if (self.atlas_isAbsolute)                    atlas_c = @"a";
    else if (self.atlas_isInSection) {
        if (self.atlas_isInTextSection)                atlas_c = @"t";
        else if (self.atlas_isInDataSection)           atlas_c = @"d";
        else if (self.atlas_isInBssSection)            atlas_c = @"b";
        else                                     atlas_c = @"s";
    }
    else if (self.atlas_isIndirect)                    atlas_c = @"i";
    else                                         atlas_c = @"?";

    return self.isExternal ? [atlas_c uppercaseString] : atlas_c;
}

- (NSString *)atlas_longTypeDescription;
{
    NSString *atlas_c;

    if (self.atlas_isCommon)                           atlas_c = @"common";
    else if (!self.atlas_isDefined)                    atlas_c =  @"undefined";
    else if (self.atlas_isPrebound)                    atlas_c =  @"prebound";
    else if (self.atlas_isAbsolute)                    atlas_c =  @"absolute";
    else if (self.atlas_isInSection) {
        ObjCAtlasSection *atlas_section = self.atlas_section;
        if (atlas_section)                             atlas_c = [NSString stringWithFormat:@"%@,%@", atlas_section.atlas_segmentName, atlas_section.atlas_sectionName];
        else                                     atlas_c = @"?,?";
    }
    else if (self.atlas_isIndirect)                    atlas_c = @"indirect";
    else                                         atlas_c = @"?";

    return atlas_c;
}

@end
