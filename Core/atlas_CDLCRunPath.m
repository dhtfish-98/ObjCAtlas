// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCRunPath.h"

#import "atlas_CDMachOFile.h"
#import "atlas_CDSearchPathState.h"

@implementation ObjCAtlasLCRunPath
{
    struct rpath_command atlas__rpathCommand;
    NSString *atlas__path;
}

// Preserve the original explicit property storage after renaming.
@synthesize path = atlas__path;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__rpathCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__rpathCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__rpathCommand.path.offset = [atlas_cursor atlas_readInt32];
        
        NSUInteger atlas_length = atlas__rpathCommand.cmdsize - sizeof(atlas__rpathCommand);
        //NSLog(@"expected length: %u", length);
        
        atlas__path = [atlas_cursor atlas_readStringOfLength:atlas_length atlas_encoding:NSASCIIStringEncoding];
        //NSLog(@"path: %@", _path);
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__rpathCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__rpathCommand.cmdsize;
}

- (NSString *)atlas_resolvedRunPath;
{
    NSString *atlas_loaderPathPrefix = @"@loader_path";
    NSString *atlas_executablePathPrefix = @"@executable_path";

    if ([self.path hasPrefix:atlas_loaderPathPrefix]) {
        NSString *atlas_loaderPath = [self.atlas_machOFile.filename stringByDeletingLastPathComponent];
        NSString *atlas_str = [[self.path stringByReplacingOccurrencesOfString:atlas_loaderPathPrefix withString:atlas_loaderPath] stringByStandardizingPath];

        return atlas_str;
    }

    if ([self.path hasPrefix:atlas_executablePathPrefix]) {
        NSString *atlas_str = @"";
        NSString *atlas_executablePath = self.atlas_machOFile.atlas_searchPathState.executablePath;
        if (atlas_executablePath)
            atlas_str = [[self.path stringByReplacingOccurrencesOfString:atlas_executablePathPrefix withString:atlas_executablePath] stringByStandardizingPath];

        return atlas_str;
    }

    return self.path;
}

@end
