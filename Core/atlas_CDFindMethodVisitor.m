// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFindMethodVisitor.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDObjectiveC1Processor.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDOCProtocol.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDOCMethod.h"
//#import "atlas_CDTypeController.h"

@interface ObjCAtlasFindMethodVisitor ()
@property (readonly) NSMutableString *atlas_resultString;
@property (nonatomic, strong) ObjCAtlasOCProtocol *atlas_context;
@property (assign) BOOL atlas_hasShownContext;
@end

#pragma mark -

@implementation ObjCAtlasFindMethodVisitor
{
    NSString *atlas__searchString;
    NSMutableString *atlas__resultString;
    ObjCAtlasOCProtocol *atlas__context;
    BOOL atlas__hasShownContext;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_searchString = atlas__searchString;
@synthesize atlas_resultString = atlas__resultString;
@synthesize atlas_context = atlas__context;
@synthesize atlas_hasShownContext = atlas__hasShownContext;

- (id)init;
{
    if ((self = [super init])) {
        atlas__searchString = nil;
        atlas__resultString = [[NSMutableString alloc] init];
        atlas__context = nil;
        atlas__hasShownContext = NO;
    }

    return self;
}

#pragma mark -

- (void)atlas_willBeginVisiting;
{
    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    if (self.atlas_classDump.atlas_hasObjectiveCRuntimeInfo) {
        //[[classDump typeController] appendStructuresToString:resultString symbolReferences:nil];
        //[resultString appendString:@"// [structures go here]\n"];
    }
}

- (void)atlas_visitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
    if (!self.atlas_classDump.atlas_hasObjectiveCRuntimeInfo) {
        [self.atlas_resultString appendString:@"//\n"];
        [self.atlas_resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [self.atlas_resultString appendString:@"//\n"];
    }
}

- (void)atlas_didEndVisiting;
{
    [self atlas_writeResultToStandardOutput];
}

- (void)atlas_writeResultToStandardOutput;
{
    NSData *atlas_data = [self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:atlas_data];
}

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    [self setAtlas_context:atlas_protocol];
}

- (void)atlas_didVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    if (self.atlas_hasShownContext)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    [self setAtlas_context:atlas_aClass];
}

- (void)atlas_didVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    if (self.atlas_hasShownContext)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_willVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_didVisitIvarsOfClass:(ObjCAtlasOCClass *)atlas_aClass;
{
}

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    [self setAtlas_context:atlas_category];
}

- (void)atlas_didVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    if (self.atlas_hasShownContext)
        [self.atlas_resultString appendString:@"\n"];
}

- (void)atlas_visitClassMethod:(ObjCAtlasOCMethod *)atlas_method;
{
    NSRange atlas_range = [atlas_method.name rangeOfString:self.atlas_searchString];
    if (atlas_range.length > 0) {
        [self atlas_showContextIfNecessary];

        [self.atlas_resultString appendString:@"+ "];
        [atlas_method atlas_appendToString:self.atlas_resultString atlas_typeController:self.atlas_classDump.atlas_typeController];
        [self.atlas_resultString appendString:@"\n"];
    }
}

- (void)atlas_visitInstanceMethod:(ObjCAtlasOCMethod *)atlas_method atlas_propertyState:(ObjCAtlasVisitorPropertyState *)atlas_propertyState;
{
    NSRange atlas_range = [atlas_method.name rangeOfString:self.atlas_searchString];
    if (atlas_range.length > 0) {
        [self atlas_showContextIfNecessary];

        [self.atlas_resultString appendString:@"- "];
        [atlas_method atlas_appendToString:self.atlas_resultString atlas_typeController:self.atlas_classDump.atlas_typeController];
        [self.atlas_resultString appendString:@"\n"];
    }
}

- (void)atlas_visitIvar:(ObjCAtlasOCInstanceVariable *)atlas_ivar;
{
}

#pragma mark -

- (void)setAtlas_context:(ObjCAtlasOCProtocol *)atlas_newContext;
{
    if (atlas_newContext != atlas__context) {
        atlas__context = atlas_newContext;
        self.atlas_hasShownContext = NO;
    }
}

- (void)atlas_showContextIfNecessary;
{
    if (self.atlas_hasShownContext == NO) {
        [self.atlas_resultString appendString:[self.atlas_context atlas_methodSearchContext]];
        [self.atlas_resultString appendString:@"\n"];
        self.atlas_hasShownContext = YES;
    }
}

@end
