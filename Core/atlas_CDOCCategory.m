// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCCategory.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDVisitorPropertyState.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCClassReference.h"

@implementation ObjCAtlasOCCategory

#pragma mark - Superclass overrides

- (NSString *)atlas_sortableName;
{
    return [NSString stringWithFormat:@"%@ (%@)", self.className, self.name];
}

#pragma mark -

- (NSString *)className
{
    return [_atlas_classRef className];
}

- (NSString *)atlas_methodSearchContext;
{
    NSMutableString *atlas_resultString = [NSMutableString string];

    [atlas_resultString appendFormat:@"@interface %@ (%@)", self.className, self.name];

    if ([self.atlas_protocols count] > 0)
        [atlas_resultString appendFormat:@" <%@>", self.atlas_protocolsString];

    return atlas_resultString;
}

- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;
{
    if ([atlas_visitor.atlas_classDump atlas_shouldShowName:self.name]) {
        ObjCAtlasVisitorPropertyState *atlas_propertyState = [[ObjCAtlasVisitorPropertyState alloc] initWithProperties:self.properties];
        
        [atlas_visitor atlas_willVisitCategory:self];
        
        //[aVisitor willVisitPropertiesOfCategory:self];
        //[self visitProperties:aVisitor];
        //[aVisitor didVisitPropertiesOfCategory:self];
        
        [self atlas_visitMethods:atlas_visitor atlas_propertyState:atlas_propertyState];
        // This can happen when... the accessors are implemented on the main class.  Odd case, but we should still emit the remaining properties.
        // Should mostly be dynamic properties
        [atlas_visitor atlas_visitRemainingProperties:atlas_propertyState];
        [atlas_visitor atlas_didVisitCategory:self];
    }
}

#pragma mark - CDTopologicalSort protocol

- (NSString *)identifier;
{
    return self.atlas_sortableName;
}

- (NSArray *)atlas_dependancies;
{
    if (self.className == nil)
        return @[];

    return @[self.className];
}

@end
