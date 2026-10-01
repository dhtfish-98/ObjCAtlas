// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasMachOFileDataCursor;
@class ObjCAtlasLCSegment;

@interface ObjCAtlasSection : NSObject

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor atlas_segment:(ObjCAtlasLCSegment *)atlas_segment;

@property (weak, readonly) ObjCAtlasLCSegment *atlas_segment;

@property (nonatomic, readonly) NSData *data;

@property (nonatomic, readonly) NSString *atlas_segmentName;
@property (nonatomic, readonly) NSString *atlas_sectionName;

@property (nonatomic, readonly) NSUInteger atlas_addr;
@property (nonatomic, readonly) NSUInteger atlas_size;

- (BOOL)atlas_containsAddress:(NSUInteger)atlas_address;
- (NSUInteger)atlas_fileOffsetForAddress:(NSUInteger)atlas_address;

@end
