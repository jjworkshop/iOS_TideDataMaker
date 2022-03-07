//
//  TideTool.h
//  SurfTide
//
//  Created by Mitsuhiro Shirai on 2013/01/01.
//  Copyright (c) 2013年 HIRO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TideTool : NSObject
+ (int)FNHH:(double)X;
+ (int)FNMM:(double)X;
+ (double)FNRH:(double)X;
+ (double)FNRM:(double)X;
+ (double)FNRdouble:(double)X;
+ (double)FNR2double:(double)X;
+ (int)SGNdouble:(double)X;
+ (double)Jurian:(int)inYY MM:(int)inMM DD:(int)inDD;
@end
