//
//  TideTable.m
//  SurfTide
//
//  Created by Mitsuhiro Shirai on 2013/01/01.
//  Copyright (c) 2013年 HIRO. All rights reserved.
//

#import "TideTable.h"
#import "Share-Header.h"

// 1〜12 の月の日数
static	int	sDayOfMonth[13] =
{0,31,28,31,30,31,30,31,31,30,31,30,31};


// タイドデータ保存（ヒストリ用）
@implementation TD2item
@synthesize title;
@synthesize NP;
@synthesize lat;
@synthesize lon;
@synthesize TC0;
@synthesize wN;
@synthesize HR;
@synthesize PL;
+ (BOOL)supportsSecureCoding {
  return YES;
}
- (id)init {
    if (self = [super init]) {
        title = nil;
        NP = nil;
        lat = nil;
        lon = nil;
        TC0 = nil;
        wN = nil;
        HR = nil;
        PL = nil;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        title = [decoder decodeObjectForKey:@"title"];
        NP = [decoder decodeObjectForKey:@"NP"];
        lat = [decoder decodeObjectForKey:@"lat"];
        lon = [decoder decodeObjectForKey:@"lon"];
        TC0 = [decoder decodeObjectForKey:@"TC0"];
        wN = [decoder decodeObjectForKey:@"wN"];
        HR = [decoder decodeObjectForKey:@"HR"];
        PL = [decoder decodeObjectForKey:@"PL"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:title forKey:@"title"];
    [encoder encodeObject:NP forKey:@"NP"];
    [encoder encodeObject:lat forKey:@"lat"];
    [encoder encodeObject:lon forKey:@"lon"];
    [encoder encodeObject:TC0 forKey:@"TC0"];
    [encoder encodeObject:wN forKey:@"wN"];
    [encoder encodeObject:HR forKey:@"HR"];
    [encoder encodeObject:PL forKey:@"PL"];
}
- (void)dealloc
{
    title = nil;
    NP = nil;
    lat = nil;
    lon = nil;
    TC0 = nil;
    wN = nil;
    HR = nil;
    PL = nil;
}
- (id)copyWithZone:(NSZone*)zone
{
    TD2item* item = [[[self class] allocWithZone:zone] init];
    if (item)
    {
        item->title = [title copyWithZone:zone];
        item->NP = [NP copyWithZone:zone];
        item->lat = [lat copyWithZone:zone];
        item->lon = [lon copyWithZone:zone];
        item->TC0 = [TC0 copyWithZone:zone];
        item->wN = [wN copyWithZone:zone];
        item->HR = [HR copyWithZone:zone];
        item->PL = [PL copyWithZone:zone];
    }
    return item;
}
@end

// タイド情報保存オブジェクト
@implementation _TD2
@end

// 係数テーブルオブジェクト
@implementation _COEFFICIENT
@end

// private用
@interface TideTable (){
	int	m_YY,m_MM,m_DD;         // 処理日付
}
-(void)PurgeTD2;                // タイド情報エリア破棄
// 係数設定
- (void)Coefficient;
- (void)CycleConst;		//分潮の波数
- (void)AngularSpeed;	//分潮の角速度
- (void)MeanLongitudesH4:(int)inTY  TZ:(int)inTZ;		// 太陽、月の軌道
- (void)MoonPosition:(double*)outLM HP:(double*)outHP;	// 月の状態を計算
- (double)LongSun;	// 太陽の状態を計算

// 太陽の正中時刻を求める
- (double)SunMeriPass;
- (void)EquatCoordinate:(double)inLM RA:(double*)outRA DC:(double*)outDC;
- (double)GrSidTime;

// 月の正中時刻を求める
- (double)MoonMeriPass;
- (void)MoonMeriPassCalc:(double*)outLST UT2:(int*)outUT2;

// サンライズとムーンライズの計算
- (void)SunAndMoonCalculation;
- (void)Sunrise;
- (void)SunriseSub:(int)inPM;
- (void)SunCalc;
- (void)ROOT2:(double*)ioTA FA:(double*)ioFA FB:(double*)ioFB TB:(double*)ioTB E:(double)inE FS:(double)inFS;
- (void)AltAzimuth:(double)inDC AZ:(double*)outAZ;
- (double)MoonAge;
- (void)MoonAgeSub:(int)inINCL Tdd:(double*)ioTdd SMD:(double)inSMD LM:(double*)outLM HP:(double*)outHP LS:(double*)outLS;
- (void)Siomawari;
- (void)MoonRise;
- (void)MoonCalc;
- (void)ROOT:(double*)ioTA FA:(double*)ioFA FB:(double*)ioFB TB:(double*)ioTB F:(double*)ioF RS:(int)inRS FlagR:(int*)outFlagR FlagS:(int*)outFlagS;

// 潮汐計算
- (void)TideCalculation;
- (int) Lagrange:(double*)ioT Y:(double*)ioY Itv:(double*)ioItv;
- (double)FNCO:(int)j;

// 天文引数 v u 、天文因数 f
- (void)BasicCoefAug;
- (void)ArgumentV;
- (double)FNV:(double)A BB:(double)B CC:(double)C DD:(double)D;
- (void)ArgumentU;
- (void)CoefficF;

// 度分表示形式（dd.mm）の角度を度の単位に直す
- (double)FNDG:(double)X;

// 角度を 0 から 360 の範囲に丸める
- (double)FNRR:(double)X;

// 角度を ｰ180 から +180 の範囲に丸める
- (double)FNR2R:(double)X;

// arctangent 出力の単位は度
- (double)FNATN2:(double)S C:(double)C;

// 角度を 0 から 360 の範囲に丸める
// arc cosine
- (double)FNACN:(double)X;

// arc sine
- (double)FNASN:(double)X;

// 緯度経度から日本かどうか判定
- (bool)isNippon:(double)inLat Lon:(double)inLon;

@end

// 実装　ーーーーー

enum {
    ext_none,
    ext_today,
    ext_watch
};

@implementation TideTable
@synthesize TD2 = m_TD2;
@synthesize COEF = m_COEF;

// イニシャライザ
- (id)init {
    self = [super init];
    if (self != nil) {
        // 初期処理
        m_YY	= 0;
        m_MM	= 0;
        m_DD	= 0;
        m_COEF = [[_COEFFICIENT alloc] init];
        
    }
    return self;
}

// ファイナライザ
- (void)dealloc
{
    // 終了処理（後始末）
	[self PurgeTD2];
	m_COEF = nil;
}

// タイド情報破棄
- (void)PurgeTD2 {
 	if (m_TD2)	{
		m_TD2 = nil;
	}   
}

// タイドテーブルの作成
- (bool)make:(int)idx yy:(int)inYY mm:(int)inMM dd:(int) inDD load:(bool)isTD2Load {
    return [self _makeTideTableShare:idx yy:inYY mm:inMM dd:inDD load:isTD2Load ext:ext_none name:nil];
}

// タイドテーブルの作成（TodayExtension用）
- (bool)makeEx:(int)inYY mm:(int)inMM dd:(int) inDD {
    return [self _makeTideTableShare:0 yy:inYY mm:inMM dd:inDD load:YES ext:ext_today name:nil];
}

// タイドテーブルの作成（Widget用）
- (bool)makeWk:(NSString*)name yy:(int)inYY mm:(int)inMM dd:(int) inDD {
    return [self _makeTideTableShare:0 yy:inYY mm:inMM dd:inDD load:YES ext:ext_today name:name];
}

// タイドテーブルの作成（Watch用）
- (bool)makeWatch:(NSString*)name yy:(int)inYY mm:(int)inMM dd:(int) inDD {
    return [self _makeTideTableShare:0 yy:inYY mm:inMM dd:inDD load:YES ext:ext_watch name:name];
}



// タイドテーブルの作成
- (bool)_makeTideTableShare:(int)idx yy:(int)inYY mm:(int)inMM dd:(int) inDD load:(bool)isTD2Load ext:(int)ext name:(NSString*)name{
	// 係数設定
	bool	result = YES;
	m_YY = inYY;
	m_MM = inMM;
	m_DD = inDD;
	[self Coefficient];
    
	// タイドテーブルを読み込み
	if (isTD2Load)	{
		// 最初に既存を破棄
		[self PurgeTD2];
		// TD2 タイド情報取込
		m_TD2 = [[_TD2 alloc] init];
        NSArray* paramsHR;
        NSArray* paramsPL;
        NSUserDefaults* userDefaults = nil;
        // Extension/Widget用
        if (ext == ext_today) {
            userDefaults = [[NSUserDefaults alloc] initWithSuiteName:GROUP_ID];
        }
        else {
            userDefaults = [NSUserDefaults standardUserDefaults];
        }
        if (name != nil) {
            // Widgetの場合
            NSData* itemData = [userDefaults objectForKey:name];
            if (itemData == nil) return NO;
            //TD2item* item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
            NSError *error = nil;
            TD2item* item = [NSKeyedUnarchiver unarchivedObjectOfClasses: [NSSet setWithObjects: [NSString class], [TD2item class], nil] fromData:itemData error:&error];
            m_TD2->NP  = item.NP;
            m_TD2->lat = [item.lat doubleValue];
            m_TD2->lon = [item.lon doubleValue];
            m_TD2->TC0 = [item.TC0 doubleValue];
            m_TD2->wN  = [item.NP componentsSeparatedByString:@":"];
            if (!m_TD2->NP) return NO;
            paramsHR  = [item.HR componentsSeparatedByString:@":"];
            paramsPL  = [item.PL componentsSeparatedByString:@":"];
        }
        else {
            // ApplicationとExtensionの場合
            NSData* shareData = [userDefaults objectForKey:TD2_HISTRIES];
            if (shareData == nil) return NO;
            // NSArray* td2Array = [NSKeyedUnarchiver unarchiveObjectWithData:shareData];
            NSError *error = nil;
            NSArray* td2Array = [NSKeyedUnarchiver unarchivedObjectOfClasses: [NSSet setWithObjects: [NSArray class], [NSString class], [TD2item class], nil] fromData:shareData error:&error];
            if (idx >= 0 && idx < td2Array.count) {
                TD2item* item = td2Array[idx];
                m_TD2->NP  = item.NP;
                m_TD2->lat = [item.lat doubleValue];
                m_TD2->lon = [item.lon doubleValue];
                m_TD2->TC0 = [item.TC0 doubleValue];
                m_TD2->wN  = [item.NP componentsSeparatedByString:@":"];
                if (!m_TD2->NP) return NO;
                paramsHR  = [item.HR componentsSeparatedByString:@":"];
                paramsPL  = [item.PL componentsSeparatedByString:@":"];
            }
            else {
                NSAssert(false , @"Index error!");
                return NO;
            }
        }

        NSAssert(paramsHR.count == 40, @"HR_tbl Err!");
        for (int i=0;i<40;i++) {
            m_TD2->HR[i] = [[paramsHR objectAtIndex:i] doubleValue];
        }
        NSAssert(paramsPL.count == 40, @"PL_tbl Err!");
        for (int i=0;i<40;i++) {
            m_TD2->PL[i] = [[paramsPL objectAtIndex:i] doubleValue];
        }
        
        // 計算で利用するため保存
        m_TD2->lat_save = m_TD2->lat;
        m_TD2->lon_save = m_TD2->lon;
	}
	else	{
		// 読み込まない場合は、計算で利用されているため元に戻す
		m_TD2->lat = m_TD2->lat_save;
		m_TD2->lon = m_TD2->lon_save;
	}
    
	// 各種計算用設定
	if (result)	{
		m_COEF->Range = m_TD2->HR[24];
		
        // ---  緯度、経度を度の単位に直す
		m_TD2->lat = [self FNDG:m_TD2->lat];
		m_TD2->lon = [self FNDG:m_TD2->lon ];
		m_COEF->latR = m_TD2->lat * m_COEF->DR;
		m_COEF->lonR = m_TD2->lon * m_COEF->DR;
        
		// --- zone time 帯域時の決定
		m_COEF->ZT = (int)((m_TD2->lon + [TideTool SGNdouble:m_TD2->lon] * 7.5) / 15) * 15;
		m_COEF->ZTm = m_COEF->ZT / 15;
		if ([self isNippon:m_TD2->lat Lon:m_TD2->lon] == 1)	{
			m_COEF->ZT  = 135;
			m_COEF->ZTm = 9;
		}
        
		// --- グラフのスケールの決定
		m_COEF->Ht = m_TD2->TC0 + m_TD2->HR[24] + m_TD2->HR[28];
		if		(m_COEF->Ht >= 0  && m_COEF->Ht <= 130)
            m_COEF->graphscale = 1;
		else if (m_COEF->Ht > 130 && m_COEF->Ht <= 195)
            m_COEF->graphscale = 1.5;
		else if (m_COEF->Ht > 195 && m_COEF->Ht <= 260)
            m_COEF->graphscale = 2;
		else if (m_COEF->Ht > 260 && m_COEF->Ht <= 390)
            m_COEF->graphscale = 3;
        else
            m_COEF->graphscale = 4;
        
		// --- zone time 零時の天文引数
		for (int i=0;i<40;i++)	{
			m_COEF->VU[i] = m_COEF->VUG[i] - m_COEF->NC[i] *
            (-m_TD2->lon) + m_COEF->AGS[i] * (-m_COEF->ZTm);
			m_COEF->VU[i] = [TideTool FNRdouble:m_COEF->VU[i]];
        }
        
		// --- 指定の日正午のデータ　（月齢、月の輝面に使用する）
		m_COEF->UT = 12 - m_COEF->ZTm;
		m_COEF->Td12 = m_COEF->TD + (m_COEF->UT / 24);	// 時刻の引き数を日の単位で表したもの
		m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
		double	theLM = 0;
		double	theHP = 0;
		[self MoonPosition:&theLM HP:&theHP];
		m_COEF->LM12 = theLM * m_COEF->RD;
		double	theBT12 = m_COEF->BT;
		m_COEF->LS12 = [self LongSun];
        
		// --- illuminated fraction of the Moon  月の輝面
		m_COEF->SMD12 = [TideTool FNRdouble:m_COEF->LM12 - m_COEF->LS12];
		m_COEF->SMD = cos(m_COEF->SMD12 * m_COEF->DR) * cos(theBT12);
		m_COEF->SMD = [self FNACN:m_COEF->SMD];
		m_COEF->IOTA = 180 - m_COEF->SMD - 0.1468 * sin(m_COEF->SMD * m_COEF->DR);
		m_COEF->ILUM = (1 + cos(m_COEF->IOTA * m_COEF->DR)) / 2 * 100;
        
		// サンライズとムーンライズの計算
		[self SunAndMoonCalculation];
        
		// 潮汐計算
		[self TideCalculation];
		
	}
	return result;
}

// タイド位置情報文字列を返す
- (NSString*)	GetMoreInfoText {
	NSString*	theStr;
	if (m_TD2)	{
        theStr = [NSString stringWithFormat:@"%4d年%2d月%2d日　位置 %@",
                  m_YY,m_MM,m_DD,
                  [self GetLatLonText]];
	}
	return theStr;
}
- (NSString*)	GetMoreInfoTextDayOnly {
	NSString*	theStr;
	if (m_TD2)	{
        theStr = [NSString stringWithFormat:@"%2d日 %@",
                  m_DD,
                  [self GetLatLonText]];
	}
	return theStr;
}
- (NSString*)	GetMoreInfoLocationAndYmd {
	NSString*	theStr;
	if (m_TD2)	{
        theStr = [NSString stringWithFormat:@"%@ %4d年%d月%d日",
                  m_TD2->NP, m_YY,m_MM,m_DD];
	}
	return theStr;
}



// 緯度経度の文字列を返す
- (NSString*)	GetLatLonText {
	NSString*	theStr;
	if (m_TD2)	{
        theStr = [NSString stringWithFormat:@"%.2f%@ %.2f%@",
                  m_TD2->lat_save,
                  (m_TD2->lat_save > 0 ? @"N" : @"S"),
                  m_TD2->lon_save,
                  (m_TD2->lon_save > 0 ? @"E" : @"W")];
	}
	return theStr;
}

// 緯度経度の数値を戻す
- (CGFloat)	GetLat {
	if (m_TD2)	{
        return m_TD2->lat_save;
	}
	return 0;
}
- (CGFloat)	GetLon {
	if (m_TD2)	{
        return m_TD2->lon_save;
	}
	return 0;
}


// 係数設定
- (void)Coefficient {
	NSAssert(m_COEF, @"Err! m_COEF is nil");
	if (!m_COEF)	return;		// 番兵
    
	// 係数テーブルの初期化
	m_COEF->PI = 3.141593;
	m_COEF->DR = m_COEF->PI / 180;
	m_COEF->RD = 180 / m_COEF->PI;
    
    [self CycleConst];      //分潮の波数
    [self AngularSpeed];	//分潮の角速度
    
	// 2月の日数の設定
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:m_YY];
    [comps setMonth:2];
    // 和暦対応漏れ（v1.3.0更新）
    // NSCalendar *cal = [NSCalendar currentCalendar];
    NSCalendar *cal = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [cal dateFromComponents:comps];
    NSRange range = [cal rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
	sDayOfMonth[2] = (int)range.length;
    
	// --- 潮汐計算用　通日 theTZ
	int i;
	int	theDay = 0;
	int	theMM = m_MM;
	for(i = 1;i < theMM;i++)	{
		theDay += sDayOfMonth[i];
	}
	theDay += m_DD - 1;
	int	theTY = m_YY - 2000;
	int	theLeap = (int)((m_YY + 3) / 4) - 500;
	int	theTZ = theDay + theLeap;
    
	// --- 天文計算用　通日
	double	theJD = [TideTool Jurian:m_YY MM:m_MM DD:m_DD];
	m_COEF->TD  = theJD - 2451545;
	m_COEF->T	= m_COEF->TD / 36525;
    
    // --- 太陽、月の軌道
    [self MeanLongitudesH4:theTY TZ:theTZ];
    
	// --- 天文引数 v u 、天文因数 f
	[self BasicCoefAug];
	[self ArgumentV];
	[self ArgumentU];
	[self CoefficF];
    
    // --- グリニッチ標準時零時の天文引数
    for (i = 0;i<40;i++)	{
        m_COEF->VUG[i] = [TideTool FNRdouble:m_COEF->V[i] + m_COEF->U[i]];
    }    
}

//分潮の波数
- (void)CycleConst {
	m_COEF->NC[0]  = 0;	// Sa
	m_COEF->NC[1]  = 0;	// Ssa
	m_COEF->NC[2]  = 0;	// Mm
	m_COEF->NC[3]  = 0;	// MSf
	m_COEF->NC[4]  = 0;	// Mf
	m_COEF->NC[5]  = 1;	// Q1
	m_COEF->NC[6]  = 1;	// Rho1
	m_COEF->NC[7]  = 1;	// O1
	m_COEF->NC[8]  = 1;	// MP1
	m_COEF->NC[9]  = 1;	// M1
	m_COEF->NC[10] = 1;	// Pi1
	m_COEF->NC[11] = 1;	// P1
	m_COEF->NC[12] = 1;	// S1
	m_COEF->NC[13] = 1;	// K1
	m_COEF->NC[14] = 1;	// Psi1
	m_COEF->NC[15] = 1;	// Phi1
	m_COEF->NC[16] = 1;	// J1
	m_COEF->NC[17] = 1;	// SO1
	m_COEF->NC[18] = 1;	// OO1
	m_COEF->NC[19] = 2;	// 2N2
	m_COEF->NC[20] = 2;	// Mu2
	m_COEF->NC[21] = 2;	// N2
	m_COEF->NC[22] = 2;	// Nu2
	m_COEF->NC[23] = 2;	// OP2
	m_COEF->NC[24] = 2;	// M2
	m_COEF->NC[25] = 2;	// Lam2
	m_COEF->NC[26] = 2;	// L2
	m_COEF->NC[27] = 2;	// T2
	m_COEF->NC[28] = 2;	// S2
	m_COEF->NC[29] = 2;	// R2
	m_COEF->NC[30] = 2;	// K2
	m_COEF->NC[31] = 2;	// 2SM2
	m_COEF->NC[32] = 3;	// MO3
	m_COEF->NC[33] = 3;	// M3
	m_COEF->NC[34] = 3;	// MK3
	m_COEF->NC[35] = 3;	// SK3
	m_COEF->NC[36] = 4;	// M4
	m_COEF->NC[37] = 4;	// MS4
	m_COEF->NC[38] = 6;	// M6
	m_COEF->NC[39] = 6;	// 2MS6    
}

//分潮の角速度
- (void)AngularSpeed {
	m_COEF->AGS[0]  = 0.0410686;	// Sa
	m_COEF->AGS[1]  = 0.0821373;	// Ssa
	m_COEF->AGS[2]  = 0.5443747;	// Mm
	m_COEF->AGS[3]  = 1.0158958;	// MSf
	m_COEF->AGS[4]  = 1.0980331;	// Mf
	m_COEF->AGS[5]  = 13.3986609;	// Q1
	m_COEF->AGS[6]  = 13.4715145;	// Rho1
	m_COEF->AGS[7]  = 13.9430356;	// O1
	m_COEF->AGS[8]  = 14.0251729;	// MP1
	m_COEF->AGS[9]  = 14.4920521;	// M1
	m_COEF->AGS[10] = 14.9178627;	// Pi1  H4
	m_COEF->AGS[11] = 14.9589314;	// P1
	m_COEF->AGS[12] = 15;			// S1
	m_COEF->AGS[13] = 15.0410686;	// K1
	m_COEF->AGS[14] = 15.0821373;	// Psi1    H4
	m_COEF->AGS[15] = 15.1232059;	// Phi1
	m_COEF->AGS[16] = 15.5854433;	// J1
	m_COEF->AGS[17] = 16.0569644;	// SO1
	m_COEF->AGS[18] = 16.1391017;	// OO1
	m_COEF->AGS[19] = 27.8953548;	// 2N2
	m_COEF->AGS[20] = 27.9682084;	// Mu2
	m_COEF->AGS[21] = 28.4397295;	// N2
	m_COEF->AGS[22] = 28.5125831;	// Nu2
	m_COEF->AGS[23] = 28.9019669;	// OP2
	m_COEF->AGS[24] = 28.9841042;	// M2
	m_COEF->AGS[25] = 29.4556253;	// Lam2
	m_COEF->AGS[26] = 29.5284789;	// L2
	m_COEF->AGS[27] = 29.9589314;	// T2    H4
	m_COEF->AGS[28] = 30;			// S2
	m_COEF->AGS[29] = 30.0410686;	// R2    H4
	m_COEF->AGS[30] = 30.0821373;	// K2
	m_COEF->AGS[31] = 31.0158958;	// 2SM2
	m_COEF->AGS[32] = 42.9271398;	// MO3
	m_COEF->AGS[33] = 43.4761563;	// M3
	m_COEF->AGS[34] = 44.0251729;	// MK3
	m_COEF->AGS[35] = 45.0410686;	// SK3
	m_COEF->AGS[36] = 57.9682084;	// M4
	m_COEF->AGS[37] = 58.9841042;	// MS4
	m_COEF->AGS[38] = 86.9523126;	// M6
	m_COEF->AGS[39] = 87.9682083;	// 2MS6
}

// 太陽、月の軌道
- (void)MeanLongitudesH4:(int)inTY  TZ:(int)inTZ {
	// Orbit of the Sun and the Moon  太陽、月の軌道
	//この式の通用期間は?
	//平成４年２月発行の「定数表」による
    
	// inTY		西暦年数より2000を引いたもの
	// inTZ		「日本全国潮汐調和定数表」で使っている通日
    
	// 月の平均黄経
	m_COEF->S = 211.728 + [TideTool FNRdouble:129.38471 * (double)inTY] +
                          [TideTool FNRdouble:13.176396 * (double)inTZ];
	// 太陽の平均黄経
	m_COEF->H = 279.974 - 0.23871  * (double)(inTY) + 0.985647 * (double)(inTZ);
	// 月の近地点の平均黄経
	m_COEF->P = 83.298 + 40.66229  * (double)(inTY) + 0.111404 * (double)(inTZ);
	// 月の昇交点の平均黄経
	m_COEF->N = 125.071 - 19.32812 * (double)(inTY) - 0.052954 * (double)(inTZ);
    
}

// 月の状態を計算
- (void)MoonPosition:(double*)outLM HP:(double*)outHP {
	double	theEC = 0.05488;							// 月の軌道の離心率
	double	theIR = 5.13 * m_COEF->DR;					// 白道傾斜角
	double	theA = 60.268;								// 軌道長半径
	double	theB = 60.268 * sqrt(1 - pow(theEC,2));		// 軌道短半径
    
	double	theArg = 125.045 - 1934.136 * m_COEF->T;	// 月の昇交点の黄経
	double	theOLR = [TideTool FNRdouble:theArg];
    
	theArg = 318.309 + 6003.15 * m_COEF->T;		// 月の近地点黄経−月の昇交点黄経
	double	theOSR = [TideTool FNRdouble:theArg];
	theOSR *= m_COEF->DR;
    
	// 平均近点離角 mean anomaly （月の平均黄経−月の近地点黄経）
	theArg = 134.963 + 477198.868 * m_COEF->T;
	double	theM = [TideTool FNRdouble:theArg];
	theM *=  m_COEF->DR;
    
	theArg = 297.85 + 445267.112 * m_COEF->T;	// 月の平均黄経 - 太陽の平均黄経
	double	theD = [TideTool FNRdouble:theArg];
	theD *= m_COEF->DR;
    
	theArg = 357.529 + 35999.05 * m_COEF->T;	// 太陽の平均黄経−太陽の近地点黄経
	double	theMP = [TideTool FNRdouble:theArg];
    theMP *= m_COEF->DR;
                 
     // 平均近点離角 mean anomaly の補正（太陽による摂動）
     // 天文年鑑と係数がかなり異なる
     theM = theM + 0.01026 * sin(2 * theD);
     theM = theM + 0.0216 * sin(2 * theD - theM);
     theM = theM - 0.01124 * sin(theMP);
     
     theOSR = theOSR + 0.00801 * sin(theMP);
     
     // --- ケプラー方程式を解く（平均近点離角より離心近点離角を求める）
     double	theU = theM;
     double	theUBAK = 0;
     do
     {
         theUBAK = theU;
         theU = theM + theEC * sin(theU);
     }
     while (ABS(theUBAK - theU) > 0.0001);
     
     //--- 離心近点離角より真近点離角、距離を求める
     
     double	theX = theA * (cos(theU) - theEC);		// r cos v = a( cos E - e )
     double	theY = theB * sin(theU);				// r sin v = b sin E
     double	theR = sqrt(pow(theX,2) + pow(theY,2));
     *outHP = 1 / theR;								// Horizontal Pallarax
     
    double	theF = [self FNATN2:theY C:theX] * m_COEF->DR;
     
     //---黄道座標への変換
     
     // ここで直角球面三角形の公式より
     // cos b cos(ι-Ω) = cos u
     // cos b sin(ι-Ω) = cos i sin u
     // sin b            = sin i sin u
     
     double	theA1 = cos(theOSR + theF);
     double	theB1 = cos(theIR) * sin(theOSR + theF);
     double	theC1 = sin(theIR) * sin(theOSR + theF);
     
     m_COEF->BT = atan(theC1 / sqrt(theA1 * theA1 + theB1 * theB1));
     m_COEF->BT = m_COEF->BT + 0.0025 * sin(2 * theD - theOSR - theM);// 太陽による摂動を補正
     
    double	theL1 = [self FNATN2:theB1 C:theA1] * m_COEF->DR;
     
     // 昇交点黄経を加えて月の黄経を出す
     *outLM = theL1 + theOLR * m_COEF->DR;		// theOLR 月の昇交点の黄経
     
     // 又補正するのか？
     *outLM = *outLM - 0.00061 * sin(theD) + 0.0008 * sin(2 * theD - theMP);
     *outLM = *outLM + 0.001 * sin(2 * theD - theM - theMP);
     *outLM = [self FNRR:*outLM];
}

// 太陽の状態を計算
- (double)LongSun {
	// -----------------------
	// in )    m_COEF->T
	// 復帰    LS    度
	//
	//-----------------------
    
	double	theG = 36000.77 * m_COEF->T;
	theG = theG - floor(theG / 360) * 360;
	theG = (theG + 357.53);
	double	theLS = theG - (77.06 - 1.91 * sin(theG * m_COEF->DR));
	return [TideTool FNRdouble:theLS];
}

// 太陽の正中時刻を求める
- (double)SunMeriPass {
	// BT UT は更新されるよ！
    
	m_COEF->UT = 12 - (m_COEF->lonR * m_COEF->RD / 15);     // 測者の経度  時間で表す
	m_COEF->BT = 0;
	m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
	double	theLM = [self LongSun] * m_COEF->DR;
	double	theRA = 0;
	double	theDC = 0;
	[self EquatCoordinate:theLM RA:&theRA DC:&theDC];
	double	theTG = [self GrSidTime];
    
	theRA = theRA * m_COEF->RD;
	double	theLN2 = m_COEF->lonR * m_COEF->RD;
	double	theHG = [TideTool FNRdouble:(theTG - theRA)];	// theRA   太陽の赤緯
	double	theLHA = theHG + theLN2;						// theLHA  地方時角
	if (theLHA > 180)	theLHA -= 360;
	if (theLHA < -180)	theLHA += 360;
	return (m_COEF->UT - theLHA / 15);						// SMP 単位　時
}
- (void)EquatCoordinate:(double)inLM RA:(double*)outRA DC:(double*)outDC {
    double	theEP = 23.44 * m_COEF->DR;
    double	theA1 = cos(m_COEF->BT) * cos(inLM);
    double	theB1 = -sin(m_COEF->BT) * sin(theEP) + cos(m_COEF->BT) * cos(theEP) * sin(inLM);
    double	theC1 = sin(m_COEF->BT) * cos(theEP) + cos(m_COEF->BT) * sin(theEP) * sin(inLM);
    double	thsS = sqrt(pow(theA1,2) + pow(theB1,2));
    *outDC = atan(theC1 / thsS);
    *outRA = atan(theB1 / theA1);
    if (theA1 < 0)	*outRA = *outRA + m_COEF->PI;
}
- (double)GrSidTime {
	// wT には既に UT が含まれており重複するような気がするが
	// これで良いのである
	// TG 度
    double	theWTG = theWTG = 36000.7695 * m_COEF->T + 100.4604 + m_COEF->UT * 15;
    return [TideTool FNRdouble:theWTG];
}

// 月の正中時刻を求める
- (double)MoonMeriPass {
	// 月の正中時刻を求める
	// 指定の日に月が正中しない場合、次の日の正中時を求める
	// 指定の日の前日の正中時は求めないようにする
	// しかしこうして求めた値は、当日のもので無ければ使わない
	//  in ) Td#         通日
	//       latR        緯度、経度 ﾗｼﾞｱﾝ
	//  out) theMMP         正中時刻　（　世界時　単位は時　）
	//       m_COEF->UT
    
    double	theMMP = 0;
	int		theUT2 = 0;
	double	theLST = 0;
    
	// --- meridian passage
	double	theLonH = m_COEF->lonR * m_COEF->RD / 15;	// 経度　時
	m_COEF->UT = 11 - theLonH;					// local time 11時から始める
    
	[self MoonMeriPassCalc:&theLST UT2:&theUT2];
	int	theFLG1 = 0;
	for (;;)	{
		if (theFLG1 == 0 && 0 <= theLST && theLST <= 24)	{
            // 最初の計算で当日に収束
            theMMP = m_COEF->UT;
            break;
		}
		else if (theFLG1 == 0 && 24 < theLST)	{
            // 最初の計算で翌日に収束 これは無いであろう
            // NUKUALFA 1995/1021 有った
            m_COEF->UT = m_COEF->UT - 24;
            theFLG1 = 1;
            [self MoonMeriPassCalc:&theLST UT2:&theUT2];
            continue;
		}
		else if (theFLG1 == 0 && theLST < 0)	{
            // 前日（theLSTで）に収束したら
            m_COEF->UT = m_COEF->UT + 24;
            theFLG1 = 1;
            [self MoonMeriPassCalc:&theLST UT2:&theUT2];
            continue;
		}
		else if (theFLG1 == 1 && 24 < theLST)	{
            // 再計算して翌日に収束
            theMMP = m_COEF->UT;
            break;
		}
		else if (theFLG1 == 1 && 0 <= theLST && theLST <= 24)	{
            // 再計算して当日に収束
            theMMP = m_COEF->UT;
            break;
		}
		else	{
			// あってはならない
        	NSAssert(false, @"It can not be...");
			break;
		}
	}
	
	if (theLST < 0 || 24 < theLST)	theMMP = 99;	// 当日の値で無ければ使わない
	return theMMP;
}
- (void)MoonMeriPassCalc:(double*)outLST UT2:(int*)outUT2
{
    double	theLM = 0;
    double	theHP = 0;
    double	theSD = 0;
    double	theRA = 0;
    double	theDC = 0;
    double	theTG = 0;
    double	theAZ = 0;
    double	theLHA = 0;
    
    int	theDT = 24;
    int j = 0;
    while (ABS(theDT) > 0.1)	{
        j++;
        m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
        [self MoonPosition:&theLM HP:&theHP];
        theSD = 0.2725 * theHP;
        m_COEF->BH = (theHP - theSD - 0.57 * m_COEF->DR);
        [self EquatCoordinate:theLM RA:&theRA DC:&theDC];
        theTG = [self GrSidTime];
        theTG = theTG * m_COEF->DR;
        m_COEF->H = theTG - theRA + m_COEF->lonR;
        
        [self AltAzimuth:theDC AZ:&theAZ];
        theLHA = [self FNR2R:(theTG - theRA + m_COEF->lonR)] * m_COEF->RD;
        m_COEF->UT = m_COEF->UT - theLHA / 15;
        *outLST = m_COEF->UT + m_COEF->ZTm;
        theDT = round(m_COEF->UT) - *outUT2;
        *outUT2 = round(m_COEF->UT);
        if (j > 10)	{
			// あってはならない
        	NSAssert(false, @"It can not be...");
			break;
        }
    }
}

// サンライズとムーンライズの計算
- (void)SunAndMoonCalculation {
	// ========= SUNRISE,MOONRISE,潮回り CALCULATION ==========
	m_COEF->UT = 12 - m_COEF->ZTm;
    m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
	m_COEF->SMP = [self SunMeriPass];
    m_COEF->SEvent[3] = m_COEF->SMP;
    [self Sunrise];
    for (int i = 0;i<7;i++)	{
        if (m_COEF->SEvent[i] != 99)	m_COEF->SEvent[i] = m_COEF->SEvent[i] + m_COEF->ZTm;
    }
    
	m_COEF->MMP = [self MoonMeriPass];
    m_COEF->AGE = [self MoonAge];
    
    [self Siomawari];
    [self MoonRise];
    
    if (m_COEF->MMP   != 99)	m_COEF->MMP   += m_COEF->ZTm;
    if (m_COEF->MoonR != 99)	m_COEF->MoonR += m_COEF->ZTm;
    if (m_COEF->MoonS != 99)	m_COEF->MoonS += m_COEF->ZTm;
}
- (void)Sunrise {
	m_COEF->BT = 0;
    
	m_COEF->BH = -18 * m_COEF->DR;
	[self SunriseSub:0];
	m_COEF->SEvent[0] = m_COEF->UT;
    
	m_COEF->BH = -6 * m_COEF->DR;
	[self SunriseSub:0];
	m_COEF->SEvent[1] = m_COEF->UT;
    
	m_COEF->BH = -0.9 * m_COEF->DR;
	[self SunriseSub:0];
	m_COEF->SEvent[2] = m_COEF->UT;
    
	m_COEF->BH = -0.9 * m_COEF->DR;
	[self SunriseSub:12];
	m_COEF->SEvent[4] = m_COEF->UT;
    
	m_COEF->BH = -6 * m_COEF->DR;
	[self SunriseSub:12];
	m_COEF->SEvent[5] = m_COEF->UT;
    
	m_COEF->BH = -18 * m_COEF->DR;
	[self SunriseSub:12];
	m_COEF->SEvent[6] = m_COEF->UT;
}
- (void)SunriseSub:(int)inPM {
	double	theTA,theFA,theTB,theFB,theE,theFS;
	for(int j = (0 - m_COEF->ZTm + inPM);j<= (6 - m_COEF->ZTm + inPM);j += 6)	{
        
		m_COEF->UT = j;				// 最初に帯域時３時の計算をする
		theTA = m_COEF->UT;
		[self SunCalc];
		theFA = m_COEF->Alt - m_COEF->BH;
        
		m_COEF->UT = j + 6;			// 次に６時間後の計算をする 太陽の場合この間に出没時はある
		theTB = m_COEF->UT;
		[self SunCalc];
		theFB = m_COEF->Alt - m_COEF->BH;
		if (theFA * theFB > 0)	{	// ２回の高度さの正負が同じなら即ち出没が無ければ
			m_COEF->UT = 99;
		}
		else	{					// 出没が有ったら
			theFS = 0;
			theE = 0.0001;			// 精度   0.36秒
			[self ROOT2:&theTA FA:&theFA FB:&theFB TB:&theTB E:theE FS:theFS];
			break;
		}
	}    
}
- (void)SunCalc {
	double	theRA = 0;
	double	theDC = 0;
	double	theAZ = 0;
	m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
	double	theLM = [self LongSun] * m_COEF->DR;
	[self EquatCoordinate:theLM RA:&theRA DC:&theDC];
	double	theTG = [self GrSidTime] * m_COEF->DR;
	m_COEF->H = theTG - theRA + m_COEF->lonR;
	[self AltAzimuth:theDC AZ:&theAZ];
}
- (void)ROOT2:(double*)ioTA FA:(double*)ioFA FB:(double*)ioFB TB:(double*)ioTB E:(double)inE FS:(double)inFS {
	double	theF = 0;
	for (;;)	{
		m_COEF->UT = *ioTA + (inFS - *ioFA) / (*ioFB - *ioFA) * (*ioTB - *ioTA);
		[self SunCalc];
		theF = m_COEF->Alt - m_COEF->BH;
        
		if (ABS(theF - inFS) < inE)	{
			break;		// ある精度に達すれば      0.36秒
		}
		else if ((*ioFB - inFS) * (theF - inFS) > 0)	{
			// 今回の theF が 前回のtheF (*ioFB)と同符号ならば即ち
			// 新しい m_COEF->UT が *ioTB の側に来たなら真の出没時は *ioTA  と m_COEF->UT の間にある
			*ioTB = m_COEF->UT;
			*ioFB = theF;
		}
		else	{
			*ioTA = m_COEF->UT;
			*ioFA = theF;
		}
	}
}
- (void)AltAzimuth:(double)inDC AZ:(double*)outAZ {
	double	theA = -cos(inDC) * sin(m_COEF->H);
	double	theB = sin(inDC) * cos(m_COEF->latR) - cos(inDC) * sin(m_COEF->latR) * cos(m_COEF->H);
	double	theC = sin(inDC) * sin(m_COEF->latR) + cos(inDC) * cos(m_COEF->latR) * cos(m_COEF->H);
    
	m_COEF->Alt = atan(theC / sqrt(pow(theA,2) + pow(theB,2)));
	*outAZ = atan(theA / theB);
	if (theB < 0)	*outAZ = *outAZ + m_COEF->PI;
	if (*outAZ < 0)	*outAZ = *outAZ + 2 * m_COEF->PI;
}
- (double)MoonAge {
	//  in )  TD1210
	//        m_COEF->LM12
	//        m_COEF->LS12
	//  out)  かんすうち　げつれい
    
    
    double	theAGE = m_COEF->LM12 - m_COEF->LS12;
    
	// 指定の日zone time 12時の月太陽の黄経を使っておよその月齢を計算する
    
    if (theAGE < 0)	theAGE = theAGE + 360;
	// 指定の日より以前の朔を求めるために、theAGEは正の値にする
	// ちなみに、m_COEF->LM12 m_COEF->LS12 ともに 0 - 360 の範囲の
	// 値であるため、Age が 360 以上になることはない
    
    double	theX = 29.5305 * theAGE / 360;	// 朔は指定の日(DY)よりおよそ theX 日前である
    
    double	theTdd = m_COEF->Td12 - theX;
    double	theSMD = 0;		// 朔の時刻の初期値　（単位　日）
    double	theLM = 0;
    double	theLS = 0;
    double	theHP = 0;
    int		theINCL = 3;	// 繰り返し計算２回だと、1992/1/10の月齢0.1ずれる
    [self MoonAgeSub:theINCL Tdd:&theTdd SMD:theSMD LM:&theLM HP:&theHP LS:&theLS];
    theAGE = m_COEF->Td12 - theTdd;
    
    return theAGE;
}
- (void)MoonAgeSub:(int)inINCL Tdd:(double*)ioTdd SMD:(double)inSMD LM:(double*)outLM HP:(double*)outHP LS:(double*)outLS {
    double	theX;
    for (int j = 1;j <= inINCL;j++)	{
        m_COEF->T = *ioTdd / 36525;
        [self MoonPosition:outLM HP:outHP];
        *outLS = [self LongSun];
        *outLM = *outLM * m_COEF->RD;	// *outLS = *outLS * m_COEF->RD
        theX = 29.5305 * [TideTool FNR2double:(*outLM - *outLS - inSMD)] / 360;
        *ioTdd -= theX;
    }    
}
- (void)Siomawari {
	// 月齢から潮回りを決める
	if (m_COEF->AGE >= 0		&& 1.5 >= m_COEF->AGE)
        m_COEF->Sio = @"大潮";
	else if (m_COEF->AGE >= 1.5		&& 5.5 >= m_COEF->AGE)
        m_COEF->Sio = @"中潮";
        else if (m_COEF->AGE >= 5.5		&& 8.5 >= m_COEF->AGE)
            m_COEF->Sio = @"小潮";
            else if (m_COEF->AGE >= 8.5		&& 9.5 >= m_COEF->AGE)
                m_COEF->Sio = @"長潮";
                else if (m_COEF->AGE >= 9.5		&& 10.5 >= m_COEF->AGE)
                    m_COEF->Sio = @"若潮";
                    else if (m_COEF->AGE >= 10.5	&& 12.5 >= m_COEF->AGE)
                        m_COEF->Sio = @"中潮";
                        else if (m_COEF->AGE >= 12.5	&& 16.5 >= m_COEF->AGE)
                            m_COEF->Sio = @"大潮";
                            else if (m_COEF->AGE >= 16.5	&& 20.5 >= m_COEF->AGE)
                                m_COEF->Sio = @"中潮";
                                else if (m_COEF->AGE >= 20.5	&& 23.5 >= m_COEF->AGE)
                                    m_COEF->Sio = @"小潮";
                                    else if (m_COEF->AGE >= 23.5	&& 24.5 >= m_COEF->AGE)
                                        m_COEF->Sio = @"長潮";
                                        else if (m_COEF->AGE >= 24.5	&& 25.5 >= m_COEF->AGE)
                                            m_COEF->Sio = @"若潮";
                                            else if (m_COEF->AGE >= 25.5	&& 27.5 >= m_COEF->AGE)
                                                m_COEF->Sio = @"中潮";
                                                else if (m_COEF->AGE >= 27.5	&& 30.5 >= m_COEF->AGE)
                                                    m_COEF->Sio = @"大潮";
}
- (void)MoonRise {
	// theFlagR    月の出が有ったら 1 無ければ 0
	// theFlagS
    
	double	theF  = 0;
	double	theTA = 0;
	double	theFA = 0;
	double	theTB = 0;
	double	theFB = 0;
	int		theRS = 0;
    
	int	theFlagR = 0;
	int	theFlagS = 0;
    
	for (int j = (0 - m_COEF->ZTm); j<= (18 - m_COEF->ZTm);j +=6)	{
		m_COEF->UT = j;
		[self MoonCalc];
		theF  = m_COEF->Alt - m_COEF->BH;
		theTA = m_COEF->UT;
		theFA = theF;
		m_COEF->UT = j + 6;
		[self MoonCalc];
		theF  = m_COEF->Alt - m_COEF->BH;
		theTB = m_COEF->UT;
		theFB = theF;
		if (theFA * theFB > 0)	{
			// 出没無し
		}
		else	{
			// 出没有り
			theRS = 1;
			if (theFA > theFB)	theRS = 2;
			[self ROOT:&theTA FA:&theFA FB:&theFB TB:&theTB F:&theF RS:theRS FlagR:&theFlagR FlagS:&theFlagS];
        }
    }
    if (theFlagR == 0)	m_COEF->MoonR = 99;
    if (theFlagS == 0)	m_COEF->MoonS = 99;
}
- (void)MoonCalc {
   	double	theLM = 0;
    double	theHP = 0;
    double	theRA = 0;
    double	theDC = 0;
    double	theAZ = 0;
    
    m_COEF->T = (m_COEF->TD + m_COEF->UT / 24) / 36525;
    [self MoonPosition:&theLM HP:&theHP];
    double	theSD = 0.2725 * theHP;
    m_COEF->BH = (theHP - theSD - 0.57 * m_COEF->DR);
    [self EquatCoordinate:theLM RA:&theRA DC:&theDC];
    double	theTG = [self GrSidTime] * m_COEF->DR;
    m_COEF->H = theTG - theRA + m_COEF->lonR;
    [self AltAzimuth:theDC AZ:&theAZ];
}
- (void)ROOT:(double*)ioTA FA:(double*)ioFA FB:(double*)ioFB TB:(double*)ioTB F:(double*)ioF RS:(int)inRS FlagR:(int*)outFlagR FlagS:(int*)outFlagS {
	double	theE = 0.0001;
	double	theFS = 0;
    
	for (;;)	{
		m_COEF->UT = *ioTA + (theFS - *ioFA) /
        (*ioFB - *ioFA) * (*ioTB - *ioTA);
		[self MoonCalc];
		*ioF = m_COEF->Alt - m_COEF->BH;
		if (ABS(*ioF - theFS) > theE)	{
			if ((*ioFB - theFS) * (*ioF - theFS) > 0)	{
				*ioTB = m_COEF->UT;
				*ioFB = *ioF;
			}
			else	{
				*ioTA = m_COEF->UT;
				*ioFA = *ioF;
			}
			continue;
		}
		else	{
			// 収束した
			if (inRS == 1)	{
				m_COEF->MoonR = m_COEF->UT;
				*outFlagR = 1;
			}
			if (inRS == 2)	{
				m_COEF->MoonS = m_COEF->UT;
				*outFlagS = 1;
			}
			break;
		}
	}
}

// 潮汐計算
- (void)TideCalculation {
	// --- 潮汐計算、表示
	double	theItv = 20;
	int	i = -60;	// 0 - theItv * 3;
	double	theTC = 0;
	double	theWkT = -60;
    
	// クリア
	int k = 0;
	for (k=0;k<5;k++)	{
		m_COEF->ChoT[k]  = 0;
		m_COEF->ChoTC[k] = 0;
	}
	k = 0;
	int	theX = 0;
	for (theX=0;theX<73;theX++)	{
		m_COEF->yPos[theX]  = 0;
	}
	theX = 0;
    
	int	theLag = [self Lagrange:&theWkT Y:&theTC Itv:&theItv];	// Lagrange関数初期化
	#pragma unused(theLag)
    while (i <= 60 * 24 + theItv * 2)	{
		// --- Calculationof Tide
		m_COEF->T = (double)i / 60;			// hour
		theTC = m_TD2->TC0;
		for (int j = 0;j<40;j++)	{
			theTC += [self FNCO:j];
		}
		if		(i < 0 || (60 * 24) < i)	{
			;	// Do nothing
		}
		else	{
            NSAssert(theX < 73, @"Err!");
			if (theX < 73)	{
				m_COEF->yPos[theX] = theTC;
			}
			theX++;
		}
		double	theWkItv = 0;
		theLag = [self Lagrange:&m_COEF->T Y:&theTC Itv:&theWkItv];
        
		if (m_COEF->T < 0)	m_COEF->T += 24;
		int	theHH = (int)(m_COEF->T);
		int	theMM = round((m_COEF->T - theHH) * 60);
		if (theHH < 24)	{
			if (theLag == 1)	{
				if (theMM >= 60)	theMM = 59;
                #pragma unused(theMM)
				if (k < 5)	{
					m_COEF->ChoT[k]  = m_COEF->T;
					m_COEF->ChoTC[k] = theTC;
				}
				//frmTIDE.picCHOKOBK.Print Format$(theHH, "@@@") & ":" & Format$(theMM, "00") & "    " & Format$(Format$(theTC, "###0"), "@@@@") & "cm"
				k++;
			}
		}
		i += (int)(theItv);
	}	// Loop
}
- (int) Lagrange:(double*)ioT Y:(double*)ioY Itv:(double*)ioItv {
	// result補間法
	// 等間隔で変化する引数tm()（時刻）、その関数fx()（潮位）
	// 関数が極大になる時の引数を求め、関数の極大値も求める
	// 連続的にtm(),fx()を監視して極大があったら関数の戻り値を1にする
	// 変数*ioT,yを用いて,上記の値を返す
	//  *ioT = -60 の時初期化される
    
	int	result = 0;
    
	static int		s_k = 0;
	static double	s_tm1 = 0;
	static double	s_tm2 = 0;
	static double	s_tm3 = 0;
	static double	s_tm4 = 0;
	static double	s_fx1 = 0;
	static double	s_fx2 = 0;
	static double	s_fx3 = 0;
	static double	s_fx4 = 0;
	static double	s_df1 = 0;
	static double	s_df2 = 0;
	static double	s_df3 = 0;
	static double	s_sg1 = 0;
	static double	s_sg2 = 0;
	static double	s_sg3 = 0;
    
	if (*ioT == -60)	s_k = 0;
	s_k++;
    
	s_tm1 = s_tm2; s_tm2 = s_tm3; s_tm3 = s_tm4; s_tm4 = *ioT;
	s_fx1 = s_fx2; s_fx2 = s_fx3; s_fx3 = s_fx4; s_fx4 = *ioY;
	s_df1 = s_df2; s_df2 = s_df3; s_df3 = s_fx4 - s_fx3;
	s_sg1 = s_sg2; s_sg2 = s_sg3; s_sg3 = [TideTool SGNdouble:s_df3];
    
	if (s_k > 3 && s_sg1 != s_sg2)	{
        
		*ioItv = s_tm4 - s_tm3;
		double	theT1 = s_tm1 + *ioItv / 2;
		double	theT2 = s_tm2 + *ioItv / 2;
		double	theT3 = s_tm3 + *ioItv / 2;
		double	theNN = (-s_df1) / (s_df2 - s_df1);
		double	theLAG1 = (1 - theNN) * (2 - theNN) * theT1 / 2 + theNN *
        (2 - theNN) * theT2 - (1 - theNN) * theNN * theT3 / 2;
        
		if (theLAG1 > 0 && theLAG1 < 24)	{
			*ioT = theLAG1;				// 関数値 fx が 極大、極小になる引き数 t
			theNN = (*ioT - s_tm2) / (s_tm3 - s_tm2);
			double	theLAG2 = (1 - theNN) * (2 - theNN) * s_fx2 / 2 +
            theNN * (2 - theNN) * s_fx3 - (1 - theNN) * theNN * s_fx4 / 2;
			*ioY = theLAG2;				// その時の関数値 fx
			result = 1;					// 関数 result の戻り値を 1 にする
		}
	}
	return result;    
}
- (double)FNCO:(int)j {
    return m_COEF->F[j] * m_TD2->HR[j] *
    cos((m_COEF->VU[j] + m_COEF->AGS[j] *
         m_COEF->T - m_TD2->PL[j]) * m_COEF->DR);
}

// 天文引数 v u 、天文因数 f
- (void)BasicCoefAug {
	double	theS1 = sin(m_COEF->N * m_COEF->DR);
	double	theS2 = sin(m_COEF->N * 2 * m_COEF->DR);
	double	theS3 = sin(m_COEF->N * 3 * m_COEF->DR);
    
	m_COEF->uMm  = 0 * theS1 + 0 * theS2 + 0 * theS3;
	m_COEF->uMf  = -23.74 * theS1 + 2.68 * theS2 - 0.38 * theS3;
	m_COEF->uO1  = 10.8 * theS1 - 1.34 * theS2 + 0.19 * theS3;
	m_COEF->uK1  = -8.86 * theS1 + 0.68 * theS2 - 0.07 * theS3;
	m_COEF->uJ1  = -12.94 * theS1 + 1.34 * theS2 - 0.19 * theS3;
	m_COEF->uOO1 = -36.68 * theS1 + 4.02 * theS2 - 0.57 * theS3;
	m_COEF->uM2  = -2.14 * theS1 + 0 * theS2 + 0 * theS3;
	m_COEF->uK2  = -17.74 * theS1 + 0.68 * theS2 - 0.04 * theS3;
    
	double	theCu = 1 - 0.2505 * cos(m_COEF->P * 2 * m_COEF->DR) - 0.1102 *
    cos((m_COEF->P * 2 - m_COEF->N) * m_COEF->DR) - 0.0156 *
    cos((m_COEF->P * 2 - m_COEF->N * 2) * m_COEF->DR) - 0.037 *
    cos(m_COEF->N * m_COEF->DR);
	double	theSu = -0.2505 * sin(m_COEF->P * 2 * m_COEF->DR) - 0.1102 *
    sin((m_COEF->P * 2 - m_COEF->N) * m_COEF->DR) - 0.0156 *
    sin((m_COEF->P * 2 - m_COEF->N * 2) * m_COEF->DR) - 0.037 *
    sin(m_COEF->N * m_COEF->DR);
	m_COEF->uL2 = [self FNATN2:theSu C:theCu];
	m_COEF->fL2 = theSu / sin(m_COEF->uL2 * m_COEF->DR);
    
	theCu = 2 * cos(m_COEF->P * m_COEF->DR) + 0.4 *
    cos((m_COEF->P - m_COEF->N) * m_COEF->DR);
	theSu = sin(m_COEF->P * m_COEF->DR) + 0.2 *
    cos((m_COEF->P - m_COEF->N) * m_COEF->DR);
	m_COEF->uM1  = [self FNATN2:theSu C:theCu];
	m_COEF->fM1  = theCu / cos(m_COEF->uM1 * m_COEF->DR);
    
	double	theN1 = cos(m_COEF->N * 1 * m_COEF->DR);
	double	theN2 = cos(m_COEF->N * 2 * m_COEF->DR);
	double	theN3 = cos(m_COEF->N * 3 * m_COEF->DR);
    
	m_COEF->fMm  = 1 - 0.13 * theN1 + 0.0013 * theN2 + 0 * theN3;
	m_COEF->fMf  = 1.0429 + 0.4135 * theN1 - 0.004 * theN2 + 0 * theN3;
	m_COEF->fO1  = 1.0089 + 0.1871 * theN1 - 0.0147 * theN2 + 0.0014 * theN3;
	m_COEF->fK1  = 1.006 + 0.115 * theN1 - 0.0088 * theN2 + 0.0006 * theN3;
	m_COEF->fJ1  = 1.0129 + 0.1676 * theN1 - 0.017 * theN2 + 0.0016 * theN3;
	m_COEF->fOO1 = 1.1027 + 0.6504 * theN1 + 0.0317 * theN2 - 0.0014 * theN3;
	m_COEF->fM2  = 1.0004 - 0.0373 * theN1 + 0.0002 * theN2 + 0 * theN3;
	m_COEF->fK2  = 1.0241 + 0.2863 * theN1 + 0.0083 * theN2 - 0.0015 * theN3;
}
- (void)ArgumentV {
	m_COEF->V[0]  = [self FNV:0 BB:1 CC:0 DD:0];		// Sa
	m_COEF->V[1]  = [self FNV:0 BB:2 CC:0 DD:0];		// Ssa
	m_COEF->V[2]  = [self FNV:1 BB:0 CC:-1 DD:0];		// Mm
	m_COEF->V[3]  = [self FNV:2 BB:-2 CC:0 DD:0];		// MSf
	m_COEF->V[4]  = [self FNV:2 BB:0 CC:0 DD:0];		// Mf
	m_COEF->V[5]  = [self FNV:-3 BB:1 CC:1 DD:270];		// Q1
	m_COEF->V[6]  = [self FNV:-3 BB:3 CC:-1 DD:270];	// Rho1
	m_COEF->V[7]  = [self FNV:-2 BB:1 CC:0 DD:270];		// O1
	m_COEF->V[8]  = [self FNV:-2 BB:3 CC:0 DD:-270];	// MP1
	m_COEF->V[9]  = [self FNV:-1 BB:1 CC:0 DD:90];		// M1
	m_COEF->V[10] = [self FNV:0 BB:-2 CC:0 DD:193];		// Pi1    H4
	m_COEF->V[11] = [self FNV:0 BB:-1 CC:0 DD:270];		// P1
	m_COEF->V[12] = [self FNV:0 BB:0 CC:0 DD:180];		// S1
	m_COEF->V[13] = [self FNV:0 BB:1 CC:0 DD:90];		// K1
	m_COEF->V[14] = [self FNV:0 BB:2 CC:0 DD:168];		// Psi1
	m_COEF->V[15] = [self FNV:0 BB:3 CC:0 DD:90];		// Phi1
	m_COEF->V[16] = [self FNV:1 BB:1 CC:-1 DD:90];		// J1
	m_COEF->V[17] = [self FNV:2 BB:-1 CC:0 DD:90];		// SO1     H4
	m_COEF->V[18] = [self FNV:2 BB:1 CC:0 DD:90];		// OO1
	m_COEF->V[19] = [self FNV:-4 BB:2 CC:2 DD:0];		// 2N2
	m_COEF->V[20] = [self FNV:-4 BB:4 CC:0 DD:0];		// Mu2
	m_COEF->V[21] = [self FNV:-3 BB:2 CC:1 DD:0];		// N2
	m_COEF->V[22] = [self FNV:-3 BB:4 CC:-1 DD:0];		// Nu2
	m_COEF->V[23] = [self FNV:-2 BB:0 CC:0 DD:180];		// OP2
	m_COEF->V[24] = [self FNV:-2 BB:2 CC:0 DD:0];		// M2
	m_COEF->V[25] = [self FNV:-1 BB:0 CC:1 DD:180];		// Lam2
	m_COEF->V[26] = [self FNV:-1 BB:2 CC:-1 DD:180];	// L2
	m_COEF->V[27] = [self FNV:0 BB:-1 CC:0 DD:282];		// T2
	m_COEF->V[28] = [self FNV:0 BB:0 CC:0 DD:0];		// S2
	m_COEF->V[29] = [self FNV:0 BB:1 CC:0 DD:258];		// R2
	m_COEF->V[30] = [self FNV:0 BB:2 CC:0 DD:0];		// K2
	m_COEF->V[31] = [self FNV:2 BB:-2 CC:0 DD:0];		// 2SM2
	m_COEF->V[32] = [self FNV:-4 BB:3 CC:0 DD:270];		// MO3
	m_COEF->V[33] = [self FNV:-3 BB:3 CC:0 DD:180];		// M3
	m_COEF->V[34] = [self FNV:-2 BB:3 CC:0 DD:90];		// MK3
	m_COEF->V[35] = [self FNV:0 BB:1 CC:0 DD:90];		// SK3
	m_COEF->V[36] = [self FNV:-4 BB:4 CC:0 DD:0];		// M4
	m_COEF->V[37] = [self FNV:-2 BB:2 CC:0 DD:0];		// MS4
	m_COEF->V[38] = [self FNV:-6 BB:6 CC:0 DD:0];		// M6
	m_COEF->V[39] = [self FNV:-4 BB:4 CC:0 DD:0];		// 2MS6
    for (int i = 0;i<40;i++)	 {
        m_COEF->V[i] = [TideTool FNRdouble:m_COEF->V[i]];
    }
}
- (double)FNV:(double)A BB:(double)B CC:(double)C DD:(double)D {
    return (m_COEF->S * A + m_COEF->H * B + m_COEF->P * C + D);
}
- (void)ArgumentU {
	m_COEF->U[0] = 0;						// Sa
	m_COEF->U[1] = 0;						// Ssa
	m_COEF->U[2] = m_COEF->uMm;				// Mm
	m_COEF->U[3] = -m_COEF->uM2;			// MSf
	m_COEF->U[4] = m_COEF->uMf;				// Mf
	m_COEF->U[5] = m_COEF->uO1;				// Q1
	m_COEF->U[6] = m_COEF->uO1;				// Rho1
	m_COEF->U[7] = m_COEF->uO1;				// O1
	m_COEF->U[8] = m_COEF->uM2;				// MP1
	m_COEF->U[9]  = m_COEF->uM1;			// M1
	m_COEF->U[10] = 0 ;						// Pi1
	m_COEF->U[11] = 0 ;						// P1
	m_COEF->U[12] = 0 ;						// S1
	m_COEF->U[13] = m_COEF->uK1;			// K1
	m_COEF->U[14] = 0 ;						// Psi1
	m_COEF->U[15] = 0 ;						// Phi1
	m_COEF->U[16] = m_COEF->uJ1;			// J1
	m_COEF->U[17] = m_COEF->uJ1;			// SO1
	m_COEF->U[18] = m_COEF->uOO1;			// OO1
	m_COEF->U[19] = m_COEF->uM2;			// 2N2
	m_COEF->U[20] = m_COEF->uM2;			// Mu2
	m_COEF->U[21] = m_COEF->uM2;			// N2
	m_COEF->U[22] = m_COEF->uM2;			// Nu2
	m_COEF->U[23] = m_COEF->uO1;			// OP2
	m_COEF->U[24] = m_COEF->uM2;			// M2
	m_COEF->U[25] = m_COEF->uM2;			// Lam2
	m_COEF->U[26] = m_COEF->uL2;			// L2
	m_COEF->U[27] = 0;						// T2
	m_COEF->U[28] = 0;						// S2
	m_COEF->U[29] = 0;						// R2
	m_COEF->U[30] = m_COEF->uK2;			// K2
	m_COEF->U[31] = -m_COEF->uM2;			// 2SM2
	m_COEF->U[32] = m_COEF->uM2 + m_COEF->uO1;// MO3
	m_COEF->U[33] = m_COEF->uM2 * 1.5;		// M3
	m_COEF->U[34] = m_COEF->uM2 + m_COEF->uK1;// MK3
	m_COEF->U[35] = m_COEF->uK1;			// SK3
	m_COEF->U[36] = m_COEF->uM2 * 2;		// M4
	m_COEF->U[37] = m_COEF->uM2;			// MS4
	m_COEF->U[38] = m_COEF->uM2 * 3;		// M6
	m_COEF->U[39] = m_COEF->uM2 * 2;		// 2MS6    
}
- (void)CoefficF {
	m_COEF->F[0]  = 1;						// Sa
	m_COEF->F[1]  = 1;						// Ssa
	m_COEF->F[2]  = m_COEF->fMm;			// Mm
	m_COEF->F[3]  = m_COEF->fM2;			// MSf
	m_COEF->F[4]  = m_COEF->fMf;			// Mf
	m_COEF->F[5]  = m_COEF->fO1;			// Q1
	m_COEF->F[6]  = m_COEF->fO1;			// Rho1
	m_COEF->F[7]  = m_COEF->fO1;			// O1
	m_COEF->F[8]  = m_COEF->fM2;			// MP1
	m_COEF->F[9]  = m_COEF->fM1;			// M1
	m_COEF->F[10] = 1;						// Pi1
	m_COEF->F[11] = 1;						// P1
	m_COEF->F[12] = 1;						// S1
	m_COEF->F[13] = m_COEF->fK1;			// K1
	m_COEF->F[14] = 1;						// Psi1
	m_COEF->F[15] = 1;						// Phi1
	m_COEF->F[16] = m_COEF->fJ1;			// J1
	m_COEF->F[17] = m_COEF->fJ1;			// SO1
	m_COEF->F[18] = m_COEF->fOO1;			// OO1
	m_COEF->F[19] = m_COEF->fM2;			// 2N2
	m_COEF->F[20] = m_COEF->fM2;			// Mu2
	m_COEF->F[21] = m_COEF->fM2;			// N2
	m_COEF->F[22] = m_COEF->fM2;			// Nu2
	m_COEF->F[23] = m_COEF->fO1;			// OP2
	m_COEF->F[24] = m_COEF->fM2;			// M2
	m_COEF->F[25] = m_COEF->fM2;			// Lam2
	m_COEF->F[26] = m_COEF->fL2;			// L2
	m_COEF->F[27] = 1;						// T2
	m_COEF->F[28] = 1;						// S2
	m_COEF->F[29] = 1;						// R2
	m_COEF->F[30] = m_COEF->fK2;			// K2
	m_COEF->F[31] = m_COEF->fM2;			// 2SM2
	m_COEF->F[32] = m_COEF->fM2 * m_COEF->fO1;// MO3
	m_COEF->F[33] = pow(m_COEF->fM2,1.5);	// M3
	m_COEF->F[34] = m_COEF->fM2 * m_COEF->fK1;// MK3
	m_COEF->F[35] = m_COEF->fK1;			// SK3
	m_COEF->F[36] = pow(m_COEF->fM2,2);		// M4
	m_COEF->F[37] = m_COEF->fM2;			// MS4
	m_COEF->F[38] = pow(m_COEF->fM2,3);		// M6
	m_COEF->F[39] = pow(m_COEF->fM2,2);		// 2MS6    
}

// 度分表示形式（dd.mm）の角度を度の単位に直す
- (double)FNDG:(double)X {
    return ((int)(X) + (X - (int)(X)) * 10 / 6);
}

// 角度を 0 から 360 の範囲に丸める
- (double)FNRR:(double)X {
    int		W1 = floor(X / (m_COEF->PI * 2));
    double	W2 = W1 * (m_COEF->PI * 2);
    return (X - W2);
}

// 角度を ｰ180 から +180 の範囲に丸める
- (double)FNR2R:(double)X {
    // (X - INT((X + TideTool::Sgn(X) * m_COEF->PI) / (m_COEF->PI * 2)) * (m_COEF->PI * 2))
    return (X - (int)((X + [TideTool SGNdouble:X] * m_COEF->PI) / (m_COEF->PI * 2)) * (m_COEF->PI * 2));
}

// arctangent 出力の単位は度
- (double)FNATN2:(double)S C:(double)C {
    double	W1 = (C < 0 ? -1 : 0);
    double	W2 = ((C > 0 && S <= 0) ? -1 : 0);
    return ((atan(S / C) - m_COEF->PI * W1 - 2 * m_COEF->PI * W2) * m_COEF->RD);
    
}

// 角度を 0 から 360 の範囲に丸める
// arc cosine
- (double)FNACN:(double)X {
    return (90 - atan(X / sqrt(-X * X + 1)) * m_COEF->RD);
}

// arc sine
- (double)FNASN:(double)X {
    return (atan(X / sqrt(-X * X + 1)) * m_COEF->RD);
}

// 緯度経度から日本かどうか判定
- (bool)isNippon:(double)inLat Lon:(double)inLon
{
    bool	result = FALSE;
    // 2004.12.02 ロジック変更（コンバートミスでタイムゾーンが変だった）
    // 北海道の「浦河」「紋別」「網走」「花咲」「釧路」の日照時間が１時間遅れてた
    if (inLat > 24)	{
        if (122 <= inLon && inLon < 128)	{
            if (inLat < 32)		result = TRUE;
        }
        else if (128 <= inLon && inLon < 131)	{
            if (inLat < 35)		result = TRUE;
        }
        else if (131 <= inLon && inLon < 138)	{
            if (inLat < 38)		result = TRUE;
        }
        else if (138 <= inLon && inLon < 148)	{
            if (inLat < 46)		result = TRUE;
        }
    }
    return result;
}

// 各種ゲッター
- (double)TD2_lat {return m_TD2->lat_save;}
- (double)TD2_lon {return m_TD2->lon_save;}
- (NSString*)TD2_NP {return m_TD2->NP;}
- (double)TD2_TC0 {return m_TD2->TC0;}
- (NSString*)COEF_Sio {return m_COEF->Sio;}
- (double)COEF_graphscale {return m_COEF->graphscale;}
- (double)COEF_Range {return m_COEF->Range;}
- (double)SunRise {return [TideTool FNHH:(m_COEF->SEvent[2])] * 60 + [TideTool FNMM:(m_COEF->SEvent[2])];}
- (double)SunSet  {return [TideTool FNHH:(m_COEF->SEvent[4])] * 60 + [TideTool FNMM:(m_COEF->SEvent[4])];}
- (double)COEF_SMD12 {return m_COEF->SMD12;}
- (double)COEF_DR {return m_COEF->DR;}
- (NSArray*)COEF_yPosArray {
    NSMutableArray* array = [NSMutableArray array];
    for (int i=0; i<73; i++) {
        [array addObject: [NSNumber numberWithDouble:m_COEF->yPos[i]]];
    }
    return array;
}
- (NSArray*)COEF_hiAndLowArray {
    NSMutableArray* array = [NSMutableArray array];
    bool isHi = YES;
    if (m_COEF->ChoTC[0] < m_COEF->ChoTC[1])    isHi = NO;
    for (int i=0;i<5;i++)    {
        if (m_COEF->ChoT[i] != 0)    {
            int    HH = (int)(m_COEF->ChoT[i]);
            int    MM = round((m_COEF->ChoT[i] - HH) * 60);
            [array addObject:[NSString stringWithFormat:@"%@,%d,%d", (isHi ? @"H" : @"L"), (int)(HH*60+MM), (int)round(m_COEF->ChoTC[i])]];
            isHi = !isHi;
        }
    }
    return array;
}
- (NSArray*)COEF_SEventArray {
    NSMutableArray* array = [NSMutableArray array];
    for (int i=0; i<7; i++) {
        double minute = [TideTool FNHH:(m_COEF->SEvent[i])] * 60 + [TideTool FNMM:(m_COEF->SEvent[i])];
        [array addObject: [NSNumber numberWithDouble:minute]];
    }
    return array;
}
- (double)COEF_AGE {return m_COEF->AGE;}
- (double)COEF_ILUM {return m_COEF->ILUM;}
- (NSArray*)COEF_MEventArray {
    NSMutableArray* array = [NSMutableArray array];
    double minute = m_COEF->MoonR == 99 ? -1 : [TideTool FNHH:(m_COEF->MoonR)] * 60 + [TideTool FNMM:(m_COEF->MoonR)];
    [array addObject: [NSNumber numberWithDouble:minute]];
    minute = m_COEF->MMP == 99 ? -1 : [TideTool FNHH:(m_COEF->MMP)] * 60 + [TideTool FNMM:(m_COEF->MMP)];
    [array addObject: [NSNumber numberWithDouble:minute]];
    minute = m_COEF->MoonS == 99 ? -1 : [TideTool FNHH:(m_COEF->MoonS)] * 60 + [TideTool FNMM:(m_COEF->MoonS)];
    [array addObject: [NSNumber numberWithDouble:minute]];
    return array;
}
- (NSArray*)TD2_TInfoArray {
    NSMutableArray* array = [NSMutableArray array];
    double num = m_TD2->HR[7] + m_TD2->HR[13] + m_TD2->HR[24] + m_TD2->HR[28] + m_TD2->TC0;
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = (m_TD2->HR[24] + m_TD2->HR[28]) + m_TD2->TC0;
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = (m_TD2->HR[24] - m_TD2->HR[28]) + m_TD2->TC0;
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = m_TD2->TC0;
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = [TideTool FNRdouble:(m_TD2->PL[28] - m_TD2->PL[24])] / 24.5;
    [array addObject: [NSString stringWithFormat : @"%2.1f", num]];
    num = m_TD2->PL[24] / 29;
    [array addObject: [NSString stringWithFormat : @"%2.1f", num]];
    num = 2 * (m_TD2->HR[24] + m_TD2->HR[28]);
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = 2 * (m_TD2->HR[24] - m_TD2->HR[28]);
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    num = 2 * m_TD2->HR[24];
    [array addObject: [NSString stringWithFormat : @"%3.1f", num]];
    return array;
}

@end
