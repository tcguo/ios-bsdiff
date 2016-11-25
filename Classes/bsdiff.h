//
//  bsdiff.h
//  bsdiff
//
//  Created by tcguo on 16/11/25.
//  Copyright © 2016年 baidu. All rights reserved.
//

#ifndef bsdiff_h
#define bsdiff_h

#define LBD_OK 0

#define LBD_ERR_OPEN 1000
#define LBD_ERR_CLOSE 1005
#define LBD_ERR_MALLOC 1010
#define LBD_ERR_SEEK 1015
#define LBD_ERR_TELL 1020
#define LBD_ERR_READ 1025
#define LBD_ERR_WRITE 1030
#define LBD_ERR_CORRUPT 1035

#define LBD_ERR_BZ 2000

#include <stdio.h>

int ff_diff(const char *oldf, const char *newf, const char *patchf);
int ff_patch(const char *oldf, const char *patchf, const char *newf);

#endif /* bsdiff_h */
