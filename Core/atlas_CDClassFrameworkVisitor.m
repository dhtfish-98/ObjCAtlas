// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDClassFrameworkVisitor.h"

#import "atlas_CDMachOFile.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDObjectiveCProcessor.h"
#import "atlas_CDSymbol.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDOCClassReference.h"

@interface ObjCAtlasClassFrameworkVisitor ()
@property (strong) NSString *atlas_frameworkName;
@end

#pragma mark -

@implementation ObjCAtlasClassFrameworkVisitor
{
    NSMutableDictionary *atlas__frameworkNamesByClassName;
    NSMutableDictionary *atlas__frameworkNamesByProtocolName;
    NSString *atlas__frameworkName;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_frameworkName = atlas__frameworkName;
@synthesize atlas_frameworkNamesByClassName = atlas__frameworkNamesByClassName;
@synthesize atlas_frameworkNamesByProtocolName = atlas__frameworkNamesByProtocolName;

- (id)init;
{
    if ((self = [super init])) {
        atlas__frameworkNamesByClassName = [[NSMutableDictionary alloc] init];
        atlas__frameworkNamesByProtocolName = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)atlas_willVisitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
    self.atlas_frameworkName = atlas_processor.atlas_machOFile.atlas_importBaseName;
}

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    [self atlas_addClassName:atlas_aClass.name atlas_referencedInFramework:self.atlas_frameworkName];
    
    // We only need to add superclasses for external classes - classes defined in this binary will be visited on their own
    ObjCAtlasOCClassReference *atlas_superClassRef = [atlas_aClass atlas_superClassRef];
    if ([atlas_superClassRef atlas_isExternalClass] && atlas_superClassRef.atlas_classSymbol != nil) {
        [self atlas_addClassForExternalSymbol:atlas_superClassRef.atlas_classSymbol];
    }
}

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    // TODO: (2012-02-28) Figure out what frameworks use each protocol, and try to pick the correct one.  More difficult because, for example, NSCopying is found in many frameworks, and picking the last one isn't good enough.  Perhaps a topological sort of the dependancies would be better.
    [self atlas_addProtocolName:atlas_protocol.name atlas_referencedInFramework:self.atlas_frameworkName];
}

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    ObjCAtlasOCClassReference *atlas_classRef = [atlas_category atlas_classRef];
    if ([atlas_classRef atlas_isExternalClass] && atlas_classRef.atlas_classSymbol != nil) {
        [self atlas_addClassForExternalSymbol:atlas_classRef.atlas_classSymbol];
    }
}

#pragma mark -

- (void)atlas_addClassForExternalSymbol:(ObjCAtlasSymbol *)atlas_symbol;
{
    NSString *atlas_frameworkName = atlas_CDImportNameForPath([[atlas_symbol atlas_dylibLoadCommand] path]);
    NSString *atlas_className = [ObjCAtlasSymbol atlas_classNameFromSymbolName:[atlas_symbol name]];
    [self atlas_addClassName:atlas_className atlas_referencedInFramework:atlas_frameworkName];
}

- (void)atlas_addClassName:(NSString *)atlas_name atlas_referencedInFramework:(NSString *)atlas_frameworkName;
{
    if (atlas_name != nil && atlas_frameworkName != nil)
        atlas__frameworkNamesByClassName[atlas_name] = atlas_frameworkName;
}

- (void)atlas_addProtocolName:(NSString *)atlas_name atlas_referencedInFramework:(NSString *)atlas_frameworkName;
{
    if (atlas_name != nil && atlas_frameworkName != nil)
        atlas__frameworkNamesByProtocolName[atlas_name] = atlas_frameworkName;
}

- (NSDictionary *)atlas_frameworkNamesByClassName;
{
    return [atlas__frameworkNamesByClassName copy];
}

- (NSDictionary *)atlas_frameworkNamesByProtocolName;
{
    return [atlas__frameworkNamesByProtocolName copy];
}

@end
