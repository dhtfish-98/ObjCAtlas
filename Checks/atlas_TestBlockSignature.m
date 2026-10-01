// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <XCTest/XCTest.h>

#import "atlas_CDType.h"
#import "atlas_CDTypeName.h"

@interface ObjCAtlasType (UnitTests)
- (NSString *)atlas_blockSignatureString;
@end

@interface ObjCAtlasTestBlockSignature : XCTestCase
@end

@implementation ObjCAtlasTestBlockSignature

- (void)testAtlasZeroArguments;
{
	NSMutableArray *atlas_types = [NSMutableArray new];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'v']];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:nil]];
	ObjCAtlasType *atlas_blockType = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_types];
	NSString *atlas_blockSignatureString = [atlas_blockType atlas_blockSignatureString];
	XCTAssertEqualObjects(atlas_blockSignatureString, @"void (^)(void)", @"");
}

- (void)testAtlasOneArgument;
{
	NSMutableArray *atlas_types = [NSMutableArray new];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'v']];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:nil]];
	ObjCAtlasTypeName *atlas_typeName = [ObjCAtlasTypeName new];
	atlas_typeName.name = @"NSData";
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasIDType:atlas_typeName]];
	ObjCAtlasType *atlas_blockType = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_types];
	NSString *atlas_blockSignatureString = [atlas_blockType atlas_blockSignatureString];
	XCTAssertEqualObjects(atlas_blockSignatureString, @"void (^)(NSData *)", @"");
}

- (void)testAtlasTwoArguments;
{
	NSMutableArray *atlas_types = [NSMutableArray new];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'v']];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:nil]];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasIDType:nil]];
	ObjCAtlasTypeName *atlas_typeName = [ObjCAtlasTypeName new];
	atlas_typeName.name = @"NSError";
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasIDType:atlas_typeName]];
	ObjCAtlasType *atlas_blockType = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_types];
	NSString *atlas_blockSignatureString = [atlas_blockType atlas_blockSignatureString];
	XCTAssertEqualObjects(atlas_blockSignatureString, @"void (^)(id, NSError *)", @"");
}

- (void)testAtlasBlockArgument;
{
	NSMutableArray *atlas_types = [NSMutableArray new];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'v']];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:nil]];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:[atlas_types copy]]];
	ObjCAtlasType *atlas_blockType = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_types];
	NSString *atlas_blockSignatureString = [atlas_blockType atlas_blockSignatureString];
	XCTAssertEqualObjects(atlas_blockSignatureString, @"void (^)(void (^)(void))", @"");
}

- (void)testAtlasBOOLArgument;
{
	NSMutableArray *atlas_types = [NSMutableArray new];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'v']];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:nil]];
	[atlas_types addObject:[[ObjCAtlasType alloc] initAtlasSimpleType:'c']];
	ObjCAtlasType *atlas_blockType = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_types];
	NSString *atlas_blockSignatureString = [atlas_blockType atlas_blockSignatureString];
	XCTAssertEqualObjects(atlas_blockSignatureString, @"void (^)(BOOL)", @"");
}

@end
