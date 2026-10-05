// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCDyldInfo.h"

#import "atlas_CDMachOFile.h"

#import "atlas_CDLCSegment.h"
#import "atlas_ULEB128.h"
#include <string.h>

static BOOL atlas_debugBindOps = NO;
static BOOL atlas_debugExportedSymbols = NO;

// Can use dyldinfo(1) to view info.

static NSString *atlas_CDRebaseTypeDescription(uint8_t atlas_type)
{
    switch (atlas_type) {
        case REBASE_TYPE_POINTER:         return @"Pointer";
        case REBASE_TYPE_TEXT_ABSOLUTE32: return @"Absolute 32";
        case REBASE_TYPE_TEXT_PCREL32:    return @"PC rel 32";
    }

    return @"Unknown";
}

static NSString *atlas_CDBindTypeDescription(uint8_t atlas_type)
{
    switch (atlas_type) {
        case REBASE_TYPE_POINTER:         return @"Pointer";
        case REBASE_TYPE_TEXT_ABSOLUTE32: return @"Absolute 32";
        case REBASE_TYPE_TEXT_PCREL32:    return @"PC rel 32";
    }

    return @"Unknown";
}

@interface ObjCAtlasLCDyldInfo ()
@end

#pragma mark -

// Needs access to: list of segments

@implementation ObjCAtlasLCDyldInfo
{
    struct dyld_info_command atlas__dyldInfoCommand;
    
    NSUInteger atlas__ptrSize;
    NSMutableDictionary *atlas__symbolNamesByAddress;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__dyldInfoCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__dyldInfoCommand.rebase_off     = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.rebase_size    = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.bind_off       = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.bind_size      = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.weak_bind_off  = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.weak_bind_size = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.lazy_bind_off  = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.lazy_bind_size = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.export_off     = [atlas_cursor atlas_readInt32];
        atlas__dyldInfoCommand.export_size    = [atlas_cursor atlas_readInt32];
        
#if 0
        NSLog(@"       cmdsize: %08x", _dyldInfoCommand.cmdsize);
        NSLog(@"    rebase_off: %08x", _dyldInfoCommand.rebase_off);
        NSLog(@"   rebase_size: %08x", _dyldInfoCommand.rebase_size);
        NSLog(@"      bind_off: %08x", _dyldInfoCommand.bind_off);
        NSLog(@"     bind_size: %08x", _dyldInfoCommand.bind_size);
        NSLog(@" weak_bind_off: %08x", _dyldInfoCommand.weak_bind_off);
        NSLog(@"weak_bind_size: %08x", _dyldInfoCommand.weak_bind_size);
        NSLog(@" lazy_bind_off: %08x", _dyldInfoCommand.lazy_bind_off);
        NSLog(@"lazy_bind_size: %08x", _dyldInfoCommand.lazy_bind_size);
        NSLog(@"    export_off: %08x", _dyldInfoCommand.export_off);
        NSLog(@"   export_size: %08x", _dyldInfoCommand.export_size);
#endif
        
        atlas__ptrSize = [[atlas_cursor atlas_machOFile] atlas_ptrSize];
        
        atlas__symbolNamesByAddress = [[NSMutableDictionary alloc] init];
    }

    return self;
}

#pragma mark -

- (void)atlas_machOFileDidReadLoadCommands:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    //[self logRebaseInfo];
    [self atlas_parseBindInfo];
    [self atlas_parseWeakBindInfo];
    //[self logLazyBindInfo];
    //[self logExportedSymbols];
    
    //NSLog(@"symbolNamesByAddress: %@", symbolNamesByAddress);
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__dyldInfoCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__dyldInfoCommand.cmdsize;
}

- (NSString *)atlas_symbolNameForAddress:(NSUInteger)atlas_address;
{
    return [atlas__symbolNamesByAddress objectForKey:[NSNumber numberWithUnsignedInteger:atlas_address]];
}

#pragma mark - Rebasing

