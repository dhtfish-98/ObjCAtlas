// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@protocol ObjCAtlasTypeControllerDelegate;

@class ObjCAtlasClassDump, ObjCAtlasType, ObjCAtlasTypeFormatter;

@interface ObjCAtlasTypeController : NSObject

- (id)initAtlasWithClassDump:(ObjCAtlasClassDump *)atlas_classDump;

@property (weak) id <ObjCAtlasTypeControllerDelegate> delegate;

@property (readonly) ObjCAtlasTypeFormatter *atlas_ivarTypeFormatter;
@property (readonly) ObjCAtlasTypeFormatter *atlas_methodTypeFormatter;
@property (readonly) ObjCAtlasTypeFormatter *atlas_propertyTypeFormatter;
@property (readonly) ObjCAtlasTypeFormatter *atlas_structDeclarationTypeFormatter;

@property (nonatomic, readonly) BOOL atlas_shouldShowIvarOffsets;
@property (nonatomic, readonly) BOOL atlas_shouldShowMethodAddresses;
@property (nonatomic, readonly) BOOL atlas_targetArchUses64BitABI;

@property (nonatomic, assign) BOOL atlas_hasUnknownFunctionPointers;
@property (nonatomic, assign) BOOL atlas_hasUnknownBlocks;

- (ObjCAtlasType *)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_replacementForType:(ObjCAtlasType *)atlas_type;
- (NSString *)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_typedefNameForStructure:(ObjCAtlasType *)atlas_structureType atlas_level:(NSUInteger)atlas_level;
- (void)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_didReferenceClassName:(NSString *)atlas_name;
- (void)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_didReferenceProtocolNames:(NSArray *)atlas_names;

- (void)atlas_appendStructuresToString:(NSMutableString *)atlas_resultString;

// Phase 0 - initiated from -[CDClassDump registerTypes]
- (void)atlas_phase0RegisterStructure:(ObjCAtlasType *)atlas_structure atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;

// Run phase 1+
- (void)atlas_workSomeMagic;

// Phase 1
- (void)atlas_phase1RegisterStructure:(ObjCAtlasType *)atlas_structure;

- (void)atlas_endPhase:(NSUInteger)atlas_phase;

- (ObjCAtlasType *)atlas_phase2ReplacementForType:(ObjCAtlasType *)atlas_type;

- (void)atlas_phase3RegisterStructure:(ObjCAtlasType *)atlas_structure;
- (ObjCAtlasType *)atlas_phase3ReplacementForType:(ObjCAtlasType *)atlas_type;

- (BOOL)atlas_shouldShowName:(NSString *)atlas_name;
- (BOOL)atlas_shouldExpandType:(ObjCAtlasType *)atlas_type;
- (NSString *)atlas_typedefNameForType:(ObjCAtlasType *)atlas_type;

@end

#pragma mark -

@protocol ObjCAtlasTypeControllerDelegate <NSObject>
@optional
- (void)atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController atlas_didReferenceClassName:(NSString *)atlas_name;
- (void)atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController atlas_didReferenceProtocolNames:(NSArray *)atlas_names;
@end
