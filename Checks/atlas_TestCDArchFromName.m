// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDFile.h"

@interface ObjCAtlasTestCDArchFromName : XCTestCase
@end

@implementation ObjCAtlasTestCDArchFromName

- (void)setUp;
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown;
{
    // Tear-down code here.
    
    [super tearDown];
}

#pragma mark - ARM

- (void)testAtlas_armv6;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"armv6");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv6' should be ARM");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, CPU_SUBTYPE_ARM_V6, @"The cpusubtype for 'armv6' should be ARM_V6");
}

- (void)testAtlas_armv7;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"armv7");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv7' should be ARM");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, CPU_SUBTYPE_ARM_V7, @"The cpusubtype for 'armv7' should be ARM_V7");
}

- (void)testAtlas_armv7s;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"armv7s");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_ARM,       @"The cputype for 'armv7s' should be ARM");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, 11,                 @"The cpusubtype for 'armv7s' should be 11");
}

- (void)testAtlas_arm64;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"arm64");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_ARM | CPU_ARCH_ABI64, @"The cputype for 'arm64' should be ARM with 64-bit mask");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, CPU_SUBTYPE_ARM_ALL,           @"The cpusubtype for 'arm64' should be CPU_SUBTYPE_ARM_ALL");
}

#pragma mark - Intel x86

- (void)testAtlas_i386;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"i386");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_X86,       @"The cputype for 'i386' should be X86");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, CPU_SUBTYPE_386,    @"The cpusubtype for 'i386' should be 386");
}

- (void)testAtlas_x86_64;
{
    atlas_CDArch atlas_arch = atlas_CDArchFromName(@"x86_64");
    XCTAssertEqual(atlas_arch.atlas_cputype,    CPU_TYPE_X86_64,    @"The cputype for 'x86_64' should be X86_64");
    XCTAssertEqual(atlas_arch.atlas_cpusubtype, CPU_SUBTYPE_386,    @"The cpusubtype for 'x86_64' should be 386");
}

@end