// address, slide, type
// slide is constant throughout the loop
- (void)atlas_logRebaseInfo;
{
    BOOL atlas_isDone = NO;
    NSUInteger atlas_rebaseCount = 0;

    NSArray *atlas_segments = self.atlas_machOFile.atlas_segments;
    NSParameterAssert([atlas_segments count] > 0);

    uint64_t atlas_address = [atlas_segments[0] atlas_vmaddr];
    uint8_t atlas_type = 0;

    NSLog(@"----------------------------------------------------------------------");
    NSLog(@"rebase_off: %u, rebase_size: %u", atlas__dyldInfoCommand.rebase_off, atlas__dyldInfoCommand.rebase_size);
    const uint8_t *atlas_start = (uint8_t *)[self.atlas_machOFile.data bytes] + atlas__dyldInfoCommand.rebase_off;
    const uint8_t *atlas_end = atlas_start + atlas__dyldInfoCommand.rebase_size;

    NSLog(@"address: %016llx", atlas_address);
    const uint8_t *atlas_ptr = atlas_start;
    while ((atlas_ptr < atlas_end) && atlas_isDone == NO) {
        uint8_t atlas_immediate = *atlas_ptr & REBASE_IMMEDIATE_MASK;
        uint8_t atlas_opcode = *atlas_ptr & REBASE_OPCODE_MASK;
        atlas_ptr++;

        switch (atlas_opcode) {
            case REBASE_OPCODE_DONE:
                //NSLog(@"REBASE_OPCODE: DONE");
                atlas_isDone = YES;
                break;
                
            case REBASE_OPCODE_SET_TYPE_IMM:
                //NSLog(@"REBASE_OPCODE: SET_TYPE_IMM,                       type = 0x%x // %@", immediate, CDRebaseTypeString(immediate));
                atlas_type = atlas_immediate;
                break;
                
            case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: {
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                
                //NSLog(@"REBASE_OPCODE: SET_SEGMENT_AND_OFFSET_ULEB,        segment index: %u, offset: %016lx", immediate, val);
                NSParameterAssert(atlas_immediate < [atlas_segments count]);
                atlas_address = [atlas_segments[atlas_immediate] atlas_vmaddr] + atlas_val;
                //NSLog(@"    address: %016lx", address);
                break;
            }
                
            case REBASE_OPCODE_ADD_ADDR_ULEB: {
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                
                //NSLog(@"REBASE_OPCODE: ADD_ADDR_ULEB,                      addr += %016lx", val);
                atlas_address += atlas_val;
                //NSLog(@"    address: %016lx", address);
                break;
            }
                
            case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                // I expect sizeof(uintptr_t) == sizeof(uint64_t)
                //NSLog(@"REBASE_OPCODE: ADD_ADDR_IMM_SCALED,                addr += %u * %u", immediate, sizeof(uint64_t));
                atlas_address += atlas_immediate * atlas__ptrSize;
                //NSLog(@"    address: %016lx", address);
                break;
                
            case REBASE_OPCODE_DO_REBASE_IMM_TIMES: {
                //NSLog(@"REBASE_OPCODE: DO_REBASE_IMM_TIMES,                count: %u", immediate);
                for (uint32_t atlas_index = 0; atlas_index < atlas_immediate; atlas_index++) {
                    [self atlas_rebaseAddress:atlas_address atlas_type:atlas_type];
                    atlas_address += atlas__ptrSize;
                }
                atlas_rebaseCount += atlas_immediate;
                break;
            }
                
            case REBASE_OPCODE_DO_REBASE_ULEB_TIMES: {
                uint64_t atlas_count = atlas_read_uleb128(&atlas_ptr, atlas_end);
                
                //NSLog(@"REBASE_OPCODE: DO_REBASE_ULEB_TIMES,               count: 0x%016lx", count);
                for (uint64_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    [self atlas_rebaseAddress:atlas_address atlas_type:atlas_type];
                    atlas_address += atlas__ptrSize;
                }
                atlas_rebaseCount += atlas_count;
                break;
            }
                
            case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB: {
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                // --------------------------------------------------------:
                //NSLog(@"REBASE_OPCODE: DO_REBASE_ADD_ADDR_ULEB,            addr += 0x%016lx", val);
                [self atlas_rebaseAddress:atlas_address atlas_type:atlas_type];
                atlas_address += atlas__ptrSize + atlas_val;
                atlas_rebaseCount++;
                break;
            }
                
            case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB: {
                uint64_t atlas_count = atlas_read_uleb128(&atlas_ptr, atlas_end);
                uint64_t atlas_skip = atlas_read_uleb128(&atlas_ptr, atlas_end);
                //NSLog(@"REBASE_OPCODE: DO_REBASE_ULEB_TIMES_SKIPPING_ULEB, count: %016lx, skip: %016lx", count, skip);
                for (uint64_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    [self atlas_rebaseAddress:atlas_address atlas_type:atlas_type];
                    atlas_address += atlas__ptrSize + atlas_skip;
                }
                atlas_rebaseCount += atlas_count;
                break;
            }
                
            default:
                NSLog(@"Unknown opcode op: %x, imm: %x", atlas_opcode, atlas_immediate);
                exit(99);
        }
    }

    NSLog(@"    ptr: %p, end: %p, bytes left over: %ld", atlas_ptr, atlas_end, atlas_end - atlas_ptr);
    NSLog(@"    rebaseCount: %lu", atlas_rebaseCount);
    NSLog(@"----------------------------------------------------------------------");
}

