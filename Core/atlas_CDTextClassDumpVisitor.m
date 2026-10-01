// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTextClassDumpVisitor.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDOCProperty.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDVisitorPropertyState.h"
#import "atlas_CDOCInstanceVariable.h"

static BOOL atlas_debug = NO;

@interface ObjCAtlasTextClassDumpVisitor ()
@end

#pragma mark -

@implementation ObjCAtlasTextClassDumpVisitor
{
    NSMutableString *atlas__resultString;
}

- (id)init;
{
    if ((self = [super init])) {
        atlas__resultString = [[NSMutableString alloc] init];
    }

    return self;
}

#pragma mark -

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    if (atlas_aClass.atlas_isExported == NO)
        [self.atlas_resultString appendString:@"__attribute__((visibility(\"hidden\")))\n"];

    [self.atlas_resultString appendFormat:@"@interface %@", atlas_aClass.name];
    if (atlas_aClass.atlas_superClassName != nil)
        [self.atlas_resultString appendFormat:@" : %@", atlas_aClass.atlas_superClassName];

    NSArray *atlas_protocols = atlas_aClass.atlas_protocols;
    if ([atlas_protocols count] > 0) {
        [self.atlas_resultString appendFormat:@" <%@>", atlas_aClass.atlas_protocolsString];
    }

    [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_didVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    if (atlas_aClass.atlas_hasMethods)
        [self.atlas_resultString appendString:@"\n"];

    [self.atlas_resultString appendString:@"@end\n\n"];
}

- (void)atlas_willVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    [self.atlas_resultString appendString:@"{\n"];
}

- (void)atlas_didVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    [self.atlas_resultString appendString:@"}\n\n"];
}

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    [self.atlas_resultString appendFormat:@"@interface %@ (%@)", atlas_category.className, atlas_category.name];

    NSArray *atlas_protocols = atlas_category.atlas_protocols;
    if ([atlas_protocols count] > 0) {
        [self.atlas_resultString appendFormat:@" <%@>", atlas_category.atlas_protocolsString];
    }

    [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_didVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    [self.atlas_resultString appendString:@"@end\n\n"];
}

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    [self.atlas_resultString appendFormat:@"@protocol %@", atlas_protocol.name];

    NSArray *atlas_protocols = atlas_protocol.atlas_protocols;
    if ([atlas_protocols count] > 0) {
        [self.atlas_resultString appendFormat:@" <%@>", atlas_protocol.atlas_protocolsString];
    }

    [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_willVisitOptionalMethods;
{
    [self.atlas_resultString appendString:@"\n@optional\n"];
}

- (void)atlas_didVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    [self.atlas_resultString appendString:@"@end\n\n"];
}

- (void)atlas_visitClassMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    [self.atlas_resultString appendString:@"+ "];
    [atlas_method atlas_appendToString:self.atlas_resultString atlas_typeController:self.atlas_classDump.atlas_typeController];
    [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_visitInstanceMethod:(ObjCAtlasOCMethod *)atlas_method atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
    ObjCAtlasOCProperty *atlas_property = [atlas_propertyState atlas_propertyForAccessor:atlas_method.name];
    if (atlas_property == nil) {
        //NSLog(@"No property for method: %@", method.name);
        [self.atlas_resultString appendString:@"- "];
        [atlas_method atlas_appendToString:self.atlas_resultString atlas_typeController:self.atlas_classDump.atlas_typeController];
        [self.atlas_resultString appendString:@"\n"];
    } else {
        if ([atlas_propertyState atlas_hasUsedProperty:atlas_property] == NO) {
            //NSLog(@"Emitting property %@ triggered by method %@", property.name, method.name);
            [self atlas_visitProperty:atlas_property];
            [atlas_propertyState atlas_useProperty:atlas_property];
        } else {
            //NSLog(@"Have already emitted property %@ triggered by method %@", property.name, method.name);
        }
    }
}

