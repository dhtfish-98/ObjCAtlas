// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCEncryptionInfo.h"

// This is used on iOS.

@implementation ObjCAtlasLCEncryptionInfo
{
    struct encryption_info_command_64 atlas__encryptionInfoCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__encryptionInfoCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__encryptionInfoCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__encryptionInfoCommand.cryptoff  = [atlas_cursor atlas_readInt32];
        atlas__encryptionInfoCommand.cryptsize = [atlas_cursor atlas_readInt32];
        atlas__encryptionInfoCommand.cryptid   = [atlas_cursor atlas_readInt32];
        if (atlas__encryptionInfoCommand.cmd == LC_ENCRYPTION_INFO_64) {
            atlas__encryptionInfoCommand.pad = [atlas_cursor atlas_readInt32];
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__encryptionInfoCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__encryptionInfoCommand.cmdsize;
}

- (uint32_t)atlas_cryptoff;
{
    return atlas__encryptionInfoCommand.cryptoff;
}

- (uint32_t)atlas_cryptsize;
{
    return atlas__encryptionInfoCommand.cryptsize;
}

- (uint32_t)atlas_cryptid;
{
    return atlas__encryptionInfoCommand.cryptid;
}

- (BOOL)atlas_isEncrypted;
{
    return atlas__encryptionInfoCommand.cryptid != 0;
}

@end
