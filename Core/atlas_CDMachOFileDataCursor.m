// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDMachOFileDataCursor.h"

#import "atlas_CDMachOFile.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDSection.h"

@implementation ObjCAtlasMachOFileDataCursor
{
    __weak ObjCAtlasMachOFile *atlas__machOFile;
    NSUInteger atlas__ptrSize;
    atlas_CDByteOrder atlas__byteOrder;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_machOFile = atlas__machOFile;

- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    return [self initAtlasWithFile:atlas_machOFile atlas_offset:0];
}

- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_offset:(NSUInteger)atlas_offset;
{
    if ((self = [super initWithData:atlas_machOFile.data])) {
        self.atlas_machOFile = atlas_machOFile;
        [self setAtlas_offset:atlas_offset];
    }

    return self;
}

- (id)initAtlasWithFile:(ObjCAtlasMachOFile *)atlas_machOFile atlas_address:(NSUInteger)atlas_address;
{
    if ((self = [super initWithData:atlas_machOFile.data])) {
        self.atlas_machOFile = atlas_machOFile;
        [self atlas_setAddress:atlas_address];
    }

    return self;
}

- (id)initAtlasWithSection:(ObjCAtlasSection *)atlas_section;
{
    if ((self = [super initWithData:[atlas_section data]])) {
        self.atlas_machOFile = atlas_section.atlas_segment.atlas_machOFile;
    }

    return self;
}

#pragma mark -

- (void)setAtlas_machOFile:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    atlas__machOFile = atlas_machOFile;
    atlas__ptrSize = atlas_machOFile.atlas_ptrSize;
    atlas__byteOrder = atlas_machOFile.atlas_byteOrder;
}

- (void)atlas_setAddress:(NSUInteger)atlas_address;
{
    NSUInteger atlas_dataOffset = [atlas__machOFile atlas_dataOffsetForAddress:atlas_address];
    [self setAtlas_offset:atlas_dataOffset];
}

#pragma mark - Read using the current byteOrder

- (uint16_t)atlas_readInt16;
{
    if (atlas__byteOrder == atlas_CDByteOrder_LittleEndian)
        return [self atlas_readLittleInt16];

    return [self atlas_readBigInt16];
}

- (uint32_t)atlas_readInt32;
{
    if (atlas__byteOrder == atlas_CDByteOrder_LittleEndian)
        return [self atlas_readLittleInt32];

    return [self atlas_readBigInt32];
}

- (uint64_t)atlas_readInt64;
{
    if (atlas__byteOrder == atlas_CDByteOrder_LittleEndian)
        return [self atlas_readLittleInt64];

    return [self atlas_readBigInt64];
}

- (uint32_t)atlas_peekInt32;
{
    NSUInteger atlas_savedOffset = self.atlas_offset;
    uint32_t atlas_val = [self atlas_readInt32];
    self.atlas_offset = atlas_savedOffset;
    
    return atlas_val;
}

- (uint64_t)atlas_readPtr;
{
    switch (atlas__ptrSize) {
        case sizeof(uint32_t): return [self atlas_readInt32];
        case sizeof(uint64_t): return [self atlas_readInt64];
    }
    [NSException raise:NSInternalInconsistencyException format:@"The ptrSize must be either 4 (32-bit) or 8 (64-bit)"];
    return 0;
}

@end
