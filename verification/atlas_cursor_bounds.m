// Copyright (c) 2026 dhtfish98
#import <Foundation/Foundation.h>
#import <sys/mman.h>
#import <unistd.h>
#import "atlas_CDDataCursor.h"

static void require(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

static void requireRangeException(void (^operation)(void), NSString *message)
{
    @try {
        operation();
    } @catch (NSException *exception) {
        require([exception.name isEqualToString:NSRangeException], message);
        return;
    }
    require(NO, message);
}

int main(void)
{
    @autoreleasepool {
        size_t pageSize = (size_t)sysconf(_SC_PAGESIZE);
        void *mapping = mmap(NULL, pageSize * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        require(mapping != MAP_FAILED, @"allocate guard pages");
        require(mprotect((uint8_t *)mapping + pageSize, pageSize, PROT_NONE) == 0, @"protect guard page");
        uint8_t *lastByte = (uint8_t *)mapping + pageSize - 1;
        *lastByte = 0x7f;
        NSData *oneByte = [NSData dataWithBytesNoCopy:lastByte length:1 freeWhenDone:NO];
        require(oneByte.bytes == lastByte, @"NSData retains the guard-page boundary");
        ObjCAtlasDataCursor *cursor = [[ObjCAtlasDataCursor alloc] initWithData:oneByte];
        require([cursor atlas_readByte] == 0x7f && cursor.atlas_offset == 1, @"one-byte read at mapped boundary");
        requireRangeException(^{ (void)[cursor atlas_readByte]; }, @"read beyond final byte");
        requireRangeException(^{ [cursor atlas_advanceByLength:NSUIntegerMax]; }, @"overflowing advance");
        require(cursor.atlas_offset == 1, @"failed advance keeps offset");
        cursor.atlas_offset = 0;
        requireRangeException(^{ (void)[cursor atlas_readCString]; }, @"unterminated string at guard page");
        requireRangeException(^{ (void)[cursor atlas_readStringOfLength:NSUIntegerMax atlas_encoding:NSASCIIStringEncoding]; }, @"overflowing string length");
        require(cursor.atlas_offset == 0, @"failed string reads keep offset");
        require(munmap(mapping, pageSize * 2) == 0, @"unmap guard pages");

        uint8_t padded[] = {'a', 0, 'x'};
        cursor = [[ObjCAtlasDataCursor alloc] initWithData:[NSData dataWithBytes:padded length:sizeof(padded)]];
        require([[cursor atlas_readStringOfLength:3 atlas_encoding:NSASCIIStringEncoding] isEqualToString:@"a"], @"padded ASCII retains prior value");
        require(cursor.atlas_offset == 3, @"padded ASCII consumes fixed width");
        cursor.atlas_offset = 0;
        require([[cursor atlas_readCString] isEqualToString:@"a"], @"terminated C string");
        require(cursor.atlas_offset == 1, @"C string preserves terminator position");
        puts("PASS: guarded byte, overflow lengths, unterminated and padded strings");
    }
    return 0;
}
