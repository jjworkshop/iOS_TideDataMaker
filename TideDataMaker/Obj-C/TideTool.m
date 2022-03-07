//
//  TideTool.m
//  SurfTide
//
//  Created by Mitsuhiro Shirai on 2013/01/01.
//  Copyright (c) 2013年 HIRO. All rights reserved.
//

#import "TideTool.h"

@implementation TideTool

// 時間の位
+ (int)FNHH:(double)X	{
    return (int)([TideTool FNRH:X]) + round([TideTool FNRM:X]) / 60;
}

// 分単位の数を四捨五入して 60 になったら 0 に直す
+ (int)FNMM:(double)X	{
    return (int)(round([TideTool FNRM:X])) % 60;
}

// 時間単位の数を 0ｰ24 の範囲に丸める
+ (double)FNRH:(double)X	{
    return X - floor(X / 24) * 24;
}

// 時間の端数を分の表示にする
+ (double)FNRM:(double)X	{
    return (X - floor(X)) * 60;
}


// 角度を 0 から 360 の範囲に丸める
+ (double)FNRdouble:(double)X {
    return (X - floor(X / 360) * 360);
}

// 角度を ｰ180 から +180 の範囲に丸める
+ (double)FNR2double:(double)X {
    return X - (int)((X + [TideTool SGNdouble:X] * 180) / 360) * 360;
}

// サインを戻す
+ (int)SGNdouble:(double)X {
    return (X==0 ? 0 : (X>0 ? 1 : -1));
}

// ユリウス日を求める
+ (double)Jurian:(int)inYY MM:(int)inMM DD:(int)inDD {
	int		theYK,theXM;
	double	theJDate;
	if (inMM > 2)	{
		theYK = inYY;
		theXM = inMM;
    }
	else	{
		theYK = inYY - 1;
		theXM = inMM + 12;
    }
	float	theSumA = (float)(floor(theYK / 100));
	float	theSumB = 2 - theSumA + floor(theSumA / 4);
	long	theSumC = floor(365.25 * theYK);
	theJDate = 1720994.5 + floor(30.6001 * (theXM + 1))
    + theSumB + theSumC + inDD;
	return theJDate;    
}


@end
