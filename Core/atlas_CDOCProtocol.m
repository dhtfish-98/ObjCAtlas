// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCProtocol.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDOCProperty.h"
#import "atlas_CDMethodType.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDVisitorPropertyState.h"

@interface ObjCAtlasOCProtocol ()
@property (nonatomic, readonly) NSString *atlas_sortableName;
@end

#pragma mark -

@implementation ObjCAtlasOCProtocol
{
    NSString *atlas__name;
    NSMutableArray *atlas__protocols;
    NSMutableArray *atlas__classMethods;
    NSMutableArray *atlas__instanceMethods;
    NSMutableArray *atlas__optionalClassMethods;
    NSMutableArray *atlas__optionalInstanceMethods;
    NSMutableArray *atlas__properties;
    
    NSMutableSet *atlas__adoptedProtocolNames;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_protocols = atlas__protocols;
@synthesize atlas_classMethods = atlas__classMethods;
@synthesize atlas_instanceMethods = atlas__instanceMethods;
@synthesize atlas_optionalClassMethods = atlas__optionalClassMethods;
@synthesize atlas_optionalInstanceMethods = atlas__optionalInstanceMethods;
@synthesize properties = atlas__properties;

- (id)init;
{
    if ((self = [super init])) {
        atlas__name = nil;
        atlas__protocols               = [[NSMutableArray alloc] init];
        atlas__classMethods            = [[NSMutableArray alloc] init];
        atlas__instanceMethods         = [[NSMutableArray alloc] init];
        atlas__optionalClassMethods    = [[NSMutableArray alloc] init];
        atlas__optionalInstanceMethods = [[NSMutableArray alloc] init];
        atlas__properties              = [[NSMutableArray alloc] init];
        
        atlas__adoptedProtocolNames    = [[NSMutableSet alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, protocols: %ld, class methods: %ld, instance methods: %ld",
            NSStringFromClass([self class]), self, self.name, [self.atlas_protocols count], [self.atlas_classMethods count], [self.atlas_instanceMethods count]];
}

#pragma mark -

// This assumes that the protocol name doesn't change after it's been added to this.
- (void)atlas_addProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    if ([atlas__adoptedProtocolNames containsObject:atlas_protocol.name] == NO) {
        [atlas__protocols addObject:atlas_protocol];
        [atlas__adoptedProtocolNames addObject:atlas_protocol.name];
    }
}

- (void)atlas_removeProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    [atlas__adoptedProtocolNames removeObject:atlas_protocol.name];
    [atlas__protocols removeObject:atlas_protocol];
}

- (NSArray *)atlas_protocolNames;
{
    NSMutableArray *atlas_names = [[NSMutableArray alloc] init];
    [self.atlas_protocols enumerateObjectsUsingBlock:^(ObjCAtlasOCProtocol *atlas_protocol, NSUInteger atlas_index, BOOL *atlas_stop){
        if (atlas_protocol.name != nil)
            [atlas_names addObject:atlas_protocol.name];
    }];
    
    return [atlas_names copy];
}

- (NSString *)atlas_protocolsString;
{
    NSArray *atlas_names = self.atlas_protocolNames;
    if ([atlas_names count] == 0)
        return @"";

    return [atlas_names componentsJoinedByString:@", "];
}

- (void)atlas_addClassMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    [atlas__classMethods addObject:atlas_method];
}

- (void)atlas_addInstanceMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    [atlas__instanceMethods addObject:atlas_method];
}

- (void)atlas_addOptionalClassMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    [atlas__optionalClassMethods addObject:atlas_method];
}

- (void)atlas_addOptionalInstanceMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    [atlas__optionalInstanceMethods addObject:atlas_method];
}

- (void)atlas_addProperty:(ObjCAtlasOCProperty *)atlas_property;
{
    [atlas__properties addObject:atlas_property];
}

- (BOOL)atlas_hasMethods;
{
    return [self.atlas_classMethods count] > 0 || [self.atlas_instanceMethods count] > 0 || [self.atlas_optionalClassMethods count] > 0 || [self.atlas_optionalInstanceMethods count] > 0;
}

- (void)atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
{
    [self atlas_registerTypesFromMethods:self.atlas_classMethods    atlas_withObject:atlas_typeController atlas_phase:atlas_phase];
    [self atlas_registerTypesFromMethods:self.atlas_instanceMethods atlas_withObject:atlas_typeController atlas_phase:atlas_phase];

    [self atlas_registerTypesFromMethods:self.atlas_optionalClassMethods    atlas_withObject:atlas_typeController atlas_phase:atlas_phase];
    [self atlas_registerTypesFromMethods:self.atlas_optionalInstanceMethods atlas_withObject:atlas_typeController atlas_phase:atlas_phase];
}