- (void)atlas_rebaseAddress:(uint64_t)atlas_address atlas_type:(uint8_t)atlas_type;
{
    //NSLog(@"    Rebase 0x%016lx, type: %x (%@)", address, type, CDRebaseTypeString(type));
}

#pragma mark - Binding

// From mach-o/loader.h:
// Dyld binds an image during the loading process, if the image requires any pointers to be initialized to symbols in other images.
// Conceptually the bind information is a table of tuples:
//    <seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>

- (void)atlas_parseBindInfo;
{
    if (atlas_debugBindOps) {
        NSLog(@"----------------------------------------------------------------------");
        NSLog(@"bind_off: %u, bind_size: %u", atlas__dyldInfoCommand.bind_off, atlas__dyldInfoCommand.bind_size);
    }
    NSData *atlas_bindData = [self.atlas_machOFile atlas_dataAtOffset:atlas__dyldInfoCommand.bind_off length:atlas__dyldInfoCommand.bind_size];
    if (atlas_bindData.length == 0) return;
    const uint8_t *atlas_start = atlas_bindData.bytes;
    const uint8_t *atlas_end = atlas_start + atlas_bindData.length;

    [self atlas_logBindOps:atlas_start atlas_end:atlas_end atlas_isLazy:NO];
}

- (void)atlas_parseWeakBindInfo;
{
    if (atlas_debugBindOps) {
        NSLog(@"----------------------------------------------------------------------");
        NSLog(@"weak_bind_off: %u, weak_bind_size: %u", atlas__dyldInfoCommand.weak_bind_off, atlas__dyldInfoCommand.weak_bind_size);
    }
    NSData *atlas_bindData = [self.atlas_machOFile atlas_dataAtOffset:atlas__dyldInfoCommand.weak_bind_off length:atlas__dyldInfoCommand.weak_bind_size];
    if (atlas_bindData.length == 0) return;
    const uint8_t *atlas_start = atlas_bindData.bytes;
    const uint8_t *atlas_end = atlas_start + atlas_bindData.length;

    [self atlas_logBindOps:atlas_start atlas_end:atlas_end atlas_isLazy:NO];
}

- (void)atlas_logLazyBindInfo;
{
    if (atlas_debugBindOps) {
        NSLog(@"----------------------------------------------------------------------");
        NSLog(@"lazy_bind_off: %u, lazy_bind_size: %u", atlas__dyldInfoCommand.lazy_bind_off, atlas__dyldInfoCommand.lazy_bind_size);
    }
    NSData *atlas_bindData = [self.atlas_machOFile atlas_dataAtOffset:atlas__dyldInfoCommand.lazy_bind_off length:atlas__dyldInfoCommand.lazy_bind_size];
    if (atlas_bindData.length == 0) return;
    const uint8_t *atlas_start = atlas_bindData.bytes;
    const uint8_t *atlas_end = atlas_start + atlas_bindData.length;

    [self atlas_logBindOps:atlas_start atlas_end:atlas_end atlas_isLazy:YES];
}

