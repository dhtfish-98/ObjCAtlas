//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDPathUnitTest.h"

#import <Foundation/Foundation.h>
#import "atlas_CDClassDump.h"

@implementation ObjCAtlasCDPathUnitTest

- (void)setUp;
{
    atlas_classDump = [[ObjCAtlasClassDump alloc] init];
}

- (void)tearDown;
{
    [atlas_classDump release];
    atlas_classDump = nil;
}

- (void)testAtlasPrivateSyncFramework;
{
    NSString *atlas_path = @"/System/Library/PrivateFrameworks/SyndicationUI.framework";
    NSBundle *atlas_bundle;

    atlas_bundle = [NSBundle bundleWithPath:atlas_path];
    STAssertNotNil(atlas_bundle, @"%@ doesn't seem to exist, we can remove this test now.", path);
    if (atlas_bundle != nil) {
        STAssertNil([atlas_bundle executablePath], @"This fails on 10.5.  It's fixed if you see this!  Executable path for %@", path);
        //STAssertNotNil([bundle executablePath], @"This fails on 10.5.  Executable path for %@", path);
    }
}

- (void)testAtlasBundlePathWithoutTrailingSlash;
{
    BOOL atlas_result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework"];
    STAssertEquals(YES, atlas_result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testAtlasBundlePathWithTrailingSlash;
{
    BOOL atlas_result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/"];
    STAssertEquals(YES, atlas_result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testAtlasExecutableSymlinkPath;
{
    BOOL atlas_result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/AppKit"];
    STAssertEquals(YES, atlas_result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

- (void)testAtlasExecutableFullPath;
{
    BOOL atlas_result;

    result = [classDump processFilename:@"/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit"];
    STAssertEquals(YES, atlas_result, @"Couldn't process AppKit.framework");
    STAssertEqualObjects(@"/System/Library/Frameworks/AppKit.framework/Versions/C", [classDump executablePath], @"");
}

@end
