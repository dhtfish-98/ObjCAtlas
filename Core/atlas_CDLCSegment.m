// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCSegment.h"

#import "atlas_CDMachOFile.h"
#import "atlas_CDSection.h"

#include <CommonCrypto/CommonCrypto.h>
#include "blowfish.h"

// Decrypt PAGE_SIZE (4096) bytes
static void atlas_BF_Decrypt_Block(BLOWFISH_CTX *atlas_ctx, const uint8_t *atlas_ptr, uint8_t *atlas_dest)
{
    uint32_t atlas_left, atlas_right;
    uint32_t atlas_src_offset = 0, atlas_dest_offset = 0;
    uint32_t atlas_previous_left = 0, atlas_previous_right = 0;
    for (NSUInteger atlas_index = 0; atlas_index < PAGE_SIZE / 8; atlas_index++) {
        atlas_left  = OSReadBigInt32(atlas_ptr, atlas_src_offset); atlas_src_offset += sizeof(uint32_t);
        atlas_right = OSReadBigInt32(atlas_ptr, atlas_src_offset); atlas_src_offset += sizeof(uint32_t);

        uint32_t atlas_left2 = atlas_left;
        uint32_t atlas_right2 = atlas_right;
        Blowfish_Decrypt(atlas_ctx, &atlas_left2, &atlas_right2);
        atlas_left2 ^= atlas_previous_left;
        atlas_right2 ^= atlas_previous_right;
        atlas_previous_left = atlas_left;
        atlas_previous_right = atlas_right;

        OSWriteBigInt32(atlas_dest, atlas_dest_offset, atlas_left2);  atlas_dest_offset += sizeof(uint32_t);
        OSWriteBigInt32(atlas_dest, atlas_dest_offset, atlas_right2); atlas_dest_offset += sizeof(uint32_t);
    }
}

NSString *atlas_CDSegmentEncryptionTypeName(atlas_CDSegmentEncryptionType atlas_type)
{
    switch (atlas_type) {
        case atlas_CDSegmentEncryptionType_None:     return @"None";
        case atlas_CDSegmentEncryptionType_AES:      return @"Protected Segment Type 1 (prior to 10.6)";
        case atlas_CDSegmentEncryptionType_Blowfish: return @"Protected Segment Type 2 (10.6)";
        case atlas_CDSegmentEncryptionType_Unknown:  return @"Unknown";
    }
}

