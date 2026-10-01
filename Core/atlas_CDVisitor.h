// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasClassDump, ObjCAtlasObjectiveCProcessor, ObjCAtlasOCProtocol, ObjCAtlasOCMethod, ObjCAtlasOCInstanceVariable, ObjCAtlasOCClass, ObjCAtlasOCCategory, ObjCAtlasOCProperty;
@class ObjCAtlasVisitorPropertyState;

@interface ObjCAtlasVisitor : NSObject

@property (strong) ObjCAtlasClassDump *atlas_classDump;

- (void)atlas_willBeginVisiting;
- (void)atlas_didEndVisiting;

- (void)atlas_willVisitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
- (void)atlas_visitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
- (void)atlas_didVisitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
- (void)atlas_didVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;

- (void)atlas_willVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
- (void)atlas_didVisitPropertiesOfProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;

- (void)atlas_willVisitOptionalMethods;
- (void)atlas_didVisitOptionalMethods;

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
- (void)atlas_didVisitClass:(ObjCAtlasOCClass *)atlas_aClass;

- (void)atlas_willVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
- (void)atlas_didVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;

- (void)atlas_willVisitPropertiesOfClass:(ObjCAtlasOCClass *)atlas_aClass;
- (void)atlas_didVisitPropertiesOfClass:(ObjCAtlasOCClass *)atlas_aClass;

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
- (void)atlas_didVisitCategory:(ObjCAtlasOCCategory *)atlas_category;

- (void)atlas_willVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;
- (void)atlas_didVisitPropertiesOfCategory:(ObjCAtlasOCCategory *)atlas_category;

- (void)atlas_visitClassMethod:(ObjCAtlasOCMethod *)atlas_method;
- (void)atlas_visitInstanceMethod:(ObjCAtlasOCMethod *)atlas_method atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
- (void)atlas_visitIvar:(ObjCAtlasOCInstanceVariable *)atlas_ivar;
- (void)atlas_visitProperty:(ObjCAtlasOCProperty *)atlas_property;

- (void)atlas_visitRemainingProperties:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;

@property (assign) BOOL atlas_shouldShowStructureSection;
@property (assign) BOOL atlas_shouldShowProtocolSection;

@end
