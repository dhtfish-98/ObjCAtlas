// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCProtocol.h"

#import "atlas_CDTopologicalSortProtocol.h"

@class ObjCAtlasOCClassReference;

@interface ObjCAtlasOCClass : ObjCAtlasOCProtocol <ObjCAtlasTopologicalSort>

@property (strong) ObjCAtlasOCClassReference *atlas_superClassRef;
@property (copy, readonly) NSString *atlas_superClassName;
@property (strong) NSArray *atlas_instanceVariables;
@property (assign) BOOL atlas_isExported;
@property (assign) BOOL atlas_isSwiftClass;

@end