@implementation ObjCAtlasLCSegment
{
    struct segment_command_64 atlas__segmentCommand; // 64-bit, also holding 32-bit
    
    NSString *atlas__name;
    NSArray *atlas__sections;
    
    NSMutableData *atlas__decryptedData;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_sections = atlas__sections;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__segmentCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__segmentCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__name = [atlas_cursor atlas_readStringOfLength:16 atlas_encoding:NSASCIIStringEncoding];
        size_t atlas_nameLength = [atlas__name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        memcpy(atlas__segmentCommand.segname, [atlas__name UTF8String], MIN(sizeof(atlas__segmentCommand.segname), atlas_nameLength));
        atlas__segmentCommand.vmaddr   = [atlas_cursor atlas_readPtr];
        atlas__segmentCommand.vmsize   = [atlas_cursor atlas_readPtr];
        atlas__segmentCommand.fileoff  = [atlas_cursor atlas_readPtr];
        atlas__segmentCommand.filesize = [atlas_cursor atlas_readPtr];
        atlas__segmentCommand.maxprot  = [atlas_cursor atlas_readInt32];
        atlas__segmentCommand.initprot = [atlas_cursor atlas_readInt32];
        atlas__segmentCommand.nsects   = [atlas_cursor atlas_readInt32];
        atlas__segmentCommand.flags    = [atlas_cursor atlas_readInt32];
        
        NSMutableArray *atlas_sections = [[NSMutableArray alloc] init];
        for (NSUInteger atlas_index = 0; atlas_index < atlas__segmentCommand.nsects; atlas_index++) {
            ObjCAtlasSection *atlas_section = [[ObjCAtlasSection alloc] initAtlasWithDataCursor:atlas_cursor atlas_segment:self];
            [atlas_sections addObject:atlas_section];
        }
        atlas__sections = [atlas_sections copy];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)atlas_extraDescription;
{
    int atlas_padding = (int)self.atlas_machOFile.atlas_ptrSize * 2;
    return [NSString stringWithFormat:@"vmaddr: 0x%0*llx - 0x%0*llx [0x%0*llx], offset: %lld, flags: 0x%x (%@), nsects: %d, sections: %@",
            atlas_padding, atlas__segmentCommand.vmaddr, atlas_padding, atlas__segmentCommand.vmaddr + atlas__segmentCommand.vmsize - 1, atlas_padding, atlas__segmentCommand.vmsize,
            atlas__segmentCommand.fileoff, self.atlas_flags, [self atlas_flagDescription], atlas__segmentCommand.nsects, self.atlas_sections.count > 0 ? self.atlas_sections : @"N/A"];
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__segmentCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__segmentCommand.cmdsize;
}

- (NSUInteger)atlas_vmaddr;
{
    return atlas__segmentCommand.vmaddr;
}

- (NSUInteger)atlas_fileoff;
{
    return atlas__segmentCommand.fileoff;
}

- (NSUInteger)atlas_filesize;
{
    return atlas__segmentCommand.filesize;
}

- (vm_prot_t)atlas_initprot;
{
    return atlas__segmentCommand.initprot;
}

- (uint32_t)atlas_flags;
{
    return atlas__segmentCommand.flags;
}

- (BOOL)atlas_isProtected;
{
    return (self.atlas_flags & SG_PROTECTED_VERSION_1) == SG_PROTECTED_VERSION_1;
}

- (atlas_CDSegmentEncryptionType)atlas_encryptionType;
{
    //NSLog(@"%s, isProtected? %u, filesize: %lu, fileoff: %lu", __cmd, [self isProtected], [self filesize], [self fileoff]);
    if (self.atlas_isProtected) {
        if (self.atlas_filesize <= 3 * PAGE_SIZE) {
            // First three pages aren't encrypted, so we can't tell.  Let's pretent it's something we can decrypt.
            return atlas_CDSegmentEncryptionType_AES;
        } else {
            const void *atlas_src = (uint8_t *)[self.atlas_machOFile.data bytes] + self.atlas_fileoff + 3 * PAGE_SIZE;

            uint32_t atlas_magic = OSReadLittleInt32(atlas_src, 0);
            //NSLog(@"%s, magic= 0x%08x", __cmd, magic);
            switch (atlas_magic) {
                case atlas_CDSegmentProtectedMagic_None:     return atlas_CDSegmentEncryptionType_None;
                case atlas_CDSegmentProtectedMagic_AES:      return atlas_CDSegmentEncryptionType_AES;
                case atlas_CDSegmentProtectedMagic_Blowfish: return atlas_CDSegmentEncryptionType_Blowfish;
            }

            return atlas_CDSegmentEncryptionType_Unknown;
        }
    }

    return atlas_CDSegmentEncryptionType_None;
}

- (BOOL)atlas_canDecrypt;
{
    atlas_CDSegmentEncryptionType atlas_encryptionType = self.atlas_encryptionType;

    return (atlas_encryptionType == atlas_CDSegmentEncryptionType_None)
        || (atlas_encryptionType == atlas_CDSegmentEncryptionType_AES)
        || (atlas_encryptionType == atlas_CDSegmentEncryptionType_Blowfish);
}

- (NSString *)atlas_flagDescription;
{
    NSMutableArray *atlas_setFlags = [NSMutableArray array];
    uint32_t atlas_flags = self.atlas_flags;
    if (atlas_flags & SG_HIGHVM)              [atlas_setFlags addObject:@"HIGHVM"];
    if (atlas_flags & SG_FVMLIB)              [atlas_setFlags addObject:@"FVMLIB"];
    if (atlas_flags & SG_NORELOC)             [atlas_setFlags addObject:@"NORELOC"];
    if (atlas_flags & SG_PROTECTED_VERSION_1) [atlas_setFlags addObject:@"PROTECTED_VERSION_1"];

    if ([atlas_setFlags count] == 0)
        return @"none";

    return [atlas_setFlags componentsJoinedByString:@" "];
}

- (BOOL)atlas_containsAddress:(NSUInteger)atlas_address;
{
    return (atlas_address >= atlas__segmentCommand.vmaddr) && (atlas_address < atlas__segmentCommand.vmaddr + atlas__segmentCommand.vmsize);
}

- (ObjCAtlasSection *)atlas_sectionContainingAddress:(NSUInteger)atlas_address;
{
    for (ObjCAtlasSection *atlas_section in self.atlas_sections) {
        if ([atlas_section atlas_containsAddress:atlas_address])
            return atlas_section;
    }

    return nil;
}

- (ObjCAtlasSection *)atlas_sectionWithName:(NSString *)atlas_name;
{
    for (ObjCAtlasSection *atlas_section in self.atlas_sections) {
        if ([[atlas_section atlas_sectionName] isEqual:atlas_name])
            return atlas_section;
    }

    return nil;
}

- (NSUInteger)atlas_fileOffsetForAddress:(NSUInteger)atlas_address;
{
    return [[self atlas_sectionContainingAddress:atlas_address] atlas_fileOffsetForAddress:atlas_address];
}

- (NSUInteger)atlas_segmentOffsetForAddress:(NSUInteger)atlas_address;
{
    return [self atlas_fileOffsetForAddress:atlas_address] - self.atlas_fileoff;
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [super atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];
#if 0
    int padding = (int)self.machOFile.ptrSize * 2;
    [resultString appendFormat:@"  segname %@\n",       self.name];
    [resultString appendFormat:@"   vmaddr 0x%0*llx\n", padding, _segmentCommand.vmaddr];
    [resultString appendFormat:@"   vmsize 0x%0*llx\n", padding, _segmentCommand.vmsize];
    [resultString appendFormat:@"  fileoff %lld\n",     _segmentCommand.fileoff];
    [resultString appendFormat:@" filesize %lld\n",     _segmentCommand.filesize];
    [resultString appendFormat:@"  maxprot 0x%08x\n",   _segmentCommand.maxprot];
    [resultString appendFormat:@" initprot 0x%08x\n",   _segmentCommand.initprot];
    [resultString appendFormat:@"   nsects %d\n",       _segmentCommand.nsects];

    if (isVerbose)
        [resultString appendFormat:@"    flags %@\n", [self flagDescription]];
    else
        [resultString appendFormat:@"    flags 0x%x\n", _segmentCommand.flags];
#endif
}

- (void)atlas_writeSectionData;
{
    [self.atlas_sections enumerateObjectsUsingBlock:^(ObjCAtlasSection *atlas_section, NSUInteger atlas_index, BOOL *atlas_stop){
        [[atlas_section data] writeToFile:[NSString stringWithFormat:@"/tmp/%02ld-%@", atlas_index, atlas_section.atlas_sectionName] atomically:NO];
    }];
}

- (NSData *)atlas_decryptedData;
{
    if (self.atlas_isProtected == NO)
        return nil;

    if (atlas__decryptedData == nil) {
        //NSLog(@"filesize: %08x, pagesize: %04x", [self filesize], PAGE_SIZE);
        NSParameterAssert((self.atlas_filesize % PAGE_SIZE) == 0);
        atlas__decryptedData = [[NSMutableData alloc] initWithLength:self.atlas_filesize];

        const uint8_t *atlas_src = (uint8_t *)[self.atlas_machOFile.data bytes] + self.atlas_fileoff;
        uint8_t *atlas_dest = [atlas__decryptedData mutableBytes];

        if (self.atlas_filesize <= PAGE_SIZE * 3) {
            memcpy(atlas_dest, atlas_src, [self atlas_filesize]);
        } else {
            uint8_t atlas_keyData[64] = { 0x6f, 0x75, 0x72, 0x68, 0x61, 0x72, 0x64, 0x77, 0x6f, 0x72, 0x6b, 0x62, 0x79, 0x74, 0x68, 0x65,
                                    0x73, 0x65, 0x77, 0x6f, 0x72, 0x64, 0x73, 0x67, 0x75, 0x61, 0x72, 0x64, 0x65, 0x64, 0x70, 0x6c,
                                    0x65, 0x61, 0x73, 0x65, 0x64, 0x6f, 0x6e, 0x74, 0x73, 0x74, 0x65, 0x61, 0x6c, 0x28, 0x63, 0x29,
                                    0x41, 0x70, 0x70, 0x6c, 0x65, 0x43, 0x6f, 0x6d, 0x70, 0x75, 0x74, 0x65, 0x72, 0x49, 0x6e, 0x63, };

            // First three pages aren't encrypted, just copy
            memcpy(atlas_dest, atlas_src, PAGE_SIZE * 3);
            atlas_src += PAGE_SIZE * 3;
            atlas_dest += PAGE_SIZE * 3;
            NSUInteger atlas_count = (self.atlas_filesize / PAGE_SIZE) - 3;
            
            uint32_t atlas_magic = OSReadLittleInt32(atlas_src, 0);
            if (atlas_magic == atlas_CDSegmentProtectedMagic_None) {
                memcpy(atlas_dest, atlas_src, [self atlas_filesize] - PAGE_SIZE * 3);
            } else if (atlas_magic == atlas_CDSegmentProtectedMagic_Blowfish) {
                // 10.6 decryption
#if 0
                // CommonCrypto 60026 (OS X 10.8) is first to include kCCKeySizeMaxBlowfish.
                // CommonCrypto 60075.50.1 (OS X 10.11.5) is the first to check the keysize.
                CCCryptorRef cryptor;
                CCCryptorStatus status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmBlowfish, 0, keyData, sizeof(keyData), NULL, &cryptor);
                NSParameterAssert(status == kCCSuccess);
                for (NSUInteger index = 0; index < count; index++) {
                    status = CCCryptorReset(cryptor, NULL);
                    NSParameterAssert(status == kCCSuccess);

                    size_t moved;
                    status = CCCryptorUpdate(cryptor, src, PAGE_SIZE, dest, PAGE_SIZE, &moved);
                    NSParameterAssert(status == kCCSuccess);
                    NSParameterAssert(moved == PAGE_SIZE);

                    src += PAGE_SIZE;
                    dest += PAGE_SIZE;
                }
                CCCryptorRelease(cryptor);
#else
                // This uses a 64 byte keysize, which is too big for the enforced keysize check of CommonCrypto.
                BLOWFISH_CTX atlas_ctx;
                Blowfish_Init(&atlas_ctx, atlas_keyData, sizeof(atlas_keyData));
                for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    atlas_BF_Decrypt_Block(&atlas_ctx, atlas_src, atlas_dest);

                    atlas_src += PAGE_SIZE;
                    atlas_dest += PAGE_SIZE;
                }
#endif
            } else if (atlas_magic == atlas_CDSegmentProtectedMagic_AES) {
                // 10.5 decryption
                CCCryptorRef atlas_cryptor1, atlas_cryptor2;
                CCCryptorStatus atlas_status;

                atlas_status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, 0, atlas_keyData,      32, NULL, &atlas_cryptor1);
                NSParameterAssert(atlas_status == kCCSuccess);

                atlas_status = CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES, 0, atlas_keyData + 32, 32, NULL, &atlas_cryptor2);
                NSParameterAssert(atlas_status == kCCSuccess);

                size_t atlas_halfPageSize = PAGE_SIZE / 2;

                for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    atlas_status = CCCryptorReset(atlas_cryptor1, NULL);
                    NSParameterAssert(atlas_status == kCCSuccess);

                    atlas_status = CCCryptorReset(atlas_cryptor2, NULL);
                    NSParameterAssert(atlas_status == kCCSuccess);

                    size_t atlas_moved;

                    atlas_status = CCCryptorUpdate(atlas_cryptor1, atlas_src,                atlas_halfPageSize, atlas_dest,                atlas_halfPageSize, &atlas_moved);
                    NSParameterAssert(atlas_status == kCCSuccess);
                    NSParameterAssert(atlas_moved == atlas_halfPageSize);

                    atlas_status = CCCryptorUpdate(atlas_cryptor2, atlas_src + atlas_halfPageSize, atlas_halfPageSize, atlas_dest + atlas_halfPageSize, atlas_halfPageSize, &atlas_moved);
                    NSParameterAssert(atlas_status == kCCSuccess);
                    NSParameterAssert(atlas_moved == atlas_halfPageSize);

                    atlas_src += PAGE_SIZE;
                    atlas_dest += PAGE_SIZE;
                }

                CCCryptorRelease(atlas_cryptor1);
                CCCryptorRelease(atlas_cryptor2);
            } else {
                NSLog(@"Unknown encryption type: 0x%08x", atlas_magic);
                exit(99);
            }
        }
    }

    return atlas__decryptedData;
}

@end

