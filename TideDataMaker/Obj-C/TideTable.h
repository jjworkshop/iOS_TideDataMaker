//
//  TideTable.h
//  SurfTide
//
//  Created by Mitsuhiro Shirai on 2013/01/01.
//  Copyright (c) 2013年 HIRO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TideTool.h"

// タイドデータ保存（ヒストリ用）
@interface TD2item : NSObject  <NSSecureCoding>
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* NP;
@property (nonatomic, strong) NSString* lat;
@property (nonatomic, strong) NSString* lon;
@property (nonatomic, strong) NSString* TC0;
@property (nonatomic, strong) NSString* wN;
@property (nonatomic, strong) NSString* HR;
@property (nonatomic, strong) NSString* PL;
@end

// タイド情報保存オブジェクト
@interface _TD2 : NSObject {
@public
	NSString*	NP;     // ロケーション名
	double	lat;        // 緯度
	double	lon;        // 経度
	double	TC0;        // 平均水面
	NSArray*	wN;     // NSString[40]
	double	HR[40];
	double	PL[40];
	double	lat_save;   // 緯度(保存用)
	double	lon_save;   // 経度(保存用)
}
@end

// 係数テーブルオブジェクト
@interface _COEFFICIENT : NSObject {
@public
	double	latR;       // 緯度R
	double	lonR;       // 経度R
	double	PI;         // Pi 3.141593
	double	DR;         // DR = PI / 180
	double	RD;         // RD = 180 / PI
	double	TD;         // 天文計算用　通日
	double	T;          // 〃
	double	S;          // 月の平均黄経
	double	H;          // 太陽の平均黄経
	double	P;          // 月の近地点の平均黄経
	double	N;          // 月の昇交点の平均黄経
    
    // 以下　天文引数 v u 、天文因数 f
	double	uMm;
	double	uMf;
	double	uO1;
	double	uK1;
	double	uJ1;
	double	uOO1;
	double	uM2;
	double	uK2;
	double	uL2;
	double	fL2;
	double	uM1;
	double	fM1;
	double	fMm;
	double	fMf;
	double	fO1;
	double	fK1;
	double	fJ1;
	double	fOO1;
	double	fM2;
	double	fK2;
	double V[40];
	double U[40];
	double F[40];
	double VUG[40];
    
    // 以下 zone time
	int		ZT;
	int		ZTm;
	
    // 以下 グラフ作成用
	double	Range;
	double	Ht;
	double	graphscale;
	double VU[40];
	double yPos[73];	// x は 0〜1440 step 20 で固定
    
    // 以下 zone time 零時の天文引数
	double NC[40];
	double AGS[40];
    
    // 以下 指定の日正午のデータ　（月齢、月の輝面に使用する）
	double	UT;
	double	Td12;
	double	LM12;
	double	LS12;
	double	BT;
	double	BH;
    
    // 以下 illuminated fraction of the Moon  月の輝面
	double	SMD12;
	double	SMD;
	double	IOTA;
	double	ILUM;
    
    // 以下 サンライズ、ムーンライズ計算 （VB 0〜）
	double SEvent[7];
	double	Alt;
	double	SMP;		// 太陽正中時刻
	double	MMP;		// 月正中時刻
	double	AGE;		// 月齢
	NSString*	Sio;
	double	MoonR;
	double	MoonS;
    
    // 潮時　潮高
	double ChoT[5];
	double ChoTC[5];
}
@end

@interface TideTable : NSObject
{
    _TD2* m_TD2;            // TD2 ファイル情報
    _COEFFICIENT* m_COEF;   // 係数テーブル
}
@property (nonatomic, strong) _TD2*	TD2;
@property (nonatomic, strong) _COEFFICIENT*	COEF;
// イニシャライザ
- (id)init;
// タイドテーブルの作成
- (bool)make:(int)idx yy:(int)inYY mm:(int)inMM dd:(int) inDD load:(bool)isTD2Load;
- (bool)makeEx:(int)inYY mm:(int)inMM dd:(int) inDD;
- (bool)makeWk:(NSString*)name yy:(int)inYY mm:(int)inMM dd:(int) inDD;
- (bool)makeWatch:(NSString*)name yy:(int)inYY mm:(int)inMM dd:(int) inDD;
// タイド位置情報文字列を返す
- (NSString*)GetMoreInfoText;
- (NSString*)GetMoreInfoTextDayOnly;
- (NSString*)GetLatLonText;
- (CGFloat)GetLat;
- (CGFloat)GetLon;
- (NSString*)GetMoreInfoLocationAndYmd;
// 各種ゲッター
- (double)TD2_lat;
- (double)TD2_lon;
- (NSString*)TD2_NP;
- (double)TD2_TC0;
- (NSString*)COEF_Sio;
- (double)COEF_graphscale;
- (double)COEF_Range;
- (double)SunRise;
- (double)SunSet;
- (double)COEF_SMD12;
- (double)COEF_DR;
- (NSArray*)COEF_yPosArray;
- (NSArray*)COEF_hiAndLowArray;
- (NSArray*)COEF_SEventArray;
- (double)COEF_AGE;
- (double)COEF_ILUM;
- (NSArray*)COEF_MEventArray;
- (NSArray*)TD2_TInfoArray;
@end
