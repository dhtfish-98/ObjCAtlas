// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFile.h"

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t
#include <mach-o/loader.h>

typedef enum : NSUInteger {
    atlas_CDByteOrder_LittleEndian = 0,
    atlas_CDByteOrder_BigEndian = 1,
} atlas_CDByteOrder;

@class ObjCAtlasLCSegment;
@class ObjCAtlasLCBuildVersion, ObjCAtlasLCDyldInfo, ObjCAtlasLCDylib, ObjCAtlasMachOFile, ObjCAtlasLCSymbolTable, ObjCAtlasLCDynamicSymbolTable, ObjCAtlasLCVersionMinimum, ObjCAtlasLCSourceVersion;

@interface ObjCAtlasMachOFile : ObjCAtlasFile

@property (readonly) atlas_CDByteOrder atlas_byteOrder;

@property (readonly) uint32_t atlas_magic;
@property (assign) cpu_type_t atlas_cputype;
@property (assign) cpu_subtype_t atlas_cpusubtype;
@property (readonly) uint32_t atlas_filetype;
@property (readonly) uint32_t atlas_flags;

@property (nonatomic, readonly) cpu_type_t atlas_maskedCPUType;
@property (nonatomic, readonly) cpu_subtype_t atlas_maskedCPUSubtype;

@property (readonly) NSArray *atlas_loadCommands;
@property (readonly) NSArray *atlas_dylibLoadCommands;
@property (readonly) NSArray *atlas_segments;
@property (readonly) NSArray *atlas_runPaths;
@property (readonly) NSArray *atlas_runPathCommands;
@property (readonly) NSArray *atlas_dyldEnvironment;
@property (readonly) NSArray *atlas_reExportedDylibs;

@property (strong) ObjCAtlasLCSymbolTable *atlas_symbolTable;
@property (strong) ObjCAtlasLCDynamicSymbolTable *atlas_dynamicSymbolTable;
@property (strong) ObjCAtlasLCDyldInfo *atlas_dyldInfo;
@property (strong) ObjCAtlasLCDylib *atlas_dylibIdentifier;
@property (strong) ObjCAtlasLCVersionMinimum *atlas_minVersionMacOSX;
@property (strong) ObjCAtlasLCVersionMinimum *atlas_minVersionIOS;
@property (strong) ObjCAtlasLCSourceVersion *atlas_sourceVersion;
@property (strong) ObjCAtlasLCBuildVersion *atlas_buildVersion;

@property (readonly) BOOL atlas_uses64BitABI;
- (NSUInteger)atlas_ptrSize;

- (NSString *)atlas_filetypeDescription;
- (NSString *)atlas_flagDescription;

- (ObjCAtlasLCSegment *)atlas_dataConstSegment;
- (ObjCAtlasLCSegment *)atlas_segmentWithName:(NSString *)atlas_segmentName;
- (ObjCAtlasLCSegment *)atlas_segmentContainingAddress:(NSUInteger)atlas_address;
- (NSString *)atlas_stringAtAddress:(NSUInteger)atlas_address;

- (NSUInteger)atlas_dataOffsetForAddress:(NSUInteger)atlas_address;

- (const void *)bytes;
- (const void *)atlas_bytesAtOffset:(NSUInteger)atlas_offset;
- (NSData *)atlas_dataAtOffset:(NSUInteger)atlas_offset length:(NSUInteger)atlas_length;

@property (nonatomic, readonly) NSString *atlas_importBaseName;

@property (nonatomic, readonly) BOOL atlas_isEncrypted;
@property (nonatomic, readonly) BOOL atlas_hasProtectedSegments;
@property (nonatomic, readonly) BOOL atlas_canDecryptAllSegments;

- (NSString *)atlas_loadCommandString:(BOOL)atlas_isVerbose;
- (NSString *)atlas_headerString:(BOOL)atlas_isVerbose;

@property (nonatomic, readonly) NSUUID *UUID;
@property (nonatomic, readonly) NSString *atlas_archName;

- (Class)atlas_processorClass;
- (void)atlas_logInfoForAddress:(NSUInteger)atlas_address;

- (NSString *)atlas_externalClassNameForAddress:(NSUInteger)atlas_address;
- (BOOL)atlas_hasRelocationEntryForAddress:(NSUInteger)atlas_address;

// Checks compressed dyld info on 10.6 or later.
- (BOOL)atlas_hasRelocationEntryForAddress2:(NSUInteger)atlas_address;
- (NSString *)atlas_externalClassNameForAddress2:(NSUInteger)atlas_address;

- (ObjCAtlasLCDylib *)atlas_dylibLoadCommandForLibraryOrdinal:(NSUInteger)atlas_ordinal;

@property (nonatomic, readonly) BOOL atlas_hasObjectiveC1Data;
@property (nonatomic, readonly) BOOL atlas_hasObjectiveC2Data;
@property (nonatomic, readonly) Class atlas_processorClass;

@end
