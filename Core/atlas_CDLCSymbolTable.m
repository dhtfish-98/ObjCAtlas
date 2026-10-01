// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCSymbolTable.h"

#include <mach-o/nlist.h>
#import "atlas_CDMachOFile.h"
#import "atlas_CDSymbol.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDLCDylib.h"

@implementation ObjCAtlasLCSymbolTable
{
    struct symtab_command atlas__symtabCommand;
    
    NSArray *atlas__symbols;
    NSUInteger atlas__baseAddress;
    
    NSDictionary *atlas__classSymbols;
    NSDictionary *atlas__externalClassSymbols;
    
    struct {
        unsigned int atlas_didFindBaseAddress:1;
        unsigned int atlas_didWarnAboutUnfoundBaseAddress:1;
        unsigned int atlas__unused:30;
    } atlas__flags;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_baseAddress = atlas__baseAddress;
@synthesize atlas_symbols = atlas__symbols;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__symtabCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__symtabCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__symtabCommand.symoff  = [atlas_cursor atlas_readInt32];
        atlas__symtabCommand.nsyms   = [atlas_cursor atlas_readInt32];
        atlas__symtabCommand.stroff  = [atlas_cursor atlas_readInt32];
        atlas__symtabCommand.strsize = [atlas_cursor atlas_readInt32];
        
        // symoff is at the start of the first section (__pointers) of the __IMPORT segment
        // stroff falls within the __LINKEDIT segment
#if 0
        NSLog(@"symtab: %08x %08x  %08x %08x %08x %08x",
              symtabCommand.cmd, symtabCommand.cmdsize,
              symtabCommand.symoff, symtabCommand.nsyms, symtabCommand.stroff, symtabCommand.strsize);
        NSLog(@"data offset for stroff: %lu", [cursor.machOFile dataOffsetForAddress:symtabCommand.stroff]);
#endif
        
        atlas__symbols = nil;
        atlas__baseAddress = 0;
        
        atlas__classSymbols = nil;
        
        atlas__flags.atlas_didFindBaseAddress = NO;
        atlas__flags.atlas_didWarnAboutUnfoundBaseAddress = NO;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)atlas_extraDescription;
{
    return [NSString stringWithFormat:@"symoff: 0x%08x (%u), nsyms: 0x%08x (%u), stroff: 0x%08x (%u), strsize: 0x%08x (%u)",
            atlas__symtabCommand.symoff, atlas__symtabCommand.symoff, atlas__symtabCommand.nsyms, atlas__symtabCommand.nsyms,
            atlas__symtabCommand.stroff, atlas__symtabCommand.stroff, atlas__symtabCommand.strsize, atlas__symtabCommand.strsize];
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__symtabCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__symtabCommand.cmdsize;
}

#define atlas_CD_VM_PROT_RW (VM_PROT_READ|VM_PROT_WRITE)

