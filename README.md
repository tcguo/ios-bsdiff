# bsdiff
This project is a copy of Colin Percival's[ binary diff/patch](http://www.daemonology.net/bsdiff/) with an Xcode project. The project includes a new nsdata category, which performs a binary search and replace.

[This is bsdiff-4.3 from](http://www.daemonology.net/bsdiff/)
#Dependencies
bdiff requires libbz2 to compress its diffs


#Use

```objc
@interface NSData (bsdiff)

// original c method
+ (BOOL)createDiffWithOldFile:(NSString *)oldFile newFile:(NSString *)newFile patchFile:(NSString *)patchFile;
+ (BOOL)applyWithOldFile:(NSString *)oldFile patchFile:(NSString *)patchFile newFile:(NSString *)newFile;


- (NSData *)diff:(NSData *)data;
+ (NSData *)dataWithData:(NSData *)data andPatch:(NSData *)patch;
- (NSData *)patch:(NSData *)patch;

@end
```


