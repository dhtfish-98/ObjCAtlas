// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <mach-o/reloc.h>

typedef enum : NSUInteger {
    atlas_CDRelocationInfoSize_8Bit  = 0,
    atlas_CDRelocationInfoSize_16Bit = 1,
    atlas_CDRelocationInfoSize_32Bit = 2,
    atlas_CDRelocationInfoSize_64Bit = 3,
} atlas_CDRelocationSize;

@interface ObjCAtlasRelocationInfo : NSObject

- (id)initAtlasWithInfo:(struct relocation_info)atlas_info;

@property (nonatomic, readonly) NSUInteger atlas_offset;
@property (nonatomic, readonly) atlas_CDRelocationSize atlas_size;
@property (nonatomic, readonly) uint32_t atlas_symbolnum;
@property (nonatomic, readonly) BOOL atlas_isExtern;

@end
