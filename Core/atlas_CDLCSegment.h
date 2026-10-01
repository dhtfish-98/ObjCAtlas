// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@class ObjCAtlasSection;

#define atlas_CDSegmentProtectedMagic_None     0
#define atlas_CDSegmentProtectedMagic_AES      0xc2286295
#define atlas_CDSegmentProtectedMagic_Blowfish 0x2e69cf40

typedef enum : NSUInteger {
    atlas_CDSegmentEncryptionType_None     = 0,
    atlas_CDSegmentEncryptionType_AES      = 1, // 10.5 and earlier (AES)
    atlas_CDSegmentEncryptionType_Blowfish = 2, // 10.6 (Blowfish)
    atlas_CDSegmentEncryptionType_Unknown
} atlas_CDSegmentEncryptionType;

extern NSString *atlas_CDSegmentEncryptionTypeName(atlas_CDSegmentEncryptionType atlas_type);

@interface ObjCAtlasLCSegment : ObjCAtlasLoadCommand

@property (strong) NSString *name;
@property (strong) NSArray *atlas_sections;

@property (nonatomic, readonly) NSUInteger atlas_vmaddr;
@property (nonatomic, readonly) NSUInteger atlas_fileoff;
@property (nonatomic, readonly) NSUInteger atlas_filesize;
@property (nonatomic, readonly) vm_prot_t atlas_initprot;
@property (nonatomic, readonly) uint32_t atlas_flags;
@property (nonatomic, readonly) BOOL atlas_isProtected;

@property (nonatomic, readonly) atlas_CDSegmentEncryptionType atlas_encryptionType;
@property (nonatomic, readonly) BOOL atlas_canDecrypt;

- (NSString *)atlas_flagDescription;

- (BOOL)atlas_containsAddress:(NSUInteger)atlas_address;
- (ObjCAtlasSection *)atlas_sectionContainingAddress:(NSUInteger)atlas_address;
- (ObjCAtlasSection *)atlas_sectionWithName:(NSString *)atlas_name;
- (NSUInteger)atlas_fileOffsetForAddress:(NSUInteger)atlas_address;
- (NSUInteger)atlas_segmentOffsetForAddress:(NSUInteger)atlas_address;

- (void)atlas_writeSectionData;

- (NSData *)atlas_decryptedData;

@end
