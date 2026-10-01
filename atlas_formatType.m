// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#import "atlas_CDClassDump.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDBalanceFormatter.h"
#import "atlas_CDOCInstanceVariable.h"

void atlas_print_usage(void)
{
    fprintf(stderr,
            "formatType %s\n"
            "Usage: formatType [options] <input file>\n"
            "\n"
            "  where options are:\n"
            "        -m        format method (default is to format ivars)\n"
            ,
            atlas_CLASS_DUMP_VERSION
       );
}

typedef enum : NSUInteger {
    atlas_CDFormat_Ivar    = 0,
    atlas_CDFormat_Method  = 1,
    atlas_CDFormat_Balance = 2,
} atlas_CDFormatType;

int main(int atlas_argc, char *atlas_argv[])
{
    @autoreleasepool {
        ObjCAtlasTypeFormatter *atlas_ivarTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas_ivarTypeFormatter.atlas_shouldExpand = YES;
        atlas_ivarTypeFormatter.atlas_shouldAutoExpand = YES;
        atlas_ivarTypeFormatter.atlas_baseLevel = 0;

        ObjCAtlasTypeFormatter *atlas_methodTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas_methodTypeFormatter.atlas_shouldExpand = NO;
        atlas_methodTypeFormatter.atlas_shouldAutoExpand = NO;
        atlas_methodTypeFormatter.atlas_baseLevel = 0;

        struct option atlas_longopts[] = {
            { "balance", no_argument, NULL, 'b' },
            { "method", no_argument, NULL, 'm' },
            { NULL, 0, NULL, 0 },
        };

        if (atlas_argc == 1) {
            atlas_print_usage();
            exit(0);
        }

        NSUInteger atlas_formatType = atlas_CDFormat_Ivar;
        
        BOOL atlas_errorFlag = NO;
        int atlas_ch;

        while ( (atlas_ch = getopt_long(atlas_argc, atlas_argv, "bm", atlas_longopts, NULL)) != -1) {
            switch (atlas_ch) {
                case 'b':
                    atlas_formatType = atlas_CDFormat_Balance;
                    break;
                    
                case 'm':
                    atlas_formatType = atlas_CDFormat_Method;
                    break;
                    
                case '?':
                default:
                    atlas_errorFlag = YES;
                    break;
            }
        }

        if (atlas_errorFlag) {
            atlas_print_usage();
            exit(2);
        }

        switch (atlas_formatType) {
            case atlas_CDFormat_Ivar:    printf("Format as ivars\n"); break;
            case atlas_CDFormat_Method:  printf("Format as methods\n"); break;
            case atlas_CDFormat_Balance: printf("Format as balance\n"); break;
        }

        for (NSUInteger atlas_index = optind; atlas_index < (NSUInteger)atlas_argc; atlas_index++) {

            NSString *atlas_arg = [NSString atlas_stringWithFileSystemRepresentation:atlas_argv[atlas_index]];
            printf("======================================================================\n");
            printf("File: %s\n", atlas_argv[atlas_index]);

            NSError *atlas_error = nil;
            NSString *atlas_input = [[NSString alloc] initWithContentsOfFile:atlas_arg encoding:NSUTF8StringEncoding error:&atlas_error];
            if (atlas_error != nil) {
                NSLog(@"input error: %@", atlas_error);
                NSLog(@"localizedFailureReason: %@", [atlas_error localizedFailureReason]);
            }

            NSArray *atlas_lines = [atlas_input componentsSeparatedByString:@"\n"];

            NSString *atlas_name = nil;
            NSString *atlas_type = nil;
            for (NSString *atlas_line in atlas_lines) {
                if ([atlas_line hasPrefix:@"//"] || [atlas_line length] == 0) {
                    printf("%s\n", [atlas_line UTF8String]);
                    continue;
                }

                if (atlas_name == nil) {
                    atlas_name = atlas_line;
                } else if (atlas_type == nil) {
                    NSString *atlas_str;

                    atlas_type = atlas_line;

                    switch (atlas_formatType) {
                        case atlas_CDFormat_Ivar: {
                            ObjCAtlasOCInstanceVariable *atlas_var = [[ObjCAtlasOCInstanceVariable alloc] initAtlasWithName:atlas_name atlas_typeString:atlas_type atlas_offset:0];
                            atlas_str = [atlas_ivarTypeFormatter atlas_formatVariable:atlas_name atlas_type:atlas_var.type];
                            break;
                        }
                            
                        case atlas_CDFormat_Method:
                            atlas_str = [atlas_methodTypeFormatter atlas_formatMethodName:atlas_name atlas_typeString:atlas_type];
                            break;
                            
                        case atlas_CDFormat_Balance: {
                            ObjCAtlasBalanceFormatter *atlas_balance = [[ObjCAtlasBalanceFormatter alloc] initWithString:atlas_type];
                            atlas_str = [atlas_balance format];
                        }
                    }
                    if (atlas_str == nil)
                        printf("Error formatting type.\n");
                    else
                        printf("%s\n", [atlas_str UTF8String]);
                    printf("----------------------------------------------------------------------\n");

                    atlas_name = atlas_type = nil;
                }
            }
        }
    }

    return 0;
}