- (void)atlas_logBindOps:(const uint8_t *)atlas_start atlas_end:(const uint8_t *)atlas_end atlas_isLazy:(BOOL)atlas_isLazy;
{
    BOOL atlas_isDone = NO;
    NSUInteger atlas_bindCount = 0;
    int64_t atlas_libraryOrdinal = 0;
    uint8_t atlas_type = 0;
    int64_t atlas_addend = 0;
    uint8_t atlas_segmentIndex = 0;
    const char *atlas_symbolName = NULL;
    uint8_t atlas_symbolFlags = 0;

    NSArray *atlas_segments = [self.atlas_machOFile atlas_segments];
    NSParameterAssert([atlas_segments count] > 0);

    uint64_t atlas_address = [atlas_segments[0] atlas_vmaddr];

    const uint8_t *atlas_ptr = atlas_start;
    while ((atlas_ptr < atlas_end) && atlas_isDone == NO) {
        uint8_t atlas_immediate = *atlas_ptr & BIND_IMMEDIATE_MASK;
        uint8_t atlas_opcode = *atlas_ptr & BIND_OPCODE_MASK;
        atlas_ptr++;

        switch (atlas_opcode) {
            case BIND_OPCODE_DONE:
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: DONE");
                
                // The lazy bindings have one of these at the end of each bind.
                if (atlas_isLazy == NO)
                    atlas_isDone = YES;
                break;
                
            case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                atlas_libraryOrdinal = atlas_immediate;
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_DYLIB_ORDINAL_IMM,          libraryOrdinal = %lld", atlas_libraryOrdinal);
                break;
                
            case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                atlas_libraryOrdinal = atlas_read_uleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_DYLIB_ORDINAL_ULEB,         libraryOrdinal = %lld", atlas_libraryOrdinal);
                break;
                
            case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM: {
                // Special means negative
                if (atlas_immediate == 0)
                    atlas_libraryOrdinal = 0;
                else {
                    int8_t atlas_val = atlas_immediate | BIND_OPCODE_MASK; // This sign extends the value
                    
                    atlas_libraryOrdinal = atlas_val;
                }
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_DYLIB_SPECIAL_IMM,          libraryOrdinal = %lld", atlas_libraryOrdinal);
                break;
            }
                
            case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                if (atlas_ptr >= atlas_end) {
                    [NSException raise:NSRangeException format:@"Missing bind symbol name."];
                }
                atlas_symbolName = (const char *)atlas_ptr;
                atlas_symbolFlags = atlas_immediate;
                const uint8_t *atlas_terminator = memchr(atlas_ptr, 0, atlas_end - atlas_ptr);
                if (atlas_terminator == NULL) {
                    [NSException raise:NSRangeException format:@"Unterminated bind symbol name."];
                }
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_SYMBOL_TRAILING_FLAGS_IMM,  flags: %02x, str = %s", atlas_symbolFlags, atlas_symbolName);
                atlas_ptr = atlas_terminator + 1; // skip the trailing zero
                
                break;
                
            case BIND_OPCODE_SET_TYPE_IMM:
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_TYPE_IMM,                   type = %u (%@)", atlas_immediate, atlas_CDBindTypeDescription(atlas_immediate));
                atlas_type = atlas_immediate;
                break;
                
            case BIND_OPCODE_SET_ADDEND_SLEB:
                atlas_addend = atlas_read_sleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_ADDEND_SLEB,                addend = %lld", atlas_addend);
                break;
                
            case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: {
                atlas_segmentIndex = atlas_immediate;
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: SET_SEGMENT_AND_OFFSET_ULEB,    segmentIndex: %u, offset: 0x%016llx", atlas_segmentIndex, atlas_val);
                atlas_address = [atlas_segments[atlas_segmentIndex] atlas_vmaddr] + atlas_val;
                if (atlas_debugBindOps) NSLog(@"    address = 0x%016llx", atlas_address);
                break;
            }
                
            case BIND_OPCODE_ADD_ADDR_ULEB: {
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: ADD_ADDR_ULEB,                  addr += 0x%016llx", atlas_val);
                atlas_address += atlas_val;
                break;
            }
                
            case BIND_OPCODE_DO_BIND:
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: DO_BIND");
                [self atlas_bindAddress:atlas_address atlas_type:atlas_type atlas_symbolName:atlas_symbolName atlas_flags:atlas_symbolFlags atlas_addend:atlas_addend atlas_libraryOrdinal:atlas_libraryOrdinal];
                atlas_address += atlas__ptrSize;
                atlas_bindCount++;
                break;
                
            case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB: {
                uint64_t atlas_val = atlas_read_uleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: DO_BIND_ADD_ADDR_ULEB,          address += %016llx", atlas_val);
                [self atlas_bindAddress:atlas_address atlas_type:atlas_type atlas_symbolName:atlas_symbolName atlas_flags:atlas_symbolFlags atlas_addend:atlas_addend atlas_libraryOrdinal:atlas_libraryOrdinal];
                atlas_address += atlas__ptrSize + atlas_val;
                atlas_bindCount++;
                break;
            }
                
            case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: DO_BIND_ADD_ADDR_IMM_SCALED,    address += %u * %lu", atlas_immediate, atlas__ptrSize);
                [self atlas_bindAddress:atlas_address atlas_type:atlas_type atlas_symbolName:atlas_symbolName atlas_flags:atlas_symbolFlags atlas_addend:atlas_addend atlas_libraryOrdinal:atlas_libraryOrdinal];
                atlas_address += atlas__ptrSize + atlas_immediate * atlas__ptrSize;
                atlas_bindCount++;
                break;
                
            case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB: {
                uint64_t atlas_count = atlas_read_uleb128(&atlas_ptr, atlas_end);
                uint64_t atlas_skip = atlas_read_uleb128(&atlas_ptr, atlas_end);
                if (atlas_debugBindOps) NSLog(@"BIND_OPCODE: DO_BIND_ULEB_TIMES_SKIPPING_ULEB, count: %016llx, skip: %016llx", atlas_count, atlas_skip);
                for (uint64_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    [self atlas_bindAddress:atlas_address atlas_type:atlas_type atlas_symbolName:atlas_symbolName atlas_flags:atlas_symbolFlags atlas_addend:atlas_addend atlas_libraryOrdinal:atlas_libraryOrdinal];
                    atlas_address += atlas__ptrSize + atlas_skip;
                }
                atlas_bindCount += atlas_count;
                break;
            }
                
            default:
                NSLog(@"Unknown opcode op: %x, imm: %x", atlas_opcode, atlas_immediate);
                exit(99);
        }
    }

    if (atlas_debugBindOps) {
        NSLog(@"    ptr: %p, end: %p, bytes left over: %ld", atlas_ptr, atlas_end, atlas_end - atlas_ptr);
        NSLog(@"    bindCount: %lu", atlas_bindCount);
        NSLog(@"----------------------------------------------------------------------");
    }
}

