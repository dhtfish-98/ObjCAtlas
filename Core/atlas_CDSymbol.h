// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <mach-o/nlist.h>

extern NSString *const atlas_ObjCClassSymbolPrefix;

@class ObjCAtlasMachOFile, ObjCAtlasSection, ObjCAtlasLCDylib;

@interface ObjCAtlasSymbol : NSObject

- (id)initAtlasWithName:(NSString *)atlas_name atlas_machOFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_nlist32:(struct nlist)atlas_nlist32;
- (id)initAtlasWithName:(NSString *)atlas_name atlas_machOFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_nlist64:(struct nlist_64)atlas_nlist64;

@property (nonatomic, readonly) uint64_t value;
@property (readonly) NSString *name;
@property (nonatomic, readonly) ObjCAtlasSection *atlas_section;
@property (nonatomic, readonly) ObjCAtlasLCDylib *atlas_dylibLoadCommand;

@property (nonatomic, readonly) BOOL isExternal;
@property (nonatomic, readonly) BOOL atlas_isPrivateExternal;
@property (nonatomic, readonly) NSUInteger atlas_stab;
@property (nonatomic, readonly) NSUInteger type;
@property (nonatomic, readonly) BOOL atlas_isDefined;
@property (nonatomic, readonly) BOOL atlas_isAbsolute;
@property (nonatomic, readonly) BOOL atlas_isInSection;
@property (nonatomic, readonly) BOOL atlas_isPrebound;
@property (nonatomic, readonly) BOOL atlas_isIndirect;
@property (nonatomic, readonly) BOOL atlas_isCommon;
@property (nonatomic, readonly) BOOL atlas_isInTextSection;
@property (nonatomic, readonly) BOOL atlas_isInDataSection;
@property (nonatomic, readonly) BOOL atlas_isInBssSection;
@property (nonatomic, readonly) NSUInteger atlas_referenceType;
@property (nonatomic, readonly) NSString *atlas_referenceTypeName;
@property (nonatomic, readonly) NSString *atlas_shortTypeDescription;
@property (nonatomic, readonly) NSString *atlas_longTypeDescription;

- (NSComparisonResult)compare:(ObjCAtlasSymbol *)atlas_other;
- (NSComparisonResult)atlas_compareByName:(ObjCAtlasSymbol *)atlas_other;

+ (NSString *)atlas_classNameFromSymbolName:(NSString *)atlas_symbolName;

@end
