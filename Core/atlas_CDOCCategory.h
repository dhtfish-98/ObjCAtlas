// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCProtocol.h"

@class ObjCAtlasOCClassReference;

@interface ObjCAtlasOCCategory : ObjCAtlasOCProtocol <ObjCAtlasTopologicalSort>

@property (strong) ObjCAtlasOCClassReference *atlas_classRef;
@property (strong, readonly) NSString *className;

- (NSString *)atlas_methodSearchContext;
- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;

@end
