// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCClass.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDOCInstanceVariable.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDTypeParser.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDVisitorPropertyState.h"
#import "atlas_CDOCClassReference.h"

@implementation ObjCAtlasOCClass
{
    NSArray *atlas__instanceVariables;

    BOOL atlas__isExported;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_instanceVariables = atlas__instanceVariables;
@synthesize atlas_isExported = atlas__isExported;

- (id)init;
{
    if ((self = [super init])) {
        atlas__isExported = YES;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@, exported: %@", [super description], self.atlas_isExported ? @"YES" : @"NO"];
}

#pragma mark -

- (NSString *)atlas_superClassName;
{
    return [_atlas_superClassRef className];
}

- (void)atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
{
    [super atlas_registerTypesWithObject:atlas_typeController atlas_phase:atlas_phase];

    for (ObjCAtlasOCInstanceVariable *atlas_instanceVariable in self.atlas_instanceVariables) {
        [atlas_instanceVariable.type atlas_phase:atlas_phase atlas_registerTypesWithObject:atlas_typeController atlas_usedInMethod:NO];
    }
}

- (NSString *)atlas_methodSearchContext;
{
    NSMutableString *atlas_resultString = [NSMutableString string];

    [atlas_resultString appendFormat:@"@interface %@", self.name];
    if (self.atlas_superClassName != nil)
        [atlas_resultString appendFormat:@" : %@", self.atlas_superClassName];

    if ([self.atlas_protocols count] > 0)
        [atlas_resultString appendFormat:@" <%@>", self.atlas_protocolsString];

    return atlas_resultString;
}

- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;
{
    if ([atlas_visitor.atlas_classDump atlas_shouldShowName:self.name]) {
        ObjCAtlasVisitorPropertyState *atlas_propertyState = [[ObjCAtlasVisitorPropertyState alloc] initWithProperties:self.properties];
        
        [atlas_visitor atlas_willVisitClass:self];
        
        [atlas_visitor atlas_willVisitIvarsOfClass:self];
        for (ObjCAtlasOCInstanceVariable *atlas_instanceVariable in self.atlas_instanceVariables)
            [atlas_visitor atlas_visitIvar:atlas_instanceVariable];
        [atlas_visitor atlas_didVisitIvarsOfClass:self];
        
        //[visitor willVisitPropertiesOfClass:self];
        //[self visitProperties:visitor];
        //[visitor didVisitPropertiesOfClass:self];
        
        [self atlas_visitMethods:atlas_visitor atlas_propertyState:atlas_propertyState];
        // Should mostly be dynamic properties
        [atlas_visitor atlas_visitRemainingProperties:atlas_propertyState];
        [atlas_visitor atlas_didVisitClass:self];
    }
}

#pragma mark - CDTopologicalSort protocol

- (NSString *)identifier;
{
    return self.name;
}

- (NSArray *)atlas_dependancies;
{
    if (self.atlas_superClassName == nil)
        return @[];

    return @[self.atlas_superClassName];
}

@end
