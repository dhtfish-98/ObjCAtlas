// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFile.h" // For CDArch

#define atlas_CLASS_DUMP_BASE_VERSION "3.5 (64 bit)"

#ifdef DEBUG
#define atlas_CLASS_DUMP_VERSION atlas_CLASS_DUMP_BASE_VERSION " (Debug version compiled " __DATE__ " " __TIME__ ")"
#else
#define atlas_CLASS_DUMP_VERSION atlas_CLASS_DUMP_BASE_VERSION
#endif

@class ObjCAtlasFile;
@class ObjCAtlasTypeController;
@class ObjCAtlasVisitor;
@class ObjCAtlasSearchPathState;

@interface ObjCAtlasClassDump : NSObject

@property (readonly) ObjCAtlasSearchPathState *atlas_searchPathState;

@property (assign) BOOL atlas_shouldProcessRecursively;
@property (assign) BOOL atlas_shouldSortClasses;
@property (assign) BOOL atlas_shouldSortClassesByInheritance;
@property (assign) BOOL atlas_shouldSortMethods;
@property (assign) BOOL atlas_shouldShowIvarOffsets;
@property (assign) BOOL atlas_shouldShowMethodAddresses;
@property (assign) BOOL atlas_shouldShowHeader;

@property (strong) NSRegularExpression *regularExpression;
- (BOOL)atlas_shouldShowName:(NSString *)atlas_name;

@property (strong) NSString *atlas_sdkRoot;

@property (readonly) NSArray *atlas_machOFiles;
@property (readonly) NSArray *atlas_objcProcessors;

@property (assign) atlas_CDArch atlas_targetArch;

@property (nonatomic, readonly) BOOL atlas_containsObjectiveCData;
@property (nonatomic, readonly) BOOL atlas_hasEncryptedFiles;
@property (nonatomic, readonly) BOOL atlas_hasObjectiveCRuntimeInfo;

@property (readonly) ObjCAtlasTypeController *atlas_typeController;

- (BOOL)atlas_loadFile:(ObjCAtlasFile *)atlas_file atlas_error:(NSError **)atlas_error;
- (void)atlas_processObjectiveCData;

- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;

- (void)atlas_appendHeaderToString:(NSMutableString *)atlas_resultString;

- (void)atlas_registerTypes;

- (void)atlas_showHeader;
- (void)atlas_showLoadCommands;

@end

extern NSString *atlas_CDErrorDomain_ClassDump;
extern NSString *atlas_CDErrorKey_Exception;