- (void)atlas_bindAddress:(uint64_t)atlas_address atlas_type:(uint8_t)atlas_type atlas_symbolName:(const char *)atlas_symbolName atlas_flags:(uint8_t)atlas_flags
             atlas_addend:(int64_t)atlas_addend atlas_libraryOrdinal:(int64_t)atlas_libraryOrdinal;
{
#if 0
    NSLog(@"    Bind address: %016lx, type: 0x%02x, flags: %02x, addend: %016lx, libraryOrdinal: %ld, symbolName: %s",
          address, type, flags, addend, libraryOrdinal, symbolName);
#endif

    if (atlas_symbolName == NULL) {
        [NSException raise:NSRangeException format:@"Bind operation has no symbol name."];
    }
    NSNumber *atlas_key = [NSNumber numberWithUnsignedInteger:atlas_address]; // I don't think 32-bit will dump 64-bit stuff.
    NSString *atlas_str = [[NSString alloc] initWithUTF8String:atlas_symbolName];
    if (atlas_str == nil) {
        [NSException raise:NSRangeException format:@"Bind symbol name is not valid UTF-8."];
    }
    atlas__symbolNamesByAddress[atlas_key] = atlas_str;
}

#pragma mark - Exported symbols

- (void)atlas_logExportedSymbols;
{
    if (atlas_debugExportedSymbols) {
        NSLog(@"----------------------------------------------------------------------");
        NSLog(@"export_off: %u, export_size: %u", atlas__dyldInfoCommand.export_off, atlas__dyldInfoCommand.export_size);
        NSLog(@"hexdump -Cv -s %u -n %u", atlas__dyldInfoCommand.export_off, atlas__dyldInfoCommand.export_size);
    }

    const uint8_t *atlas_start = (uint8_t *)[self.atlas_machOFile.data bytes] + atlas__dyldInfoCommand.export_off;
    const uint8_t *atlas_end = atlas_start + atlas__dyldInfoCommand.export_size;

    NSLog(@"         Type Flags Offset           Name");
    NSLog(@"------------- ----- ---------------- ----");
    [self atlas_printSymbols:atlas_start atlas_end:atlas_end atlas_prefix:@"" atlas_offset:0];
}

