// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCBuildVersion.h"

#import "atlas_CDMachOFile.h"

static NSString *atlas_NSStringFromBuildVersionPlatform(uint32_t atlas_platform)
{
    switch (atlas_platform) {
        case PLATFORM_MACOS:            return @"macOS";
        case PLATFORM_IOS:              return @"iOS";
        case PLATFORM_TVOS:             return @"tvOS";
        case PLATFORM_WATCHOS:          return @"watchOS";
        case PLATFORM_BRIDGEOS:         return @"bridgeOS";
        case PLATFORM_IOSMAC:           return @"iOS Mac";
        case PLATFORM_IOSSIMULATOR:     return @"iOS Simulator";
        case PLATFORM_TVOSSIMULATOR:    return @"tvOS Simulator";
        case PLATFORM_WATCHOSSIMULATOR: return @"watchOS Simulator";
        default:               return [NSString stringWithFormat:@"Unknown platform %x", atlas_platform];
    }
}

static NSString *atlas_NSStringFromBuildVersionTool(uint32_t atlas_tool)
{
    switch (atlas_tool) {
        case TOOL_CLANG: return @"clang";
        case TOOL_SWIFT: return @"swift";
        case TOOL_LD:    return @"ld";
        default:         return [NSString stringWithFormat:@"Unknown tool %x", atlas_tool];
    }
}

static NSString *atlas_NSStringFromBuildVersionToolNotATuple(uint64_t atlas_tuple)
{
    uint32_t atlas_tool = atlas_tuple >> 32;
    uint32_t atlas_version = atlas_tuple & 0xffffffff;
    return [NSString stringWithFormat:@"%@ %u.%u.%u", atlas_NSStringFromBuildVersionTool(atlas_tool),
            atlas_version >> 16,
            (atlas_version >> 8) & 0xff,
            atlas_version & 0xff];
}

@implementation ObjCAtlasLCBuildVersion
{
    struct build_version_command atlas__buildVersionCommand;
    NSArray *atlas__tools;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__buildVersionCommand.cmd      = [atlas_cursor atlas_readInt32];
        atlas__buildVersionCommand.cmdsize  = [atlas_cursor atlas_readInt32];
        atlas__buildVersionCommand.platform = [atlas_cursor atlas_readInt32];
        atlas__buildVersionCommand.minos    = [atlas_cursor atlas_readInt32];
        atlas__buildVersionCommand.sdk      = [atlas_cursor atlas_readInt32];
        atlas__buildVersionCommand.ntools   = [atlas_cursor atlas_readInt32];
        NSMutableArray *atlas_tools = [NSMutableArray array];
        for (NSUInteger atlas_index = 0; atlas_index < atlas__buildVersionCommand.ntools; atlas_index++) {
            // ISO tuples.
            uint32_t atlas_tool    = [atlas_cursor atlas_readInt32];
            uint32_t atlas_version = [atlas_cursor atlas_readInt32];
            uint64_t atlas_iso_tuples = ((uint64_t)atlas_tool << 32) | atlas_version;
            [atlas_tools addObject:@(atlas_iso_tuples)];
        }
        atlas__tools = [atlas_tools copy];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__buildVersionCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__buildVersionCommand.cmdsize;
}

- (NSString *)atlas_buildVersionString;
{
    return [NSString stringWithFormat:@"Platform: %@ %u.%u.%u, SDK: %u.%u.%u",
            atlas_NSStringFromBuildVersionPlatform(atlas__buildVersionCommand.platform),
            atlas__buildVersionCommand.minos >> 16,
            (atlas__buildVersionCommand.minos >> 8) & 0xff,
            atlas__buildVersionCommand.minos & 0xff,

            atlas__buildVersionCommand.sdk >> 16,
            (atlas__buildVersionCommand.sdk >> 8) & 0xff,
            atlas__buildVersionCommand.sdk & 0xff];
}

- (NSArray *)atlas_toolStrings;
{
    NSMutableArray *atlas_tools = [NSMutableArray array];
    // iso map
    for (NSNumber *atlas_tuple in atlas__tools) {
        [atlas_tools addObject:atlas_NSStringFromBuildVersionToolNotATuple([atlas_tuple unsignedLongLongValue])];
    }

    return [atlas_tools copy];
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [super atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];

    [atlas_resultString appendFormat:@"    Build version: %@\n", self.atlas_buildVersionString];
}

@end
