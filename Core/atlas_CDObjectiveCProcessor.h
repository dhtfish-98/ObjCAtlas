// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasMachOFile, ObjCAtlasSection, ObjCAtlasTypeController;
@class ObjCAtlasVisitor;
@class ObjCAtlasOCClass, ObjCAtlasOCCategory;
@class ObjCAtlasProtocolUniquer;

@interface ObjCAtlasObjectiveCProcessor : NSObject

- (id)initAtlasWithMachOFile:(ObjCAtlasMachOFile *)atlas_machOFile;

@property (readonly) ObjCAtlasMachOFile *atlas_machOFile;
@property (nonatomic, readonly) BOOL atlas_hasObjectiveCData;

@property (nonatomic, readonly) ObjCAtlasSection *atlas_objcImageInfoSection;
@property (nonatomic, readonly) NSString *atlas_garbageCollectionStatus;

- (void)atlas_addClass:(ObjCAtlasOCClass *)atlas_aClass atlas_withAddress:(uint64_t)atlas_address;
- (ObjCAtlasOCClass *)atlas_classWithAddress:(uint64_t)atlas_address;

- (void)atlas_addClassesFromArray:(NSArray *)atlas_array;
- (void)atlas_addCategoriesFromArray:(NSArray *)atlas_array;

- (void)atlas_addCategory:(ObjCAtlasOCCategory *)atlas_category;

- (void)atlas_process;
- (void)atlas_loadProtocols;
- (void)atlas_loadClasses;
- (void)atlas_loadCategories;

- (void)atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;

- (NSArray *)atlas_protocolAddressListAtAddress:(uint64_t)atlas_address;

@property (readonly) ObjCAtlasProtocolUniquer *atlas_protocolUniquer;

@end