- (void)atlas_visitIvar:(ObjCAtlasOCInstanceVariable *)atlas_ivar;
{
    [atlas_ivar atlas_appendToString:self.atlas_resultString atlas_typeController:self.atlas_classDump.atlas_typeController];
    [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_visitProperty:(ObjCAtlasOCProperty *)atlas_property;
{
    ObjCAtlasType *atlas_parsedType = atlas_property.type;
    if (atlas_parsedType == nil) {
        if ([atlas_property.atlas_attributeString hasPrefix:@"T"]) {
            [self.atlas_resultString appendFormat:@"// Error parsing type for property %@:\n", atlas_property.name];
            [self.atlas_resultString appendFormat:@"// Property attributes: %@\n\n", atlas_property.atlas_attributeString];
        } else {
            [self.atlas_resultString appendFormat:@"// Error: Property attributes should begin with the type ('T') attribute, property name: %@\n", atlas_property.name];
            [self.atlas_resultString appendFormat:@"// Property attributes: %@\n\n", atlas_property.atlas_attributeString];
        }
    } else {
        [self atlas__visitProperty:atlas_property atlas_parsedType:atlas_parsedType atlas_attributes:atlas_property.attributes];
    }
}

- (void)atlas_didVisitPropertiesOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    if ([atlas_aClass.properties count] > 0)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_willVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    if ([atlas_category.properties count] > 0)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_didVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    if ([atlas_category.properties count] > 0/* && [aCategory hasMethods]*/)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_willVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    if ([atlas_protocol.properties count] > 0)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_didVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    if ([atlas_protocol.properties count] > 0 /*&& [aProtocol hasMethods]*/)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_visitRemainingProperties:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
    NSArray *atlas_remaining = atlas_propertyState.atlas_remainingProperties;

    if ([atlas_remaining count] > 0) {
        [self.atlas_resultString appendString:@"\n"];
        [self.atlas_resultString appendFormat:@"// Remaining properties\n"];
        //NSLog(@"Warning: remaining undeclared property count: %u", [remaining count]);
        //NSLog(@"remaining: %@", remaining);
        for (ObjCAtlasOCProperty *atlas_property in atlas_remaining)
            [self atlas_visitProperty:atlas_property];
    }
}

#pragma mark -

@synthesize atlas_resultString = atlas__resultString;

- (void)atlas_writeResultToStandardOutput;
{
    NSData *atlas_data = [self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:atlas_data];
}

- (void)atlas__visitProperty:(ObjCAtlasOCProperty *)atlas_property atlas_parsedType:(ObjCAtlasType *)atlas_parsedType atlas_attributes:(NSArray *)atlas_attrs;
{
    NSString *atlas_backingVar = nil;
    BOOL atlas_isWeak = NO;
    BOOL atlas_isDynamic = NO;
    
    NSMutableArray *atlas_alist = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_unknownAttrs = [[NSMutableArray alloc] init];
    
    // objc_v2_encode_prop_attr() in gcc/objc/objc-act.c
    
    for (NSString *atlas_attr in atlas_attrs) {
        if ([atlas_attr hasPrefix:@"T"]) {
            if (atlas_debug) NSLog(@"Warning: Property attribute 'T' should occur only occur at the beginning");
        } else if ([atlas_attr hasPrefix:@"R"]) {
            [atlas_alist addObject:@"readonly"];
        } else if ([atlas_attr hasPrefix:@"C"]) {
            [atlas_alist addObject:@"copy"];
        } else if ([atlas_attr hasPrefix:@"&"]) {
            [atlas_alist addObject:@"retain"];
        } else if ([atlas_attr hasPrefix:@"G"]) {
            [atlas_alist addObject:[NSString stringWithFormat:@"getter=%@", [atlas_attr substringFromIndex:1]]];
        } else if ([atlas_attr hasPrefix:@"S"]) {
            [atlas_alist addObject:[NSString stringWithFormat:@"setter=%@", [atlas_attr substringFromIndex:1]]];
        } else if ([atlas_attr hasPrefix:@"V"]) {
            atlas_backingVar = [atlas_attr substringFromIndex:1];
        } else if ([atlas_attr hasPrefix:@"N"]) {
            [atlas_alist addObject:@"nonatomic"];
        } else if ([atlas_attr hasPrefix:@"W"]) {
            // @property(assign) __weak NSObject *prop;
            // Only appears with GC.
            atlas_isWeak = YES;
        } else if ([atlas_attr hasPrefix:@"P"]) {
            // @property(assign) __strong NSObject *prop;
            // Only appears with GC.
            // This is the default.
            atlas_isWeak = NO;
        } else if ([atlas_attr hasPrefix:@"D"]) {
            // Dynamic property.  Implementation supplied at runtime.
            // @property int prop; // @dynamic prop;
            atlas_isDynamic = YES;
        } else {
            if (atlas_debug) NSLog(@"Warning: Unknown property attribute '%@'", atlas_attr);
            [atlas_unknownAttrs addObject:atlas_attr];
        }
    }
    
    if ([atlas_alist count] > 0) {
        [self.atlas_resultString appendFormat:@"@property(%@) ", [atlas_alist componentsJoinedByString:@", "]];
    } else {
        [self.atlas_resultString appendString:@"@property "];
    }
    
    if (atlas_isWeak)
        [self.atlas_resultString appendString:@"__weak "];
    
    NSString *atlas_formattedString = [self.atlas_classDump.atlas_typeController.atlas_propertyTypeFormatter atlas_formatVariable:atlas_property.name atlas_type:atlas_parsedType];
    [self.atlas_resultString appendFormat:@"%@;", atlas_formattedString];
    
    if (atlas_isDynamic) {
        [self.atlas_resultString appendFormat:@" // @dynamic %@;", atlas_property.name];
    } else if (atlas_backingVar != nil) {
        if ([atlas_backingVar isEqualToString:atlas_property.name]) {
            [self.atlas_resultString appendFormat:@" // @synthesize %@;", atlas_property.name];
        } else {
            [self.atlas_resultString appendFormat:@" // @synthesize %@=%@;", atlas_property.name, atlas_backingVar];
        }
    }
    
    [self.atlas_resultString appendString:@"\n"];
    if ([atlas_unknownAttrs count] > 0) {
        [self.atlas_resultString appendFormat:@"// Preceding property had unknown attributes: %@\n", [atlas_unknownAttrs componentsJoinedByString:@","]];
        if ([atlas_property.atlas_attributeString length] > 80) {
            [self.atlas_resultString appendFormat:@"// Original attribute string (following type): %@\n\n", atlas_property.atlas_attributeStringAfterType];
        } else {
            [self.atlas_resultString appendFormat:@"// Original attribute string: %@\n\n", atlas_property.atlas_attributeString];
        }
    }
}

@end
