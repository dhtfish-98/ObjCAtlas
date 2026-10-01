// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType, ObjCAtlasTypeController, ObjCAtlasTypeFormatter;

@interface ObjCAtlasStructureTable : NSObject

@property (strong) NSString *identifier;
@property (strong) NSString *atlas_anonymousBaseName;
@property (assign) BOOL atlas_shouldDebug;

@property (weak) ObjCAtlasTypeController *atlas_typeController;

// Phase 0
- (void)atlas_phase0RegisterStructure:(ObjCAtlasType *)atlas_structure atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
- (void)atlas_finishPhase0;

// Phase 1
- (void)atlas_runPhase1;
- (void)atlas_phase1RegisterStructure:(ObjCAtlasType *)atlas_structure;
- (void)atlas_finishPhase1;
@property (nonatomic, readonly) NSUInteger atlas_phase1_maxDepth;

// Phase 2
- (void)atlas_runPhase2AtDepth:(NSUInteger)atlas_depth;
- (ObjCAtlasType *)atlas_phase2ReplacementForType:(ObjCAtlasType *)atlas_type;

- (void)atlas_finishPhase2;

// Phase 3
- (void)atlas_phase2ReplacementOnPhase0;

- (void)atlas_buildPhase3Exceptions;
- (void)atlas_runPhase3;
- (void)atlas_phase3RegisterStructure:(ObjCAtlasType *)atlas_structure
                          atlas_count:(NSUInteger)atlas_referenceCount
                   atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
- (void)atlas_finishPhase3;
- (ObjCAtlasType *)atlas_phase3ReplacementForType:(ObjCAtlasType *)atlas_type;

// Other

// Called by CDTypeController prior to calling the next two methods.
- (void)atlas_generateTypedefNames;
- (void)atlas_generateMemberNames;

// Called by CDTypeController
- (void)atlas_appendNamedStructuresToString:(NSMutableString *)atlas_resultString
                            atlas_formatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter
                             atlas_markName:(NSString *)atlas_markName;

// Called by CDTypeController
- (void)atlas_appendTypedefsToString:(NSMutableString *)atlas_resultString
                     atlas_formatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter
                      atlas_markName:(NSString *)atlas_markName;

- (BOOL)atlas_shouldExpandType:(ObjCAtlasType *)atlas_type;
- (NSString *)atlas_typedefNameForType:(ObjCAtlasType *)atlas_type;

// Debugging
- (void)atlas_debugName:(NSString *)atlas_name;
- (void)atlas_debugAnon:(NSString *)atlas_str;
- (void)atlas_logPhase0Info;
- (void)atlas_logPhase2Info;
- (void)atlas_logPhase3Info;

@end
