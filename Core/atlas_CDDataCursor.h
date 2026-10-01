// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface ObjCAtlasDataCursor : NSObject

- (id)initWithData:(NSData *)atlas_data;

@property (readonly) NSData *data;
- (const void *)bytes;

@property (nonatomic, assign) NSUInteger atlas_offset;

- (void)atlas_advanceByLength:(NSUInteger)atlas_length;
- (NSUInteger)atlas_remaining;

- (uint8_t)atlas_readByte;

- (uint16_t)atlas_readLittleInt16;
- (uint32_t)atlas_readLittleInt32;
- (uint64_t)atlas_readLittleInt64;

- (uint16_t)atlas_readBigInt16;
- (uint32_t)atlas_readBigInt32;
- (uint64_t)atlas_readBigInt64;

- (float)atlas_readLittleFloat32;
- (float)atlas_readBigFloat32;

- (double)atlas_readLittleFloat64;
//- (double)readBigFloat64;

- (void)atlas_appendBytesOfLength:(NSUInteger)atlas_length atlas_intoData:(NSMutableData *)atlas_data;
- (void)atlas_readBytesOfLength:(NSUInteger)atlas_length atlas_intoBuffer:(void *)atlas_buf;
- (BOOL)isAtEnd;

- (NSString *)atlas_readCString;
- (NSString *)atlas_readStringOfLength:(NSUInteger)atlas_length atlas_encoding:(NSStringEncoding)atlas_encoding;

@end
