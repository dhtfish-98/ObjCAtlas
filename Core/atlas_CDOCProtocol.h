// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasTypeController;
@class ObjCAtlasVisitor, ObjCAtlasVisitorPropertyState;
@class ObjCAtlasOCMethod, ObjCAtlasOCProperty;

@interface ObjCAtlasOCProtocol : NSObject

@property (strong) NSString *name;

@property (readonly) NSArray *atlas_protocols;
- (void)atlas_addProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
- (void)atlas_removeProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
@property (nonatomic, readonly) NSArray *atlas_protocolNames;
@property (nonatomic, readonly) NSString *atlas_protocolsString;

@property (nonatomic, readonly) NSArray *atlas_classMethods; // TODO: NSArray vs. NSMutableArray
- (void)atlas_addClassMethod:(ObjCAtlasOCMethod *)atlas_method;

@property (nonatomic, readonly) NSArray *atlas_instanceMethods;
- (void)atlas_addInstanceMethod:(ObjCAtlasOCMethod *)atlas_method;

@property (nonatomic, readonly) NSArray *atlas_optionalClassMethods;
- (void)atlas_addOptionalClassMethod:(ObjCAtlasOCMethod *)atlas_method;

@property (nonatomic, readonly) NSArray *atlas_optionalInstanceMethods;
- (void)atlas_addOptionalInstanceMethod:(ObjCAtlasOCMethod *)atlas_method;

@property (nonatomic, readonly) NSArray *properties;
- (void)atlas_addProperty:(ObjCAtlasOCProperty *)atlas_property;

@property (nonatomic, readonly) BOOL atlas_hasMethods;

- (void)atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
- (void)atlas_registerTypesFromMethods:(NSArray *)atlas_methods atlas_withObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCProtocol *)atlas_other;

- (NSString *)atlas_methodSearchContext;
- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;

- (void)atlas_visitMethods:(ObjCAtlasVisitor *)atlas_visitor atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;

- (void)atlas_mergeMethodsFromProtocol:(ObjCAtlasOCProtocol *)atlas_other;
- (void)atlas_mergePropertiesFromProtocol:(ObjCAtlasOCProtocol *)atlas_other;

@end