- (void)atlas_registerTypesFromMethods:(NSArray *)atlas_methods atlas_withObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
{
    for (ObjCAtlasOCMethod *atlas_method in atlas_methods) {
        for (ObjCAtlasMethodType *atlas_methodType in atlas_method.atlas_parsedMethodTypes) {
            [atlas_methodType.type atlas_phase:atlas_phase atlas_registerTypesWithObject:atlas_typeController atlas_usedInMethod:YES];
        }
    }
}

#pragma mark - Sorting

- (NSString *)atlas_sortableName;
{
    return self.name;
}

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCProtocol *)atlas_other;
{
    return [self.atlas_sortableName compare:atlas_other.atlas_sortableName];
}

#pragma mark -

- (NSString *)atlas_methodSearchContext;
{
    NSMutableString *atlas_resultString = [NSMutableString string];

    [atlas_resultString appendFormat:@"@protocol %@", self.name];
    if ([self.atlas_protocols count] > 0)
        [atlas_resultString appendFormat:@" <%@>", self.atlas_protocolsString];

    return atlas_resultString;
}

- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;
{
    if ([atlas_visitor.atlas_classDump atlas_shouldShowName:self.name] && atlas_visitor.atlas_shouldShowProtocolSection) {
        ObjCAtlasVisitorPropertyState *atlas_propertyState = [[ObjCAtlasVisitorPropertyState alloc] initWithProperties:self.properties];
        
        [atlas_visitor atlas_willVisitProtocol:self];
        
        //[aVisitor willVisitPropertiesOfProtocol:self];
        //[self visitProperties:aVisitor];
        //[aVisitor didVisitPropertiesOfProtocol:self];
        
        [self atlas_visitMethods:atlas_visitor atlas_propertyState:atlas_propertyState];
        
        // @optional properties will generate optional instance methods, and we'll emit @property in the @optional section.
        [atlas_visitor atlas_visitRemainingProperties:atlas_propertyState];
        
        [atlas_visitor atlas_didVisitProtocol:self];
    }
}

