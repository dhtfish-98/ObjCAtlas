// Copyright (c) 2026 dhtfish98
#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <mach-o/fat.h>
#import "atlas_CDMachOFile.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDSection.h"
#import "atlas_CDLCSymbolTable.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDFatArch.h"

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

static ObjCAtlasMachOFile *fileWithSymbolTable(uint32_t symbolOffset, uint32_t symbolCount,
                                               uint32_t stringOffset, uint32_t stringSize,
                                               uint32_t stringIndex, const void *strings, size_t stringBytes)
{
    struct mach_header_64 header = {0};
    header.magic = MH_MAGIC_64;
    header.cputype = CPU_TYPE_ARM64;
    header.cpusubtype = CPU_SUBTYPE_ARM_ALL;
    header.filetype = MH_EXECUTE;
    header.ncmds = 1;
    header.sizeofcmds = sizeof(struct symtab_command);
    struct symtab_command command = {0};
    command.cmd = LC_SYMTAB;
    command.cmdsize = sizeof(command);
    command.symoff = symbolOffset;
    command.nsyms = symbolCount;
    command.stroff = stringOffset;
    command.strsize = stringSize;
    struct nlist_64 symbol = {0};
    symbol.n_un.n_strx = stringIndex;
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:&command length:sizeof(command)];
    [data appendBytes:&symbol length:sizeof(symbol)];
    [data appendBytes:strings length:stringBytes];
    ObjCAtlasMachOFile *file = [[ObjCAtlasMachOFile alloc] initAtlasWithData:data atlas_filename:@"symtab-fixture" atlas_searchPathState:nil];
    require(file != nil && file.atlas_symbolTable != nil, @"parse synthetic symbol table");
    return file;
}

static ObjCAtlasMachOFile *fileWithBindInfo(uint32_t bindOffset, uint32_t bindSize, const void *bindBytes, size_t bindBytesLength)
{
    struct mach_header_64 header = {0};
    header.magic = MH_MAGIC_64;
    header.cputype = CPU_TYPE_ARM64;
    header.cpusubtype = CPU_SUBTYPE_ARM_ALL;
    header.filetype = MH_EXECUTE;
    header.ncmds = 2;
    header.sizeofcmds = sizeof(struct segment_command_64) + sizeof(struct dyld_info_command);
    struct segment_command_64 segment = {0};
    segment.cmd = LC_SEGMENT_64;
    segment.cmdsize = sizeof(segment);
    segment.vmaddr = 0x1000;
    segment.vmsize = 0x1000;
    struct dyld_info_command command = {0};
    command.cmd = LC_DYLD_INFO_ONLY;
    command.cmdsize = sizeof(command);
    command.bind_off = bindOffset;
    command.bind_size = bindSize;
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:&segment length:sizeof(segment)];
    [data appendBytes:&command length:sizeof(command)];
    [data appendBytes:bindBytes length:bindBytesLength];
    return [[ObjCAtlasMachOFile alloc] initAtlasWithData:data atlas_filename:@"bind-fixture" atlas_searchPathState:nil];
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

        uint32_t symbolOffset = sizeof(struct mach_header_64) + sizeof(struct symtab_command);
        uint32_t stringOffset = symbolOffset + sizeof(struct nlist_64);
        const char validSymbol[] = "_fixture";
        file = fileWithSymbolTable(symbolOffset, 1, stringOffset, sizeof(validSymbol), 0, validSymbol, sizeof(validSymbol));
        [file.atlas_symbolTable atlas_loadSymbols];
        require(file.atlas_symbolTable.atlas_symbols.count == 1, @"bounded symbol table accepts valid name");
        file = fileWithSymbolTable(symbolOffset + 4096, 1, stringOffset, sizeof(validSymbol), 0, validSymbol, sizeof(validSymbol));
        requireRangeException(^{ [file.atlas_symbolTable atlas_loadSymbols]; }, @"symbol entries beyond EOF");
        file = fileWithSymbolTable(symbolOffset, 1, stringOffset, sizeof(validSymbol) + 1, 0, validSymbol, sizeof(validSymbol));
        requireRangeException(^{ [file.atlas_symbolTable atlas_loadSymbols]; }, @"string table beyond EOF");
        file = fileWithSymbolTable(symbolOffset, 1, stringOffset, sizeof(validSymbol), sizeof(validSymbol), validSymbol, sizeof(validSymbol));
        requireRangeException(^{ [file.atlas_symbolTable atlas_loadSymbols]; }, @"symbol name index beyond table");
        const char unterminatedSymbol[] = {'A', 'B', 'C'};
        file = fileWithSymbolTable(symbolOffset, 1, stringOffset, sizeof(unterminatedSymbol), 0, unterminatedSymbol, sizeof(unterminatedSymbol));
        requireRangeException(^{ [file.atlas_symbolTable atlas_loadSymbols]; }, @"unterminated symbol name");

        uint32_t fatHeader[] = {CFSwapInt32HostToBig(FAT_MAGIC), 0};
        ObjCAtlasFatFile *fat = [[ObjCAtlasFatFile alloc] initAtlasWithData:[NSData dataWithBytes:fatHeader length:sizeof(fatHeader)] atlas_filename:@"fat-fixture" atlas_searchPathState:nil];
        require(fat != nil, @"parse synthetic fat file");
        ObjCAtlasFatArch *arch = [ObjCAtlasFatArch new];
        arch.atlas_fatFile = fat;
        arch.atlas_offset = UINT32_MAX;
        arch.atlas_size = 16;
        requireRangeException(^{ (void)arch.atlas_machOFile; }, @"fat slice offset beyond EOF");
        arch.atlas_offset = 4;
        arch.atlas_size = 16;
        requireRangeException(^{ (void)arch.atlas_machOFile; }, @"fat slice length crossing EOF");

        uint32_t bindOffset = sizeof(struct mach_header_64) + sizeof(struct segment_command_64) + sizeof(struct dyld_info_command);
        const uint8_t validBind[] = {BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM, 'A', 0, BIND_OPCODE_DONE};
        const uint8_t *validBindPtr = validBind;
        require(fileWithBindInfo(bindOffset, sizeof(validBind), validBind, sizeof(validBind)) != nil, @"bounded bind name accepted");
        requireRangeException(^{ (void)fileWithBindInfo(bindOffset, sizeof(validBind) + 1, validBindPtr, sizeof(validBind)); }, @"bind range crossing EOF");
        const uint8_t unterminatedBind[] = {BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM, 'A'};
        const uint8_t *unterminatedBindPtr = unterminatedBind;
        requireRangeException(^{ (void)fileWithBindInfo(bindOffset, sizeof(unterminatedBind), unterminatedBindPtr, sizeof(unterminatedBind)); }, @"unterminated bind name");
        const uint8_t missingBindName[] = {BIND_OPCODE_DO_BIND, BIND_OPCODE_DONE};
        const uint8_t *missingBindNamePtr = missingBindName;
        requireRangeException(^{ (void)fileWithBindInfo(bindOffset, sizeof(missingBindName), missingBindNamePtr, sizeof(missingBindName)); }, @"bind operation without name");
        puts("PASS: synthetic Mach-O file, section, string and protected segment boundaries");
    }
    return 0;
}
