// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDFatArch.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

@interface ObjCAtlasTestFatFile_armv7_v7s : XCTestCase
@end

@implementation ObjCAtlasTestFatFile_armv7_v7s
{
    ObjCAtlasFatFile *atlas__fatFile;
    ObjCAtlasFatArch *atlas__arch_v7;
    ObjCAtlasFatArch *atlas__arch_v7s;
    ObjCAtlasMachOFile *atlas__macho_v7;
    ObjCAtlasMachOFile *atlas__macho_v7s;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    atlas__fatFile = [[ObjCAtlasFatFile alloc] init];
    
    atlas__macho_v7 = [[ObjCAtlasMachOFile alloc] init];
    atlas__macho_v7.atlas_cputype    = CPU_TYPE_ARM;
    atlas__macho_v7.atlas_cpusubtype = CPU_SUBTYPE_ARM_V7;

    atlas__arch_v7 = [[ObjCAtlasFatArch alloc] initAtlasWithMachOFile:atlas__macho_v7];
    [atlas__fatFile atlas_addArchitecture:atlas__arch_v7];

    atlas__macho_v7s = [[ObjCAtlasMachOFile alloc] init];
    atlas__macho_v7s.atlas_cputype    = CPU_TYPE_ARM;
    atlas__macho_v7s.atlas_cpusubtype = 11;

    atlas__arch_v7s = [[ObjCAtlasFatArch alloc] initAtlasWithMachOFile:atlas__macho_v7s];
    [atlas__fatFile atlas_addArchitecture:atlas__arch_v7s];
}

- (void)tearDown;
{
    // Tear-down code here.
    atlas__fatFile   = nil;
    atlas__arch_v7   = nil;
    atlas__arch_v7s  = nil;
    atlas__macho_v7  = nil;
    atlas__macho_v7s = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)testAtlas_machOFileWithArch_armv7;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_ARM, CPU_SUBTYPE_ARM_V7 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__fatFile atlas_machOFileWithArch:atlas_arch];
    XCTAssertNotNil(atlas_machOFile,            @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(atlas_machOFile, atlas__macho_v7,  @"Didn't find correct Mach-O file");
}

- (void)testAtlas_machOFileWithArch_armv7s;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_ARM, 11 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__fatFile atlas_machOFileWithArch:atlas_arch];
    XCTAssertNotNil(atlas_machOFile,             @"The Mach-O file shouldn't be nil");
    XCTAssertEqual(atlas_machOFile, atlas__macho_v7s,  @"Didn't find correct Mach-O file");
}

@end