- (void)atlas_visitMethods:(ObjCAtlasVisitor *)atlas_visitor atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
    NSArray *atlas_methods = self.atlas_classMethods;
    if (atlas_visitor.atlas_classDump.atlas_shouldSortMethods)
        atlas_methods = [atlas_methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (ObjCAtlasOCMethod *atlas_method in atlas_methods)
        [atlas_visitor atlas_visitClassMethod:atlas_method];

    atlas_methods = self.atlas_instanceMethods;
    if (atlas_visitor.atlas_classDump.atlas_shouldSortMethods)
        atlas_methods = [atlas_methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (ObjCAtlasOCMethod *atlas_method in atlas_methods)
        [atlas_visitor atlas_visitInstanceMethod:atlas_method atlas_propertyState:atlas_propertyState];

    if ([self.atlas_optionalClassMethods count] > 0 || [self.atlas_optionalInstanceMethods count] > 0) {
        [atlas_visitor atlas_willVisitOptionalMethods];

        atlas_methods = self.atlas_optionalClassMethods;
        if (atlas_visitor.atlas_classDump.atlas_shouldSortMethods)
            atlas_methods = [atlas_methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (ObjCAtlasOCMethod *atlas_method in atlas_methods)
            [atlas_visitor atlas_visitClassMethod:atlas_method];

        atlas_methods = self.atlas_optionalInstanceMethods;
        if (atlas_visitor.atlas_classDump.atlas_shouldSortMethods)
            atlas_methods = [atlas_methods sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
        for (ObjCAtlasOCMethod *atlas_method in atlas_methods)
            [atlas_visitor atlas_visitInstanceMethod:atlas_method atlas_propertyState:atlas_propertyState];

        [atlas_visitor atlas_didVisitOptionalMethods];
    }
}

#if 0
- (void)visitProperties:(CDVisitor *)visitor;
{
    NSArray *array = properties;
    if (visitor.classDump.shouldSortMethods)
        array = [array sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
    for (CDOCProperty *property in array)
        [visitor visitProperty:property];
}
#endif

#pragma mark -

- (void)atlas_mergeMethodsFromProtocol:(ObjCAtlasOCProtocol *)atlas_other;
{
    NSMutableDictionary *atlas_instanceMethodsByName         = [NSMutableDictionary dictionary];
    NSMutableDictionary *atlas_optionalInstanceMethodsByName = [NSMutableDictionary dictionary];
    NSMutableDictionary *atlas_classMethodsByName            = [NSMutableDictionary dictionary];
    NSMutableDictionary *atlas_optionalClassMethodsByName    = [NSMutableDictionary dictionary];
    
    for (ObjCAtlasOCMethod *atlas_method in atlas__instanceMethods)
        atlas_instanceMethodsByName[atlas_method.name] = atlas_method;
    
    for (ObjCAtlasOCMethod *atlas_method in atlas__optionalInstanceMethods)
        atlas_optionalInstanceMethodsByName[atlas_method.name] = atlas_method;
    
    for (ObjCAtlasOCMethod *atlas_method in atlas__classMethods)
        atlas_classMethodsByName[atlas_method.name] = atlas_method;
    
    for (ObjCAtlasOCMethod *atlas_method in atlas__optionalClassMethods)
        atlas_optionalClassMethodsByName[atlas_method.name] = atlas_method;
    
    // Instance methods
    for (ObjCAtlasOCMethod *atlas_method in atlas_other.atlas_instanceMethods) {
        ObjCAtlasOCMethod *atlas_m2 = atlas_instanceMethodsByName[atlas_method.name];
        if (atlas_m2 == nil) {
            // Add if it is not an optional instance method.
            if (atlas_optionalInstanceMethodsByName[atlas_method.name] == nil) {
                [self atlas_addInstanceMethod:atlas_method];
                atlas_instanceMethodsByName[atlas_method.name] = atlas_method;
            }
        }
    }
    
    for (ObjCAtlasOCMethod *atlas_method in atlas_other.atlas_optionalInstanceMethods) {
        ObjCAtlasOCMethod *atlas_m2 = atlas_optionalInstanceMethodsByName[atlas_method.name];
        if (atlas_m2 == nil) {
            atlas_m2 = atlas_instanceMethodsByName[atlas_method.name];
            if (atlas_m2 == nil) {
                [self atlas_addOptionalInstanceMethod:atlas_method];
                atlas_optionalInstanceMethodsByName[atlas_method.name] = atlas_method;
            } else {
                // Move to the optional instance methods.
                [self atlas_addOptionalInstanceMethod:atlas_m2];
                [atlas__instanceMethods removeObject:atlas_m2];
                atlas_optionalInstanceMethodsByName[atlas_m2.name] = atlas_m2;
                [atlas_instanceMethodsByName removeObjectForKey:atlas_m2.name];
            }
        }
    }

    // Class methods
    for (ObjCAtlasOCMethod *atlas_method in atlas_other.atlas_classMethods) {
        ObjCAtlasOCMethod *atlas_m2 = atlas_classMethodsByName[atlas_method.name];
        if (atlas_m2 == nil) {
            // Add if it is not an optional class method.
            if (atlas_optionalClassMethodsByName[atlas_method.name] == nil) {
                [self atlas_addClassMethod:atlas_method];
                atlas_classMethodsByName[atlas_method.name] = atlas_method;
            }
        }
    }
    
    for (ObjCAtlasOCMethod *atlas_method in atlas_other.atlas_optionalClassMethods) {
        ObjCAtlasOCMethod *atlas_m2 = atlas_optionalClassMethodsByName[atlas_method.name];
        if (atlas_m2 == nil) {
            atlas_m2 = atlas_classMethodsByName[atlas_method.name];
            if (atlas_m2 == nil) {
                [self atlas_addOptionalClassMethod:atlas_method];
                atlas_optionalClassMethodsByName[atlas_method.name] = atlas_method;
            } else {
                // Move to the optional class methods.
                [self atlas_addOptionalClassMethod:atlas_m2];
                [atlas__classMethods removeObject:atlas_m2];
                atlas_optionalClassMethodsByName[atlas_m2.name] = atlas_m2;
                [atlas_classMethodsByName removeObjectForKey:atlas_m2.name];
            }
        }
    }
}

- (void)atlas_mergePropertiesFromProtocol:(ObjCAtlasOCProtocol *)atlas_other;
{
    NSMutableDictionary *atlas_propertiesByName = [NSMutableDictionary dictionary];

    for (ObjCAtlasOCProperty *atlas_property in atlas__properties)
        atlas_propertiesByName[atlas_property.name] = atlas_property;
    
    for (ObjCAtlasOCProperty *atlas_property in atlas_other.properties) {
        ObjCAtlasOCProperty *atlas_p2 = atlas_propertiesByName[atlas_property.name];
        if (atlas_p2 == nil) {
            [self atlas_addProperty:atlas_property];
            atlas_propertiesByName[atlas_property.name] = atlas_property;
        }
    }
}

@end