- (void)atlas_loadSymbols;
{
    for (ObjCAtlasLoadCommand *atlas_loadCommand in [self.atlas_machOFile atlas_loadCommands]) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]]) {
            ObjCAtlasLCSegment *atlas_segment = (ObjCAtlasLCSegment *)atlas_loadCommand;

            if (([atlas_segment atlas_initprot] & atlas_CD_VM_PROT_RW) == atlas_CD_VM_PROT_RW) {
                //NSLog(@"segment... initprot = %08x, addr= %016lx *** r/w", [segment initprot], [segment vmaddr]);
                atlas__baseAddress = [atlas_segment atlas_vmaddr];
                atlas__flags.atlas_didFindBaseAddress = YES;
                break;
            }
        }
    }
    
    NSMutableArray *atlas_symbols = [[NSMutableArray alloc] init];
    NSMutableDictionary *atlas_classSymbols = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *atlas_externalClassSymbols = [[NSMutableDictionary alloc] init];

    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_offset:atlas__symtabCommand.symoff];
    //NSLog(@"offset= %lu", [cursor offset]);
    //NSLog(@"stroff=  %lu", symtabCommand.stroff);
    //NSLog(@"strsize= %lu", symtabCommand.strsize);

    const char *atlas_strtab = (char *)[self.atlas_machOFile.data bytes] + atlas__symtabCommand.stroff;
    
    void (^atlas_addSymbol)(NSString *, ObjCAtlasSymbol *) = ^(NSString *atlas_name, ObjCAtlasSymbol *atlas_symbol) {
        [atlas_symbols addObject:atlas_symbol];
        
        NSString *atlas_className = [ObjCAtlasSymbol atlas_classNameFromSymbolName:atlas_symbol.name];
        if (atlas_className != nil) {
            if (atlas_symbol.value != 0)
                atlas_classSymbols[atlas_className] = atlas_symbol;
            else
                atlas_externalClassSymbols[atlas_className] = atlas_symbol;
        }
    };

    if (![self.atlas_machOFile atlas_uses64BitABI]) {
        //NSLog(@"32 bit...");
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  --------");
        for (uint32_t atlas_index = 0; atlas_index < atlas__symtabCommand.nsyms; atlas_index++) {
            struct nlist atlas_nlist;

            atlas_nlist.n_un.n_strx = [atlas_cursor atlas_readInt32];
            atlas_nlist.n_type      = [atlas_cursor atlas_readByte];
            atlas_nlist.n_sect      = [atlas_cursor atlas_readByte];
            atlas_nlist.n_desc      = [atlas_cursor atlas_readInt16];
            atlas_nlist.n_value     = [atlas_cursor atlas_readInt32];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %08x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif

            const char *atlas_ptr = atlas_strtab + atlas_nlist.n_un.n_strx;
            NSString *atlas_str = [[NSString alloc] initWithBytes:atlas_ptr length:strlen(atlas_ptr) encoding:NSASCIIStringEncoding];

            ObjCAtlasSymbol *atlas_symbol = [[ObjCAtlasSymbol alloc] initAtlasWithName:atlas_str atlas_machOFile:self.atlas_machOFile atlas_nlist32:atlas_nlist];
            atlas_addSymbol(atlas_str, atlas_symbol);
        }

        //NSLog(@"Loaded %lu 32-bit symbols", [symbols count]);
    } else {
        //NSLog(@"       str table index  type  sect  desc  value");
        //NSLog(@"       ---------------  ----  ----  ----  ----------------");
        for (uint32_t atlas_index = 0; atlas_index < atlas__symtabCommand.nsyms; atlas_index++) {
            struct nlist_64 atlas_nlist;

            atlas_nlist.n_un.n_strx = [atlas_cursor atlas_readInt32];
            atlas_nlist.n_type      = [atlas_cursor atlas_readByte];
            atlas_nlist.n_sect      = [atlas_cursor atlas_readByte];
            atlas_nlist.n_desc      = [atlas_cursor atlas_readInt16];
            atlas_nlist.n_value     = [atlas_cursor atlas_readInt64];
#if 0
            NSLog(@"%5u: %08x           %02x    %02x  %04x  %016x - %s",
                  index, nlist.n_un.n_strx, nlist.n_type, nlist.n_sect, nlist.n_desc, nlist.n_value, strtab + nlist.n_un.n_strx);
#endif
            const char *atlas_ptr = atlas_strtab + atlas_nlist.n_un.n_strx;
            NSString *atlas_str = [[NSString alloc] initWithBytes:atlas_ptr length:strlen(atlas_ptr) encoding:NSASCIIStringEncoding];

            ObjCAtlasSymbol *atlas_symbol = [[ObjCAtlasSymbol alloc] initAtlasWithName:atlas_str atlas_machOFile:self.atlas_machOFile atlas_nlist64:atlas_nlist];
            atlas_addSymbol(atlas_str, atlas_symbol);
        }

        //NSLog(@"Loaded %lu 64-bit symbols", [symbols count]);
    }
    
    atlas__symbols = [atlas_symbols copy];
    atlas__classSymbols = [atlas_classSymbols copy];
    atlas__externalClassSymbols = [atlas_externalClassSymbols copy];

    //NSLog(@"symbols: %@", _symbols);
}

- (uint32_t)atlas_symoff;
{
    return atlas__symtabCommand.symoff;
}

- (uint32_t)atlas_nsyms;
{
    return atlas__symtabCommand.nsyms;
}

- (uint32_t)atlas_stroff;
{
    return atlas__symtabCommand.stroff;
}

- (uint32_t)atlas_strsize;
{
    return atlas__symtabCommand.strsize;
}

- (NSUInteger)atlas_baseAddress;
{
    if (atlas__flags.atlas_didFindBaseAddress == NO && atlas__flags.atlas_didWarnAboutUnfoundBaseAddress == NO) {
        fprintf(stderr, "Warning: Couldn't find first read/write segment for base address of relocation entries.\n");
        atlas__flags.atlas_didWarnAboutUnfoundBaseAddress = YES;
    }

    return atlas__baseAddress;
}

- (ObjCAtlasSymbol *)atlas_symbolForClassName:(NSString *)atlas_className;
{
    return atlas__classSymbols[atlas_className];
}

- (ObjCAtlasSymbol *)atlas_symbolForExternalClassName:(NSString *)atlas_className
{
    return atlas__externalClassSymbols[atlas_className];
}

@end
