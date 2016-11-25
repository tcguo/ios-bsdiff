//
//  NSData+bsdiff.m
//  bsdiff
//
//  Created by tcguo on 16/11/24.
//  Copyright © 2016年 baidu. All rights reserved.
//

#import "NSData+bsdiff.h"
#import "zlib.h"
#import "bsdiff.h"

#define CORRUPT_EXCEPTION [NSException exceptionWithName:@"bsdiff" reason:@"Corrupt patch" userInfo:nil]

@implementation NSData (bsdiff)

static off_t ff_offtin(u_char *buf) {
    off_t y;
    
    y=buf[7]&0x7F;
    y=y*256;y+=buf[6];
    y=y*256;y+=buf[5];
    y=y*256;y+=buf[4];
    y=y*256;y+=buf[3];
    y=y*256;y+=buf[2];
    y=y*256;y+=buf[1];
    y=y*256;y+=buf[0];
    
    if(buf[7]&0x80) y=-y;
    
    return y;
}

+ (BOOL)createDiffWithOldFile:(NSString *)oldFile newFile:(NSString *)newFile patchFile:(NSString *)patchFile {
    NSParameterAssert(oldFile);
    NSParameterAssert(newFile);
    NSParameterAssert(patchFile);
    
    int isSuccess =  ff_diff([oldFile UTF8String], [newFile UTF8String], [patchFile UTF8String]);
    return !isSuccess;
}

+ (BOOL)applyWithOldFile:(NSString *)oldFile patchFile:(NSString *)patchFile newFile:(NSString *)newFile {
    NSParameterAssert(oldFile);
    NSParameterAssert(newFile);
    NSParameterAssert(patchFile);
    
    int isSuccess =  ff_patch([oldFile UTF8String], [patchFile UTF8String], [newFile UTF8String]);
    return !isSuccess;
}


- (NSData *)diff:(NSData *)data {
    // TODO:
    return nil;
}

+ (NSData *)dataWithData:(NSData *)data andPatch:(NSData *)patch {
    return [data patch:patch];
}

- (NSData *)patch:(NSData *)patch {
    NSData * (^io_open)(NSData *data);
    ssize_t oldsize, newsize, cstart, dstart, estart;
    ssize_t bzctrllen, bzdatalen;
    u_char *header;
    off_t oldpos,newpos;
    off_t ctrl[3];
    long long lenread;
    off_t i;
    
    NSData *headerData = [patch subdataWithRange:NSMakeRange(0, 32)];
    NSData *headerVersion = [headerData subdataWithRange:NSMakeRange(0, 8)];
    if ([headerVersion isEqualToData:[@"BSDIFF40" dataUsingEncoding:NSASCIIStringEncoding]]) {
        io_open = ^(NSData *data) {
            int bzret;
            bz_stream stream = { 0 };
            stream.next_in = (char*)[data bytes];
            stream.avail_in = (u_int)[data length];
            
            const int buffer_size = 10000;
            NSMutableData * buffer = [NSMutableData dataWithLength:buffer_size];
            stream.next_out = [buffer mutableBytes];
            stream.avail_out = buffer_size;
            
            NSMutableData * decompressed = [NSMutableData data];
            
            BZ2_bzDecompressInit(&stream, 0, NO);
            @try {
                do {
                    bzret = BZ2_bzDecompress(&stream);
                    if (bzret != BZ_OK && bzret != BZ_STREAM_END)
                        @throw [NSException exceptionWithName:@"bzip2" reason:@"BZ2_bzDecompress failed" userInfo:nil];
                    
                    [decompressed appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
                    stream.next_out = [buffer mutableBytes];
                    stream.avail_out = buffer_size;
                } while(bzret != BZ_STREAM_END);
            }
            @finally {
                BZ2_bzDecompressEnd(&stream);
            }
            
            return decompressed;
        };
    } else if ([headerVersion isEqualToData:[@"BSDIFN40" dataUsingEncoding:NSASCIIStringEncoding]]) {
        io_open = ^(NSData *data) {
            return data;
        };
    } else {
        @throw CORRUPT_EXCEPTION;
    }
    header = (u_char *)[headerData bytes];
    bzctrllen = ff_offtin(header + 8);
    bzdatalen = ff_offtin(header + 16);
    newsize = ff_offtin(header + 24);
    
    if ((bzctrllen < 0) || (bzdatalen < 0) || (newsize < 0)) {
        @throw CORRUPT_EXCEPTION;
    }
    
    NSData *cstream = io_open([patch subdataWithRange:NSMakeRange(32, [patch length]-32)]);
    NSData *dstream = io_open([patch subdataWithRange:NSMakeRange(32 + bzctrllen, [patch length]-(32 + bzctrllen))]);
    NSData *estream = io_open([patch subdataWithRange:NSMakeRange(32 + bzctrllen + bzdatalen, [patch length]-(32 + bzctrllen + bzdatalen))]);
    
    oldsize = [self length];
    NSData *old = [NSData dataWithData:self];
    NSMutableData *new = [NSMutableData dataWithCapacity:newsize + 1];
    
    oldpos = 0; newpos = 0;
    cstart = 0; dstart = 0; estart = 0;
    while (newpos < newsize) {
        for (i = 0; i <= 2; i++) {
            NSData *c = [cstream subdataWithRange:NSMakeRange(cstart, 8)];
            lenread = [c length];
            if (lenread < 8) {
                @throw CORRUPT_EXCEPTION;
            }
            ctrl[i] = ff_offtin((u_char *)[c bytes]);
            cstart += 8;
        }
        
        if (newpos + ctrl[0] > newsize) {
            @throw CORRUPT_EXCEPTION;
        }
        
        NSData *d = [dstream subdataWithRange:NSMakeRange(dstart, ctrl[0])];
        lenread = [d length];
        [new appendData:d];
        if (lenread < ctrl[0]) {
            @throw CORRUPT_EXCEPTION;
        }
        dstart += ctrl[0];
        
        u_char *new_bytes = [new mutableBytes];
        u_char *old_bytes = (u_char *)[old bytes];
        for (i = 0; i < ctrl[0]; i++) {
            if ((oldpos + i >= 0) && (oldpos + i < oldsize)) {
                new_bytes[newpos + i] += old_bytes[oldpos + i];
            }
        }
        
        newpos += ctrl[0];
        oldpos += ctrl[0];
        
        if (newpos + ctrl[1] > newsize) {
            @throw CORRUPT_EXCEPTION;
        }
        
        NSData *e = [estream subdataWithRange:NSMakeRange(estart, ctrl[1])];
        lenread = [e length];
        [new appendData:e];
        if (lenread < ctrl[1]) {
            @throw CORRUPT_EXCEPTION;
        }
        estart += ctrl[1];
        
        newpos += ctrl[1];
        oldpos += ctrl[2];
    }
    
    return [NSData dataWithData:new];
}

@end
