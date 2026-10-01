// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCDylib.h"

#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

static NSString *atlas_CDDylibVersionString(uint32_t atlas_version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", atlas_version >> 16, (atlas_version >> 8) & 0xff, atlas_version & 0xff];
}

@implementation ObjCAtlasLCDylib
{
    struct dylib_command atlas__dylibCommand;
    NSString *atlas__path;
}

// Preserve the original explicit property storage after renaming.
@synthesize path = atlas__path;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__dylibCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__dylibCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__dylibCommand.dylib.name.offset           = [atlas_cursor atlas_readInt32];
        atlas__dylibCommand.dylib.timestamp             = [atlas_cursor atlas_readInt32];
        atlas__dylibCommand.dylib.current_version       = [atlas_cursor atlas_readInt32];
        atlas__dylibCommand.dylib.compatibility_version = [atlas_cursor atlas_readInt32];
        
        NSUInteger atlas_length = atlas__dylibCommand.cmdsize - sizeof(atlas__dylibCommand);
        //NSLog(@"expected length: %u", length);
        
        atlas__path = [atlas_cursor atlas_readStringOfLength:atlas_length atlas_encoding:NSASCIIStringEncoding];
        //NSLog(@"path: %@", path);
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__dylibCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__dylibCommand.cmdsize;
}

- (uint32_t)atlas_timestamp;
{
    return atlas__dylibCommand.dylib.timestamp;
}

- (uint32_t)atlas_currentVersion;
{
    return atlas__dylibCommand.dylib.current_version;
}

- (uint32_t)atlas_compatibilityVersion;
{
    return atlas__dylibCommand.dylib.compatibility_version;
}

- (NSString *)atlas_formattedCurrentVersion;
{
    return atlas_CDDylibVersionString(self.atlas_currentVersion);
}

- (NSString *)atlas_formattedCompatibilityVersion;
{
    return atlas_CDDylibVersionString(self.atlas_compatibilityVersion);
}

#if 0
- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"%@ (compatibility version %@, current version %@, timestamp %d [%@])",
                     self.path, CDDylibVersionString(self.compatibilityVersion), CDDylibVersionString(self.currentVersion),
                     self.timestamp, [NSDate dateWithTimeIntervalSince1970:self.timestamp]];
}
#endif

@end
