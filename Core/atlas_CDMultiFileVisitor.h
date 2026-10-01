// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTextClassDumpVisitor.h"

#import "atlas_CDTypeController.h" // For CDTypeControllerDelegate protocol

// This generates separate files for each class.  Files are created in the 'outputPath' directory.

@interface ObjCAtlasMultiFileVisitor : ObjCAtlasTextClassDumpVisitor <ObjCAtlasTypeControllerDelegate>

@property (strong) NSString *atlas_outputPath;

@end
