// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_ULEB128.h"

uint64_t atlas_read_uleb128(const uint8_t **atlas_ptrptr, const uint8_t *atlas_end)
{
    const uint8_t *atlas_ptr = *atlas_ptrptr;
    uint64_t atlas_result = 0;
    int atlas_bit = 0;
    
    //NSLog(@"read_uleb128()");
    do {
        NSCAssert(atlas_ptr != atlas_end, @"Malformed uleb128", nil);
        
        //NSLog(@"byte: %02x", *ptr);
        uint64_t atlas_slice = *atlas_ptr & 0x7f;
        
        if (atlas_bit >= 64 || atlas_slice << atlas_bit >> atlas_bit != atlas_slice) {
            NSLog(@"uleb128 too big");
            exit(88);
        } else {
            atlas_result |= (atlas_slice << atlas_bit);
            atlas_bit += 7;
        }
    }
    while ((*atlas_ptr++ & 0x80) != 0);
    
#if 0
    static NSUInteger maxlen = 0;
    if (maxlen < ptr - *ptrptr) {
        const uint8_t *ptr2 = *ptrptr;
        
        NSMutableArray *byteStrs = [NSMutableArray array];
        do {
            [byteStrs addObject:[NSString stringWithFormat:@"%02x", *ptr2]];
        } while (++ptr2 < ptr);
        //NSLog(@"max uleb length now: %u (%@)", ptr - *ptrptr, [byteStrs componentsJoinedByString:@" "]);
        //NSLog(@"sizeof(uint64_t): %u, sizeof(uintptr_t): %u", sizeof(uint64_t), sizeof(uintptr_t));
        maxlen = ptr - *ptrptr;
    }
#endif
    
    *atlas_ptrptr = atlas_ptr;
    return atlas_result;
}

int64_t atlas_read_sleb128(const uint8_t **atlas_ptrptr, const uint8_t *atlas_end)
{
    const uint8_t *atlas_ptr = *atlas_ptrptr;
    
    int64_t atlas_result = 0;
    int atlas_bit = 0;
    uint8_t atlas_byte;
    
    //NSLog(@"read_sleb128()");
    do {
        NSCAssert(atlas_ptr != atlas_end, @"Malformed sleb128", nil);
        
        atlas_byte = *atlas_ptr++;
        //NSLog(@"%02x", byte);
        atlas_result |= ((atlas_byte & 0x7f) << atlas_bit);
        atlas_bit += 7;
    } while ((atlas_byte & 0x80) != 0);
    
    //NSLog(@"result before sign extend: %ld", result);
    // sign extend negative numbers
    // This essentially clears out from -1 the low order bits we've already set, and combines that with our bits.
    if ( (atlas_byte & 0x40) != 0 )
        atlas_result |= (-1LL) << atlas_bit;
    
    //NSLog(@"result after sign extend: %ld", result);
    
    //NSLog(@"ptr before: %p, after: %p", *ptrptr, ptr);
    *atlas_ptrptr = atlas_ptr;
    return atlas_result;
}
