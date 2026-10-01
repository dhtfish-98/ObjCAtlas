// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDFile.h"

@interface ObjCAtlasTestCDArchUses64BitABI : XCTestCase
@end

@implementation ObjCAtlasTestCDArchUses64BitABI

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

#pragma mark - Intel x86

- (void)testAtlas_i386;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86, CPU_SUBTYPE_386 };
    XCTAssertFalse(atlas_CDArchUses64BitABI(atlas_arch), @"i386 does not use 64 bit ABI");
}

- (void)testAtlas_x86_64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 };
    XCTAssertTrue(atlas_CDArchUses64BitABI(atlas_arch), @"x86_64 uses 64 bit ABI");
}

- (void)testAtlas_x86_64_lib64;
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64, CPU_SUBTYPE_386 | CPU_SUBTYPE_LIB64 };
    XCTAssertTrue(atlas_CDArchUses64BitABI(atlas_arch), @"x86_64 (with LIB64 capability bit) uses 64 bit ABI");
}

- (void)testAtlas_x86_64_plusOtherCapablity
{
    atlas_CDArch atlas_arch = { CPU_TYPE_X86_64 | 0x40000000, CPU_SUBTYPE_386 };
    XCTAssertTrue(atlas_CDArchUses64BitABI(atlas_arch), @"x86_64 (with other capability bit) uses 64 bit ABI");
}

@end
