// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDVisitor.h"

#import "atlas_CDClassDump.h"

@implementation ObjCAtlasVisitor
{
    ObjCAtlasClassDump *atlas__classDump;
    BOOL atlas__shouldShowStructureSection;
    BOOL atlas__shouldShowProtocolSection;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_classDump = atlas__classDump;
@synthesize atlas_shouldShowStructureSection = atlas__shouldShowStructureSection;
@synthesize atlas_shouldShowProtocolSection = atlas__shouldShowProtocolSection;

- (id)init;
{
    if ((self = [super init])) {
        atlas__shouldShowStructureSection = YES;
        atlas__shouldShowProtocolSection  = YES;
    }
    
    return self;
}

#pragma mark -

- (void)atlas_willBeginVisiting;
{
}

- (void)atlas_didEndVisiting;
{
}

// Called before visiting.
- (void)atlas_willVisitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
}

// This gets called before visiting the children, but only if it has children it will visit.
- (void)atlas_visitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
}

- (void)atlas_willVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
}

- (void)atlas_didVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
}

- (void)atlas_willVisitOptionalMethods;
{
}

- (void)atlas_didVisitOptionalMethods;
{
}

// Called after visiting.
- (void)atlas_didVisitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
}

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
}

- (void)atlas_didVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
}

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_didVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_willVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_didVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_willVisitPropertiesOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_didVisitPropertiesOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
}

- (void)atlas_didVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
}

- (void)atlas_willVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;
{
}

- (void)atlas_didVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;
{
}

- (void)atlas_visitClassMethod:(ObjCAtlasOCMethod *)atlas_method;
{
}

- (void)atlas_visitInstanceMethod:(ObjCAtlasOCMethod *)atlas_method atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
}

- (void)atlas_visitIvar:(ObjCAtlasOCInstanceVariable *)atlas_ivar;
{
}

- (void)atlas_visitProperty:(ObjCAtlasOCProperty *)atlas_property;
{
}

- (void)atlas_visitRemainingProperties:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
}

@end
