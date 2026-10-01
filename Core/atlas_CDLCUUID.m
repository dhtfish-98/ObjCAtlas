// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCUUID.h"

#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCUUID
{
    struct uuid_command atlas__uuidCommand;
    
    NSUUID *atlas__UUID;
}

// Preserve the original explicit property storage after renaming.
@synthesize UUID = atlas__UUID;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__uuidCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__uuidCommand.cmdsize = [atlas_cursor atlas_readInt32];
        for (NSUInteger atlas_index = 0; atlas_index < sizeof(atlas__uuidCommand.uuid); atlas_index++) {
            atlas__uuidCommand.uuid[atlas_index] = [atlas_cursor atlas_readByte];
        }
        atlas__UUID = [[NSUUID alloc] initWithUUIDBytes:atlas__uuidCommand.uuid];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__uuidCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__uuidCommand.cmdsize;
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [super atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];

    [atlas_resultString appendString:@"    uuid "];
    [atlas_resultString appendString:[self.UUID UUIDString]];
    [atlas_resultString appendString:@"\n"];
}

- (NSString *)atlas_extraDescription;
{
    return [self.UUID UUIDString];
}

@end
