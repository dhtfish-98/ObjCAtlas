// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

// Importing these here saves us from importing them in the implementation of every load command.
#include <mach-o/loader.h>
#import "atlas_CDMachOFileDataCursor.h"

@class ObjCAtlasMachOFile;

@interface ObjCAtlasLoadCommand : NSObject

+ (id)atlas_loadCommandWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;

- (NSString *)atlas_extraDescription;

@property (weak, readonly) ObjCAtlasMachOFile *atlas_machOFile;
@property (readonly) NSUInteger atlas_commandOffset;

@property (nonatomic, readonly) uint32_t atlas_cmd;
@property (nonatomic, readonly) uint32_t atlas_cmdsize;
@property (nonatomic, readonly) BOOL atlas_mustUnderstandToExecute;

@property (nonatomic, readonly) NSString *commandName;

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;

- (void)atlas_machOFileDidReadLoadCommands:(ObjCAtlasMachOFile *)atlas_machOFile;

@end
