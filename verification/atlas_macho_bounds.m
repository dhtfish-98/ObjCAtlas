// Copyright (c) 2026 dhtfish98
#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
#import "atlas_CDMachOFile.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDSection.h"

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

static ObjCAtlasMachOFile *fileWithSegment(struct segment_command_64 segment, struct section_64 *section, const void *tail, size_t tailLength)
{
    struct mach_header_64 header = {0};
    header.magic = MH_MAGIC_64;
    header.cputype = CPU_TYPE_ARM64;
    header.cpusubtype = CPU_SUBTYPE_ARM_ALL;
    header.filetype = MH_EXECUTE;
    header.ncmds = 1;
    header.sizeofcmds = sizeof(segment) + (section == NULL ? 0 : sizeof(*section));
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = header.sizeofcmds;
    segment.nsects = section == NULL ? 0 : 1;
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:&segment length:sizeof(segment)];
    if (section != NULL) {
        [data appendBytes:section length:sizeof(*section)];
    }
    if (tailLength != 0) {
        [data appendBytes:tail length:tailLength];
    }
    ObjCAtlasMachOFile *file = [[ObjCAtlasMachOFile alloc] initAtlasWithData:data atlas_filename:@"bounded-fixture" atlas_searchPathState:nil];
    require(file != nil, @"parse synthetic Mach-O");
    return file;
}

int main(void)
{
    @autoreleasepool {
        struct segment_command_64 segment = {0};
        segment.vmaddr = 0x1000;
        segment.vmsize = 0x1000;
        segment.fileoff = sizeof(struct mach_header_64) + sizeof(segment) + sizeof(struct section_64);
        segment.filesize = 4;
        struct section_64 section = {0};
        memcpy(section.sectname, "__cstring", 9);
        memcpy(section.segname, "__TEXT", 6);
        section.addr = segment.vmaddr;
        section.size = 4;
        section.offset = (uint32_t)segment.fileoff;
        const char unterminated[] = {'A', 'B', 'C', 'D'};
        ObjCAtlasMachOFile *file = fileWithSegment(segment, &section, unterminated, sizeof(unterminated));
        requireRangeException(^{ (void)[file atlas_stringAtAddress:0x1000]; }, @"unterminated in-file string");
        requireRangeException(^{ (void)[file atlas_dataAtOffset:file.data.length - 1 length:2]; }, @"range crossing EOF");
        requireRangeException(^{ (void)[file atlas_dataAtOffset:NSUIntegerMax length:2]; }, @"overflowing range");
        requireRangeException(^{ (void)[file atlas_bytesAtOffset:file.data.length + 1]; }, @"offset beyond EOF");
        require([[file atlas_dataAtOffset:segment.fileoff length:4] isEqualToData:[NSData dataWithBytes:unterminated length:4]], @"valid range");

        section.size = 8;
        file = fileWithSegment(segment, &section, unterminated, sizeof(unterminated));
        ObjCAtlasLCSegment *parsedSegment = file.atlas_segments.firstObject;
        ObjCAtlasSection *parsedSection = parsedSegment.atlas_sections.firstObject;
        requireRangeException(^{ (void)parsedSection.data; }, @"section extending beyond EOF");

        segment.fileoff = 0;
        segment.filesize = 4 * PAGE_SIZE;
        segment.flags = SG_PROTECTED_VERSION_1;
        file = fileWithSegment(segment, NULL, NULL, 0);
        parsedSegment = file.atlas_segments.firstObject;
        requireRangeException(^{ (void)parsedSegment.atlas_encryptionType; }, @"protected header beyond EOF");
        requireRangeException(^{ (void)[parsedSegment atlas_decryptedData]; }, @"protected copy beyond EOF");
        segment.filesize = 1;
        file = fileWithSegment(segment, NULL, NULL, 0);
        parsedSegment = file.atlas_segments.firstObject;
        requireRangeException(^{ (void)[parsedSegment atlas_decryptedData]; }, @"misaligned protected segment");
        puts("PASS: synthetic Mach-O file, section, string and protected segment boundaries");
    }
    return 0;
}
