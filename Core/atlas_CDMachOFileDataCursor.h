// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDDataCursor.h"

@class ObjCAtlasMachOFile, ObjCAtlasSection;

@interface ObjCAtlasMachOFileDataCursor : ObjCAtlasDataCursor

- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile;
- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_offset:(NSUInteger)atlas_offset;
- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_address:(NSUInteger)atlas_address;

- (id)initAtlasWithSection:(ObjCAtlasSection *)atlas_section;

@property (nonatomic, weak, readonly) ObjCAtlasMachOFile *atlas_machOFile;

- (void)atlas_setAddress:(NSUInteger)atlas_address;

// Read using the current byteOrder
- (uint16_t)atlas_readInt16;
- (uint32_t)atlas_readInt32;
- (uint64_t)atlas_readInt64;

- (uint32_t)atlas_peekInt32;

// Read using the current byteOrder and ptrSize (from the machOFile)
- (uint64_t)atlas_readPtr;

@end
