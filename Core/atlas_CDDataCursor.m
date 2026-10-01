// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDDataCursor.h"

@implementation ObjCAtlasDataCursor
{
    NSData *atlas__data;
    NSUInteger atlas__offset;
}

// Preserve the original explicit property storage after renaming.
@synthesize data = atlas__data;
@synthesize atlas_offset = atlas__offset;

- (id)initWithData:(NSData *)atlas_data;
{
    if ((self = [super init])) {
        atlas__data = atlas_data;
        atlas__offset = 0;
    }

    return self;
}

#pragma mark -

- (const void *)bytes;
{
    return [atlas__data bytes];
}

- (void)setAtlas_offset:(NSUInteger)atlas_newOffset;
{
    if (atlas_newOffset <= [atlas__data length]) {
        atlas__offset = atlas_newOffset;
    } else {
        [NSException raise:NSRangeException format:@"Trying to seek past end of data."];
    }
}

- (void)atlas_advanceByLength:(NSUInteger)atlas_length;
{
    if (atlas__offset + atlas_length <= [atlas__data length]) {
        atlas__offset += atlas_length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to advance past end of data."];
    }
}

- (NSUInteger)atlas_remaining;
{
    return [atlas__data length] - atlas__offset;
}

#pragma mark -

- (uint8_t)atlas_readByte;
{
    uint8_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadLittleInt16([atlas__data bytes], atlas__offset) & 0xFF;
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint16_t)atlas_readLittleInt16;
{
    uint16_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadLittleInt16([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint32_t)atlas_readLittleInt32;
{
    uint32_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadLittleInt32([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint64_t)atlas_readLittleInt64;
{
    uint64_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
//        uint8_t *ptr = [_data bytes] + _offset;
//        NSLog(@"%016llx: %02x %02x %02x %02x %02x %02x %02x %02x", _offset, ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7]);
        atlas_result = OSReadLittleInt64([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint16_t)atlas_readBigInt16;
{
    uint16_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadBigInt16([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint32_t)atlas_readBigInt32;
{
    uint32_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadBigInt32([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (uint64_t)atlas_readBigInt64;
{
    uint64_t atlas_result;

    if (atlas__offset + sizeof(atlas_result) <= [atlas__data length]) {
        atlas_result = OSReadBigInt64([atlas__data bytes], atlas__offset);
        atlas__offset += sizeof(atlas_result);
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
        atlas_result = 0;
    }

    return atlas_result;
}

- (float)atlas_readLittleFloat32;
{
    uint32_t atlas_val;

    atlas_val = [self atlas_readLittleInt32];
    return *(float *)&atlas_val;
}

- (float)atlas_readBigFloat32;
{
    uint32_t atlas_val;

    atlas_val = [self atlas_readBigInt32];
    return *(float *)&atlas_val;
}

- (double)atlas_readLittleFloat64;
{
    uint32_t atlas_v1, atlas_v2, *atlas_ptr;
    double atlas_dval;

    atlas_v1 = [self atlas_readLittleInt32];
    atlas_v2 = [self atlas_readLittleInt32];
    atlas_ptr = (uint32_t *)&atlas_dval;
    *atlas_ptr++ = atlas_v1;
    *atlas_ptr = atlas_v2;

    return atlas_dval;
}

- (void)atlas_appendBytesOfLength:(NSUInteger)atlas_length atlas_intoData:(NSMutableData *)atlas_data;
{
    if (atlas__offset + atlas_length <= [atlas__data length]) {
        [atlas_data appendBytes:(uint8_t *)[atlas__data bytes] + atlas__offset length:atlas_length];
        atlas__offset += atlas_length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
    }
}

- (void)atlas_readBytesOfLength:(NSUInteger)atlas_length atlas_intoBuffer:(void *)atlas_buf;
{
    if (atlas__offset + atlas_length <= [atlas__data length]) {
        memcpy(atlas_buf, (uint8_t *)[atlas__data bytes] + atlas__offset, atlas_length);
        atlas__offset += atlas_length;
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
    }
}

- (BOOL)isAtEnd;
{
    return atlas__offset >= [atlas__data length];
}

- (NSString *)atlas_readCString;
{
    return [self atlas_readStringOfLength:strlen((const char *)[atlas__data bytes] + atlas__offset) atlas_encoding:NSASCIIStringEncoding];
}

- (NSString *)atlas_readStringOfLength:(NSUInteger)atlas_length atlas_encoding:(NSStringEncoding)atlas_encoding;
{
    if (atlas__offset + atlas_length <= [atlas__data length]) {
        NSString *atlas_str;

        if (atlas_encoding == NSASCIIStringEncoding) {
            char *atlas_buf;

            // Jump through some hoops if the length is padded with zero bytes, as in the case of 10.5's Property List Editor and iSync Plug-in Maker.
            atlas_buf = malloc(atlas_length + 1);
            if (atlas_buf == NULL) {
                NSLog(@"Error: malloc() failed.");
                return nil;
            }

            strncpy(atlas_buf, (const char *)[atlas__data bytes] + atlas__offset, atlas_length);
            atlas_buf[atlas_length] = 0;

            atlas_str = [[NSString alloc] initWithBytes:atlas_buf length:strlen(atlas_buf) encoding:atlas_encoding];
            atlas__offset += atlas_length;
            free(atlas_buf);
            return atlas_str;
        } else {
            atlas_str = [[NSString alloc] initWithBytes:(uint8_t *)[atlas__data bytes] + atlas__offset length:atlas_length encoding:atlas_encoding];
            atlas__offset += atlas_length;
            return atlas_str;
        }
    } else {
        [NSException raise:NSRangeException format:@"Trying to read past end in %s", atlas___cmd];
    }

    return nil;
}

@end
