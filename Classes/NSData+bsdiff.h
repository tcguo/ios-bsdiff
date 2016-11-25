//
//  NSData+bsdiff.h
//  bsdiff
//
//  Created by tcguo on 16/11/24.
//  Copyright © 2016年 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <bzlib.h>

@interface NSData (bsdiff)

// original c method
+ (BOOL)createDiffWithOldFile:(NSString *)oldFile newFile:(NSString *)newFile patchFile:(NSString *)patchFile;
+ (BOOL)applyWithOldFile:(NSString *)oldFile patchFile:(NSString *)patchFile newFile:(NSString *)newFile;


- (NSData *)diff:(NSData *)data;
+ (NSData *)dataWithData:(NSData *)data andPatch:(NSData *)patch;
- (NSData *)patch:(NSData *)patch;

@end
