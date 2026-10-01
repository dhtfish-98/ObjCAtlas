// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCDynamicSymbolTable.h"

#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDRelocationInfo.h"

@implementation ObjCAtlasLCDynamicSymbolTable
{
    struct dysymtab_command atlas__dysymtab;
    
    NSArray *atlas__externalRelocationEntries;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__dysymtab.cmd     = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__dysymtab.ilocalsym      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nlocalsym      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.iextdefsym     = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nextdefsym     = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.iundefsym      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nundefsym      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.tocoff         = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.ntoc           = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.modtaboff      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nmodtab        = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.extrefsymoff   = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nextrefsyms    = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.indirectsymoff = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nindirectsyms  = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.extreloff      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nextrel        = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.locreloff      = [atlas_cursor atlas_readInt32];
        atlas__dysymtab.nlocrel        = [atlas_cursor atlas_readInt32];
#if 0
        NSLog(@"ilocalsym:      0x%08x  %d", dysymtab.ilocalsym, dysymtab.ilocalsym);
        NSLog(@"nlocalsym:      0x%08x  %d", dysymtab.nlocalsym, dysymtab.nlocalsym);
        NSLog(@"iextdefsym:     0x%08x  %d", dysymtab.iextdefsym, dysymtab.iextdefsym);
        NSLog(@"nextdefsym:     0x%08x  %d", dysymtab.nextdefsym, dysymtab.nextdefsym);
        NSLog(@"iundefsym:      0x%08x  %d", dysymtab.iundefsym, dysymtab.iundefsym);
        NSLog(@"nundefsym:      0x%08x  %d", dysymtab.nundefsym, dysymtab.nundefsym);
        
        NSLog(@"tocoff:         0x%08x  %d", dysymtab.tocoff, dysymtab.tocoff);
        NSLog(@"ntoc:           0x%08x  %d", dysymtab.ntoc, dysymtab.ntoc);
        NSLog(@"modtaboff:      0x%08x  %d", dysymtab.modtaboff, dysymtab.modtaboff);
        NSLog(@"nmodtab:        0x%08x  %d", dysymtab.nmodtab, dysymtab.nmodtab);
        
        NSLog(@"extrefsymoff:   0x%08x  %d", dysymtab.extrefsymoff, dysymtab.extrefsymoff);
        NSLog(@"nextrefsyms:    0x%08x  %d", dysymtab.nextrefsyms, dysymtab.nextrefsyms);
        NSLog(@"indirectsymoff: 0x%08x  %d", dysymtab.indirectsymoff, dysymtab.indirectsymoff);
        NSLog(@"nindirectsyms:  0x%08x  %d", dysymtab.nindirectsyms, dysymtab.nindirectsyms);
        
        NSLog(@"extreloff:      0x%08x  %d", dysymtab.extreloff, dysymtab.extreloff);
        NSLog(@"nextrel:        0x%08x  %d", dysymtab.nextrel, dysymtab.nextrel);
        NSLog(@"locreloff:      0x%08x  %d", dysymtab.locreloff, dysymtab.locreloff);
        NSLog(@"nlocrel:        0x%08x  %d", dysymtab.nlocrel, dysymtab.nlocrel);
#endif
        
        atlas__externalRelocationEntries = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__dysymtab.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__dysymtab.cmdsize;
}

- (void)atlas_loadSymbols;
{
    NSMutableArray *atlas_externalRelocationEntries = [[NSMutableArray alloc] init];
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_offset:atlas__dysymtab.extreloff];

    //NSLog(@"indirectsymoff: %lu", dysymtab.indirectsymoff);
    //NSLog(@"nindirectsyms:  %lu", dysymtab.nindirectsyms);
#if 0
    [cursor setOffset:[self.machOFile offset] + dysymtab.indirectsymoff];
    for (uint32_t index = 0; index < dysymtab.nindirectsyms; index++) {
        // From loader.h: An indirect symbol table entry is simply a 32bit index into the symbol table to the symbol that the pointer or stub is referring to.
        uint32_t val = [cursor readInt32];
        NSLog(@"%3u: %08x (%u)", index, val, val);
    }
#endif

    //NSLog(@"extreloff: %lu", dysymtab.extreloff);
    //NSLog(@"nextrel:   %lu", dysymtab.nextrel);

    //NSLog(@"     address   val       symbolnum  pcrel  len  ext  type");
    //NSLog(@"---  --------  --------  ---------  -----  ---  ---  ----");
    for (uint32_t atlas_index = 0; atlas_index < atlas__dysymtab.nextrel; atlas_index++) {
        struct relocation_info atlas_rinfo;

        atlas_rinfo.r_address = [atlas_cursor atlas_readInt32];
        uint32_t atlas_val    = [atlas_cursor atlas_readInt32];

        atlas_rinfo.r_symbolnum = atlas_val & 0x00ffffff;
        atlas_rinfo.r_pcrel     = (atlas_val & 0x01000000) >> 24;
        atlas_rinfo.r_length    = (atlas_val & 0x06000000) >> 25;
        atlas_rinfo.r_extern    = (atlas_val & 0x08000000) >> 27;
        atlas_rinfo.r_type      = (atlas_val & 0xf0000000) >> 28;
#if 0
        NSLog(@"%3d: %08x  %08x   %08x      %01x    %01x    %01x     %01x", index, rinfo.r_address, val,
              rinfo.r_symbolnum, rinfo.r_pcrel, rinfo.r_length, rinfo.r_extern, rinfo.r_type);
#endif

        ObjCAtlasRelocationInfo *atlas_ri = [[ObjCAtlasRelocationInfo alloc] initAtlasWithInfo:atlas_rinfo];
        [atlas_externalRelocationEntries addObject:atlas_ri];
    }

    //NSLog(@"externalRelocationEntries: %@", externalRelocationEntries);

    // r_address is purported to be the offset from the vmaddr of the first segment, but...
    // It seems to be from the first segment with r/w initprot.

    // it appears to be the offset from the vmaddr of the 3rd segment in t1s.
    // Actually, it really seems to be the offset from the vmaddr of the section indicated in the n_desc part of the nlist.
    // 0000000000000000 01 00 0500 0000000000000038 _OBJC_CLASS_$_NSObject
    // GET_LIBRARY_ORDINAL() from nlist.h for library.
    
    atlas__externalRelocationEntries = [atlas_externalRelocationEntries copy];
}

// Just search for externals.
- (ObjCAtlasRelocationInfo *)atlas_relocationEntryWithOffset:(NSUInteger)atlas_offset;
{
    for (ObjCAtlasRelocationInfo *atlas_info in atlas__externalRelocationEntries) {
        if (atlas_info.atlas_isExtern && atlas_info.atlas_offset == atlas_offset) {
            return atlas_info;
        }
    }

    return nil;
}

@end
