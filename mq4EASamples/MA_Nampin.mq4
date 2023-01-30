//------------------------------------------------------------------+
// jisakuEA.mq4
// Copyright 2019, Hazu
//------------------------------------------------------------------+
#property copyright "Copyright 2019, Hazu" // 作成者名
#property link "https://hazu-hobby.net/ea-source-code/#i-9" // Webサイトリンク
#property version "4.0" // バージョン
#property strict // 厳格なコンパイルモード
#property description "自作EA" // EA説明文
#define MAGICMA 20191007 // EA識別用マジックナンバー
#define DEBUG //バックテスト用
#ifdef DEBUG
int prevsec;
int BScnt = 0;

bool ForBackTest(int Timerseconds)
{
    if (Seconds() != prevsec)
    BScnt ++;
    prevsec = Seconds();
    if (BScnt >= Timerseconds){
        BScnt = 0;
        return(true);
    }
    return(false);
}
#endif

// OnInit(初期化)イベント
int OnInit() {
    EventSetTimer(60);
    return(INIT_SUCCEEDED);
}

// OnDeinit(アンロード)イベント
void OnDeinit(const int reason) {
    EventKillTimer();
}
//バックテスト用
void OnTick(){
    #ifdef DEBUG
    if (ForBackTest(60))
    OnTimer();
    #endif
}

// OnTick(tick受信)イベント
void OnTimer(){
    if ( IsTradeAllowed() == false ) {
    return;
    }
    main(); //Main logic
}

//------------------------------------------------------------------------------------
// 0. main : メインロジック
//------------------------------------------------------------------------------------
input int Ma1 = 1;                    // 現在値
input int Ma2 = 7;                    // 7区間移動平均
input int Ma3 = 25;                  // 25区間移動平均
input int time = 15;                  // 時間足指定
input string rcur = "USDJPY";   //通貨ペア指定
double M0[5],M1[5],U1[5],L1[5],M2[5],M3[5];
int result;
bool goflg;
void main(){
    getprm();
    check();
    position();
    return;
}

//------------------------------------------------------------------------------------
// 1. getprm : パラメータ取得
//------------------------------------------------------------------------------------
void getprm(){
    for(int i=4; i>=0; i=i-1){
        M0[i] = iMA(rcur,time, Ma1, 0, 0, 0, i);
        M1[i] = iMA(rcur,time, Ma2, 0, 0, 0, i);
        U1[i] = iBands(rcur,time,Ma2,1.5,0,PRICE_CLOSE,1,i);
        L1[i] = iBands(rcur,time,Ma2,1.5,0,PRICE_CLOSE,2,i);
        M2[i] = iMA(rcur,time,Ma3, 0, 0, 0, i);
        M3[i] = iMA(rcur,time,50, 0, 0, 0, i);
    }
}

//------------------------------------------------------------------------------------
// 2. check : 取引条件確認
//------------------------------------------------------------------------------------
void check(){
    //条件処理
    for(int i=4; i>=0; i=i-1){
        if(M1[i]<=M2[i]){
            result = -1;    //売り判定
            if(M0[i]>=U1[i])
                goflg = true;   //売買指示
            else
                goflg = false;
        }
        else if(M1[i]>=M2[i]){
            result = 1;
            if(M0[i]<=L1[i])
                goflg = true;   //買い判定
            else
                goflg = false;  //売買指示
            }
        else{
            result = 0;
            goflg = false;
        }
    }
}

//------------------------------------------------------------------------------------
// 3. position : ポジション管理
//------------------------------------------------------------------------------------
void position(){
    //ポジション数取得
    int res;
    int tpoji = 0;
    int pojilim = 1; // 最大ポジション
    int torder = OrdersTotal();
    //ポジション数カウント
    for(int i = torder-1; i >= 0; i--){
        res = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if(OrderSymbol()==rcur&&((OrderType()==0&&result==1)||(OrderType()==1&&result==-1)))
            tpoji += 1;
        }
        //ポジション構築
        if(tpoji<pojilim&&result!=0&&goflg)
            ordersend();
        }
    }
}

//------------------------------------------------------------------------------------
// 4. ordersend : ポジション構築
//------------------------------------------------------------------------------------
void ordersend(){
    int res = 0;
    double BID = MarketInfo(rcur,MODE_BID);
    double ASK = MarketInfo(rcur,MODE_ASK);
    double PIP = MarketInfo(rcur,MODE_SPREAD);
    //売り指示
    if(result==-1&&PIP<=100){
        res = OrderSend(rcur,OP_SELL,0.5,BID,100,ASK+0.2,ASK-0.4,"Short",MAGICMA,0,clrRed);
        Sleep(3000);
    }
    //買い指示
    else if(result==1&&PIP<=100){
        res = OrderSend(rcur,OP_BUY,0.5,ASK,100,BID-0.2,BID+0.4,"Long",MAGICMA,0,clrRed);
        Sleep(3000);
    }
}

// memo ------------------------------
// 通貨ペア：ドル円
// 時間足：M15
// モデル：全ティック
// スプレッド： 5
// 期間：20014/4/1-2020/4/22
// 結果：100万円⇒210万円