// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasOCProtocol;

@interface ObjCAtlasProtocolUniquer : NSObject

// Gather
- (ObjCAtlasOCProtocol *)atlas_protocolWithAddress:(uint64_t)atlas_address;
- (void)atlas_setProtocol:(ObjCAtlasOCProtocol *)atlas_protocol atlas_withAddress:(uint64_t)atlas_address;

// Process
- (void)atlas_createUniquedProtocols;

// Results
- (NSArray *)atlas_uniqueProtocolsAtAddresses:(NSArray *)atlas_addresses;
- (NSArray *)atlas_uniqueProtocolsSortedByName;

@end
