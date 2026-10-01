// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDFatArch.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

@interface ObjCAtlasTestThinFile_Intel64_lib64 : XCTestCase
@end

@implementation ObjCAtlasTestThinFile_Intel64_lib64
{
    ObjCAtlasMachOFile *atlas__macho_x86_64;
}

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
    atlas__macho_x86_64 = [[ObjCAtlasMachOFile alloc] init];
    atlas__macho_x86_64.atlas_cputype    = CPU_TYPE_X86_64;
    atlas__macho_x86_64.atlas_cpusubtype = CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64; // For example, /Applications/Utilities/Grab.app on 10.8
}

- (void)tearDown;
{
    // Tear-down code here.
    atlas__macho_x86_64  = nil;
    
    [super tearDown];
}

#pragma mark -

- (void)testAtlas_bestMatchIntel64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    
    BOOL atlas_result = [atlas__macho_x86_64 atlas_bestMatchForArch:&atlas_arch];
    XCTAssertTrue(atlas_result,                                                                  @"Didn't find a best match for x86_64");
    XCTAssertTrue(atlas_arch.atlas_cputype == CPU_TYPE_X86_64,                                         @"Best match cputype should be CPU_TYPE_X86_64");
    XCTAssertTrue(atlas_arch.atlas_cpusubtype == (cpu_subtype_t)(CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64), @"Best match cpusubtype should be CPU_SUBTYPE_386");
}

- (void)testAtlas_machOFileWithArch_x86_64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__macho_x86_64 atlas_machOFileWithArch:atlas_arch];
    XCTAssertNotNil(atlas_machOFile,               @"The Mach-O file shouldn't be nil", NULL);
    XCTAssertEqual(atlas_machOFile, atlas__macho_x86_64, @"Didn't find correct Mach-O file", NULL);
}

- (void)testAtlas_machOFileWithArch_i386;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    ObjCAtlasMachOFile *atlas_machOFile = [atlas__macho_x86_64 atlas_machOFileWithArch:atlas_arch];
    XCTAssertNil(atlas_machOFile, @"The Mach-O file should be nil", NULL);
}

@end
