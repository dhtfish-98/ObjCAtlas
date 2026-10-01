// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDFatArch.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

@interface ObjCAtlasTestFatFile_Intel64_32 : XCTestCase
@end

@implementation ObjCAtlasTestFatFile_Intel64_32
{
    ObjCAtlasFatFile *atlas__fatFile;
    ObjCAtlasFatArch *atlas__arch_i386;
    ObjCAtlasFatArch *atlas__arch_x86_64;
    ObjCAtlasMachOFile *atlas__macho_i386;
    ObjCAtlasMachOFile *atlas__macho_x86_64;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    atlas__fatFile = [[ObjCAtlasFatFile alloc] init];
    
    atlas__macho_x86_64 = [[ObjCAtlasMachOFile alloc] init];
    atlas__macho_x86_64.atlas_cputype    = CPU_TYPE_X86_64;
    atlas__macho_x86_64.atlas_cpusubtype = CPU_SUBTYPE_386;
    
    atlas__arch_x86_64 = [[ObjCAtlasFatArch alloc] initAtlasWithMachOFile:atlas__macho_x86_64];
    [atlas__fatFile atlas_addArchitecture:atlas__arch_x86_64];
    
    atlas__macho_i386 = [[ObjCAtlasMachOFile alloc] init];
    atlas__macho_i386.atlas_cputype    = CPU_TYPE_X86;
    atlas__macho_i386.atlas_cpusubtype = CPU_SUBTYPE_386;
    
    atlas__arch_i386 = [[ObjCAtlasFatArch alloc] initAtlasWithMachOFile:atlas__macho_i386];
    [atlas__fatFile atlas_addArchitecture:atlas__arch_i386];
}

- (void)tearDown;
{
    // Tear-down code here.
    atlas__fatFile      = nil;
    atlas__arch_i386    = nil;
    atlas__arch_x86_64  = nil;
    atlas__macho_i386   = nil;
    atlas__macho_x86_64 = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)testAtlas_bestMatchIntel64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    
    BOOL atlas_result = [atlas__fatFile atlas_bestMatchForArch:&atlas_arch];
    XCTAssertTrue(atlas_result,                             @"Didn't find a best match for x86_64");
    XCTAssertTrue(atlas_arch.atlas_cputype == CPU_TYPE_X86_64,    @"Best match cputype should be CPU_TYPE_X86_64");
    XCTAssertTrue(atlas_arch.atlas_cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}

#if 0
// We don't build 32-bit any more, so this test case shouldn't come up.
- (void)test_bestMatchIntel32;
{
    CDArch arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    
    BOOL result = [_intel_64_32 bestMatchForArch:&arch];
    XCTAssertTrue(result,                             @"Didn't find a best match for i386");
    XCTAssertTrue(arch.cputype == CPU_TYPE_X86,       @"Best match cputype should be CPU_TYPE_X86");
    XCTAssertTrue(arch.cpusubtype == CPU_SUBTYPE_386, @"Best match cpusubtype should be CPU_SUBTYPE_386");
}
#endif

- (void)testAtlas_machOFileWithArch_x86_64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__fatFile atlas_machOFileWithArch:atlas_arch];
    XCTAssertNotNil(atlas_machOFile,               @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(atlas_machOFile, atlas__macho_x86_64, @"Didn't find correct Mach-O file", NULL);
}

- (void)testAtlas_machOFileWithArch_i386;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__fatFile atlas_machOFileWithArch:atlas_arch];
    XCTAssertNotNil(atlas_machOFile,             @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(atlas_machOFile, atlas__macho_i386, @"Didn't find correct Mach-O file");
}

@end
