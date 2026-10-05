// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDSection.h"

#include <mach-o/loader.h>
#import "atlas_CDMachOFile.h"
#import "atlas_CDMachOFileDataCursor.h"
#import "atlas_CDLCSegment.h"

@implementation ObjCAtlasSection
{
    struct section_64 atlas__section; // 64-bit, also holding 32-bit
}

@synthesize data = _data;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor atlas_segment:(ObjCAtlasLCSegment *)atlas_segment;
{
    if ((self = [super init])) {
        _atlas_segment = atlas_segment;
        
        _atlas_sectionName = [atlas_cursor atlas_readStringOfLength:16 atlas_encoding:NSASCIIStringEncoding];
        size_t atlas_sectionNameLength = [_atlas_sectionName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        memcpy(atlas__section.sectname, [_atlas_sectionName UTF8String], MIN(atlas_sectionNameLength, sizeof(atlas__section.sectname)));
        _atlas_segmentName = [atlas_cursor atlas_readStringOfLength:16 atlas_encoding:NSASCIIStringEncoding];
        size_t atlas_segmentNameLength = [_atlas_segmentName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        memcpy(atlas__section.segname, [_atlas_segmentName UTF8String], MIN(atlas_segmentNameLength, sizeof(atlas__section.segname)));
        atlas__section.addr      = [atlas_cursor atlas_readPtr];
        atlas__section.size      = [atlas_cursor atlas_readPtr];
        atlas__section.offset    = [atlas_cursor atlas_readInt32];
        uint32_t atlas_dyldOffset = (uint32_t)(atlas__section.addr - atlas_segment.atlas_vmaddr + atlas_segment.atlas_fileoff);
        if (atlas__section.offset > 0 && atlas__section.offset != atlas_dyldOffset) {
            fprintf(stderr, "Warning: Invalid section offset 0x%08x replaced with 0x%08x in %s,%s\n", atlas__section.offset, atlas_dyldOffset, [_atlas_segmentName UTF8String], [_atlas_sectionName UTF8String]);
            atlas__section.offset = atlas_dyldOffset;
        }
        atlas__section.align     = [atlas_cursor atlas_readInt32];
        atlas__section.reloff    = [atlas_cursor atlas_readInt32];
        atlas__section.nreloc    = [atlas_cursor atlas_readInt32];
        atlas__section.flags     = [atlas_cursor atlas_readInt32];
        atlas__section.reserved1 = [atlas_cursor atlas_readInt32];
        atlas__section.reserved2 = [atlas_cursor atlas_readInt32];
        if (atlas_cursor.atlas_machOFile.atlas_uses64BitABI) {
            atlas__section.reserved3 = [atlas_cursor atlas_readInt32];
        }
    }

    return self;
}

#pragma mark -

- (NSData *)data;
{
    if (!_data) {
        _data = [self.atlas_segment.atlas_machOFile atlas_dataAtOffset:atlas__section.offset length:atlas__section.size];
    }
    return _data;
}

- (NSUInteger)atlas_addr;
{
    return atlas__section.addr;
}

- (NSUInteger)atlas_size;
{
    return atlas__section.size;
}

- (BOOL)atlas_containsAddress:(NSUInteger)atlas_address;
{
    return (atlas_address >= atlas__section.addr) && (atlas_address - atlas__section.addr < atlas__section.size);
}

- (NSUInteger)atlas_fileOffsetForAddress:(NSUInteger)atlas_address;
{
    NSParameterAssert([self atlas_containsAddress:atlas_address]);
    NSUInteger atlas_delta = atlas_address - atlas__section.addr;
    if (atlas_delta > NSUIntegerMax - atlas__section.offset) {
        [NSException raise:NSRangeException format:@"Section file offset overflow."];
    }
    return atlas__section.offset + atlas_delta;
}

#pragma mark - Debugging

- (NSString *)description;
{
    int atlas_padding = (int)self.atlas_segment.atlas_machOFile.atlas_ptrSize * 2;
    return [NSString stringWithFormat:@"<%@:%p> '%@,%-16s' addr: %0*llx, size: %0*llx",
            NSStringFromClass([self class]), self,
            self.atlas_segmentName, [self.atlas_sectionName UTF8String],
            atlas_padding, atlas__section.addr, atlas_padding, atlas__section.size];
}

@end
