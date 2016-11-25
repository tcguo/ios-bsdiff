//
//  ViewController.m
//  bsdiff
//
//  Created by tcguo on 16/11/24.
//  Copyright © 2016年 baidu. All rights reserved.
//

#import "ViewController.h"
#import "NSData+bsdiff.h"
//#import "bdiff.h"

@interface ViewController ()

@property (nonatomic, copy) NSString *dirPath;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self createDir];
    NSString *oldString = @"i am";
    NSString *newString = @"i am a progrommer";
    [oldString writeToFile:[NSString stringWithFormat:@"%@/old.data", self.dirPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [newString writeToFile:[NSString stringWithFormat:@"%@/new.data", self.dirPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSData *oldData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/old.data", self.dirPath]];
    NSData *newData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/new.data", self.dirPath]];
    
    NSString *oldPath = [NSString stringWithFormat:@"%@/old.data", self.dirPath];
    NSString *newPath = [NSString stringWithFormat:@"%@/new.data", self.dirPath];
    NSString *patchPath = [NSString stringWithFormat:@"%@/patch.data", self.dirPath];

    BOOL isSuccess = [NSData createDiffWithOldFile:oldPath newFile:newPath patchFile:patchPath];
    
    NSData *patchData = [NSData dataWithContentsOfFile:patchPath];
    NSData *newFileData = [NSData dataWithData:oldData andPatch:patchData];
    [newFileData writeToFile:[NSString stringWithFormat:@"%@/newfile.data", self.dirPath] atomically:YES];
}

- (void)createDir {
    BOOL isDir = YES;
    NSError *err = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:self.dirPath isDirectory:&isDir]){
        [manager createDirectoryAtPath:self.dirPath withIntermediateDirectories:NO attributes:nil error:&err];
    }
}

- (NSString *)dirPath {
    if (!_dirPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = paths[0];
        _dirPath = [documentPath stringByAppendingPathComponent:@"dsdiff"];
    }
    return _dirPath;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
