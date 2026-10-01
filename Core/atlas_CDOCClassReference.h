// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <Foundation/Foundation.h>

@class ObjCAtlasOCClass, ObjCAtlasSymbol;

/*!
 * CDOCClassReference acts as a proxy object to a class that may be external. It can thus be repesented
 * as one of: a \c CDOCClass object (for internal classes), a \c CDSymbol object (for external classes),
 * or an \c NSString of the class name (for ObjC1 compatibility). The class name can then be inferred from
 * any of these representations.
 */
@interface ObjCAtlasOCClassReference : NSObject

@property (strong) ObjCAtlasOCClass *atlas_classObject;
@property (strong) ObjCAtlasSymbol *atlas_classSymbol;
@property (nonatomic, copy) NSString *className; // inferred from classObject / classSymbol if not set directly
@property (nonatomic, readonly, getter=atlas_isExternalClass) BOOL atlas_externalClass;

- (instancetype)initAtlasWithClassObject:(ObjCAtlasOCClass *)atlas_classObject;
- (instancetype)initAtlasWithClassSymbol:(ObjCAtlasSymbol *)atlas_symbol;
- (instancetype)initAtlasWithClassName:(NSString *)atlas_className;

@end