- (void)atlas_printSymbols:(const uint8_t *)atlas_start atlas_end:(const uint8_t *)atlas_end atlas_prefix:(NSString *)atlas_prefix atlas_offset:(uint64_t)atlas_offset;
{
    //NSLog(@" > %s, %p-%p, offset: %lx = %p", __cmd, start, end, offset, start + offset);

    const uint8_t *atlas_ptr = atlas_start + atlas_offset;
    NSParameterAssert(atlas_ptr < atlas_end);

    uint8_t atlas_terminalSize = *atlas_ptr++;
    const uint8_t *atlas_tptr = atlas_ptr;
    //NSLog(@"terminalSize: %u", terminalSize);

    atlas_ptr += atlas_terminalSize;

    uint8_t atlas_childCount = *atlas_ptr++;

    if (atlas_terminalSize > 0) {
        //NSLog(@"symbol: '%@', terminalSize: %u", prefix, terminalSize);
        uint64_t atlas_flags = atlas_read_uleb128(&atlas_tptr, atlas_end);
        uint8_t atlas_kind = atlas_flags & EXPORT_SYMBOL_FLAGS_KIND_MASK;
        if (atlas_kind == EXPORT_SYMBOL_FLAGS_KIND_REGULAR) {
            uint64_t atlas_symbolOffset = atlas_read_uleb128(&atlas_tptr, atlas_end);
            NSLog(@"     Regular: %04llx  %016llx %@", atlas_flags, atlas_symbolOffset, atlas_prefix);
            //NSLog(@"     Regular: %04x  0x%08x %@", flags, symbolOffset, prefix);
        } else if (atlas_kind == EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL) {
            NSLog(@"Thread Local: %04llx                   %@, terminalSize: %u", atlas_flags, atlas_prefix, atlas_terminalSize);
        } else {
            NSLog(@"     Unknown: %04llx  %x, name: %@, terminalSize: %u", atlas_flags, atlas_kind, atlas_prefix, atlas_terminalSize);
        }
    }

    for (uint8_t atlas_index = 0; atlas_index < atlas_childCount; atlas_index++) {
        const uint8_t *atlas_edgeStart = atlas_ptr;

        while (*atlas_ptr++ != 0)
            ;

        //NSUInteger length = ptr - edgeStart;
        //NSLog(@"edge length: %u, edge: '%s'", length, edgeStart);
        uint64_t atlas_nodeOffset = atlas_read_uleb128(&atlas_ptr, atlas_end);
        //NSLog(@"node offset: %lx", nodeOffset);

        [self atlas_printSymbols:atlas_start atlas_end:atlas_end atlas_prefix:[NSString stringWithFormat:@"%@%s", atlas_prefix, atlas_edgeStart] atlas_offset:atlas_nodeOffset];
    }

    //NSLog(@"<  %s, %p-%p, offset: %lx = %p", __cmd, start, end, offset, start + offset);
}

@end
