import fs from 'node:fs/promises';
import { SpreadsheetFile, Workbook } from '@oai/artifact-tool';

const outDir = 'C:/Users/wchkl/Documents/Codex/2026-08-12/https-chatgpt-com-share-6a7b9aee-e840-2/outputs';
await fs.mkdir(outDir, {recursive:true});

const base = [
['IMM-001','基礎','T細胞','T','精準追擊、連擊','單體殺傷區','適應／穿透／持續輸出','細胞毒刃','集中處決','適應型'],
['IMM-002','基礎','B細胞','B','採集抗原、支援','抗體生產核心','生產／記憶／增益','抗體生成','記憶增幅','生產型'],
['IMM-003','基礎','巨噬細胞','M','吞噬、推擠、救援','阻擋與吞噬區','承傷／控制／回收','吞噬回收','固定消化爐','經濟／坦克型'],
['IMM-004','基礎','NK細胞','N','高速截擊精英','低血量處決區','突襲／斬殺／威脅優先','快速截擊','靜默獵殺','刺殺型'],
['IMM-005','基礎','抗體構造體','A','浮游追蹤彈群','遠程導引炮台','標記／穿透／中繼','弱點標記','導引炮台','遠程型'],
['IMM-006','基礎','樹突細胞','D','偵察感染區','情報與增幅信標','掃描／指揮／揭露','抗原掃描','免疫信標','支援型']
];

const pair = [
['IMM-007','雙融合','記憶獵手','T+B','長戰適應','B記錄菌株；T對重複敵人累積反制傷害','記憶標記','學習追擊','固定記憶陣','長期反制','適應型','T←B'],
['IMM-008','雙融合','吞噬突擊','T+M','前線反擊','巨噬承傷聚怪；T將吸收量轉成反擊','吞噬反擊','衝撞吞噬','吞噬壁壘','反擊爆發','坦克型','M←T'],
['IMM-009','雙融合','細胞毒刃','T+N','連續處決','T削弱防禦；NK接續斬殺並刷新下一目標','毒刃連鎖','追擊斬殺','處決陣列','連殺重置','攻擊型','T←N'],
['IMM-010','雙融合','精準抗體','T+A','裝甲穿透','T鎖定弱點；抗體遠距穿透部位','弱點穿透','精準集火','導引炮台','穿甲爆發','遠程型','A←T'],
['IMM-011','雙融合','免疫指揮','T+D','戰術換防','樹突傳遞指令；T快速重新分配火力','戰術中繼','快速換防','指揮信標','全隊重定向','支援型','D←T'],
['IMM-012','雙融合','抗原處理','B+M','資源處理','巨噬回收殘骸；B轉換成抗原樣本','抗原回收','吞噬採樣','處理中樞','資源增幅','經濟型','M←B'],
['IMM-013','雙融合','標記處決','B+N','延遲爆破','B植入標記；NK擊殺時引發連鎖爆破','爆破標記','標記突進','處決信標','多重爆破','攻擊型','B←N'],
['IMM-014','雙融合','抗體風暴','B+A','飽和清場','B大量生產；抗體形成追蹤彈幕','抗體生產','移動播種','風暴炮台','全域彈幕','攻擊型','B←A'],
['IMM-015','雙融合','抗原呈現','B+D','情報反制','分析敵方突變並把反制資料分享全隊','弱點共享','採集呈現','呈現信標','反制循環','支援型','D←B'],
['IMM-016','雙融合','感染清除','M+N','區域淨化','NK殺敵；巨噬清理殘骸並阻止再感染','殘骸清除','突襲清理','淨化壁壘','感染重置','控制型','N←M'],
['IMM-017','雙融合','免疫壁壘','M+A','投射物防禦','巨噬阻擋；抗體攔截遠程攻擊並生成護盾','吞噬護盾','推進護衛','護盾壁壘','無菌領域','防禦型','M←A'],
['IMM-018','雙融合','抗原中樞','M+D','生物質轉化','生物質轉換成治療、助手及淨化進度','生物質轉化','吞噬供料','中樞反應爐','再生脈衝','經濟型','D←M'],
['IMM-019','雙融合','抗體追獵','N+A','全圖防漏','抗體追蹤逃敵；NK跨區截擊','追蹤鎖定','獵殺逃敵','追獵炮台','全圖處決','刺殺型','N←A'],
['IMM-020','雙融合','獵殺信標','N+D','Boss打斷','樹突標記弱點；NK在信標間突進','信標鎖殺','信標突進','鎖殺陣列','沉默打斷','控制型','N←D'],
['IMM-021','雙融合','免疫網絡','A+D','跨區中繼','樹突建立節點；抗體跨區傳遞攻擊和增益','節點連線','節點穿梭','網絡炮台','全域中繼','支援型','A←D']
];

const triple = [
['IMM-022','三融合','適應免疫核心','T+B+A','突變反制','分析主導菌株，動態改變抗體傷害特性','適應彈幕','採集學習','固定適應核心','抗性重編程','攻擊／適應','T←A+B'],
['IMM-023','三融合','全域截擊中樞','T+N+D','多戰區救火','偵測前線缺口並投射T／NK快速截擊','截擊中繼','跨區截擊','全域信標','戰區同步','支援／控制','D←N+T'],
['IMM-024','三融合','組織防衛聖域','M+A+D','永久陣地','建立健康安全區，阻止感染重新擴張','聖域建立','護送建點','聖域炮台','無菌穹頂','防禦／控制','A←M+D'],
['IMM-025','三融合','組織再生巢','B+M+D','戰場修復','將抗原與生物質轉化成修復地形與部署點','再生合成','採集修復','再生中樞','器官修復','支援／經濟','B←M+D'],
['IMM-026','三融合','抗體獵殺蜂群','B+N+A','多精英追獵','分出多支自主獵殺隊同時鎖定精英','蜂群鎖定','蜂群追獵','獵殺蜂巢','多重處決','攻擊／刺殺','N←A+B'],
['IMM-027','三融合','凋亡反應爐','T+M+N','高風險爆發','儲存吞噬能量後釋放Boss破防爆發','凋亡蓄能','近線蓄能','反應爐壁壘','爆發凋亡','攻擊／坦克','M←N+T']
];

const apex = [
['IMM-028','全六融合','全域免疫核心・IMMUNE PRIME','T+B+M+N+A+D','終局戰場狀態','連接健康區、揭露最終感染核心並投射直控化身','全域覺醒','六家族同步','統合核心','終局淨化','終局型','Unified Rig'],
['IMM-029','隱藏Apex','長期免疫記憶庫','T+B','永久反制','保留一種菌株的反制資料至後續波次','記憶庫寫入','標記保留','記憶中樞','跨波次反制','適應型','記憶獵手分支'],
['IMM-030','隱藏Apex','無菌聖域','M+A','永久防線','放棄部分攻擊，建立近乎不可突破的淨化領域','聖域展開','護盾推進','無菌穹頂','區域重置','防禦型','免疫壁壘分支'],
['IMM-031','隱藏Apex','靜默獵殺網','N+D','全圖控制','中斷Boss技能、突變傳播及敵方增援訊號','靜默協議','信標突進','沉默網絡','全域封鎖','控制型','獵殺信標分支']
];

const chars = [...base,...pair,...triple,...apex];
const characterRows = chars.map((r) => {
  if (r[1] === '基礎') {
    return [r[0],r[1],r[2],r[3],r[3],r[6],r[4],r[5],r[6],r[7],r[8],'家族Apex：'+r[8],r[9],'可養成'];
  }
  return [r[0],r[1],r[2],r[3],r[11],r[4],r[7],r[8],r[5],r[6],r[8],r[9],r[10],r[1]==='隱藏Apex'?'共用資產分支':r[1]==='全六融合'?'終局身份':'固定融合身份'];
});
const skillRows = chars.map((r) => {
  if (r[1] === '基礎') return [r[0],r[2],r[1],r[3],r[6],r[6],r[7],r[4],r[8],r[5],'家族Apex：'+r[8],r[9],'基礎雙形態'];
  return [r[0],r[2],r[1],r[3],r[4],r[5],r[6],r[7],r[8],r[8],r[9],r[10],'融合資產：'+r[11]];
});

const fam = ['T','B','M','N','A','D'];
const cn = {T:'T細胞',B:'B細胞',M:'巨噬細胞',N:'NK細胞',A:'抗體構造體',D:'樹突細胞'};
const named = new Map();
for (const r of [...pair,...triple,...apex]) named.set(r[3],r[2]);
const rel = [];
function choose(start,k,a=[]){ if(a.length===k){rel.push(a.join('+'));return;} for(let i=start;i<=fam.length-(k-a.length);i++) choose(i+1,k,[...a,fam[i]]); }
for(let k=2;k<=6;k++) choose(0,k);
const relationRows = rel.map((x,i)=>{
  const n=x.split('+').length, name=named.get(x)||'', physical=name && (n===2||n===3||n===6) ? '是':'否';
  const status=name ? (n===2?'★1被動／★3固定融合':n===3?'★5指定融合':n===6?'★5終局融合':'Apex分支') : '只疊加雙家族被動';
  return ['R-'+String(i+1).padStart(2,'0'),n,x,x.split('+').map(y=>cn[y]).join('＋'),name,name?'是':'否',physical,status];
});
relationRows.push(['A-01','Apex','T+B','T細胞＋B細胞','長期免疫記憶庫','是','共用模型','★5隱藏分支']);
relationRows.push(['A-02','Apex','M+A','巨噬細胞＋抗體構造體','無菌聖域','是','共用模型','★5隱藏分支']);
relationRows.push(['A-03','Apex','N+D','NK細胞＋樹突細胞','靜默獵殺網','是','共用模型','★5隱藏分支']);

const balanceRows = [
['吞噬技能','普通敵人生命線',25,'%','低於此生命值可吞噬'],
['吞噬技能','大型／精英生命線',15,'%','低血並先破防或失衡'],
['吞噬技能','吞噬冷卻',7,'秒','移動形態主動技能'],
['吞噬技能','初始胃袋容量',10,'生物質','容量滿後需固定消化'],
['吞噬經濟','每批升級點需求',10,'生物質→1共享升級點',''],
['永久材料','普通敵人一度概率',5,'%','只計合資格敵人'],
['永久材料','大型敵人一度概率',15,'%','只計合資格敵人'],
['永久材料','精英敵人一度概率',30,'%','只計合資格敵人'],
['永久材料','一度保底次數',10,'次合資格消化',''],
['永久材料','每局吞噬一度上限',3,'個','其他來源另計'],
['永久材料','目標平均產出','1–2','個／局',''],
['反濫用','吞噬來源總供應比例','25–30%','永久材料總供應',''],
['星級','雙融合最低星級','★3','','雙方均需固定'],
['星級','三融合最低星級','★5','','只限指定配方'],
['星級','全六融合最低星級','★5','','特殊終局條件']
];

const enemyRows = [
['E-001','病毒族','基本病毒','普通',1,'L01–L06','漂浮','接觸感染','感染脈衝','T細胞集火／抗體標記',60,1.0,1,'生命低於25%可吞噬'],
['E-002','病毒族','裂變病毒','普通',2,'L01–L06','彈跳','死亡分裂','裂變芽體','優先擊殺分裂源',75,0.9,1,'裂變後代不重複產材料'],
['E-003','病毒族','感染病毒','特殊',3,'L01–L06','漂浮','感染範圍','感染雲霧','樹突揭露／遠程清除',110,0.8,1,'低血量可吞噬'],
['E-004','病毒族','群體病毒','特殊',4,'L01–L05','群聚','數量壓制','群體增殖','範圍傷害／抗體風暴',45,1.2,1,'群體共享生物質額度'],
['E-005','病毒族','飛行病毒','特殊',5,'L01–L06','飛行','俯衝感染','空中突襲','抗體追獵／NK截擊',90,1.5,1,'需標記或空中攻擊'],
['E-006','病毒族','突變病毒','精英',7,'L01–L06','漂浮','適應攻擊','定期變異','樹突掃描後再集火',220,0.9,8,'需破防及低於10%'],
['E-007','細菌族','裝甲細菌','重型',3,'L01–L04','爬行','高防撞擊','裝甲外殼','T穿透／抗體弱點',300,0.55,3,'先破防才可吞噬'],
['E-008','細菌族','再生細菌','特殊',9,'L02–L06','爬行','近距咬擊','生命再生','NK處決／感染清除',180,0.65,3,'再生時不可吞噬'],
['E-009','細菌族','細菌群落','精英',11,'L02–L06','群聚','包圍感染','群落增殖','巨噬吞噬核心',420,0.45,8,'核心死亡後群落停止'],
['E-010','細菌族','生物膜細菌','精英',13,'L02–L06','黏附','減速黏液','生物膜護盾','抗體穿透／樹突標記',360,0.35,8,'護盾破裂後可吞噬'],
['E-011','寄生體族','吸血寄生體','特殊',10,'L02–L06','跳躍','吸血附著','生命偷取','NK優先斬殺',160,1.1,3,'附著中不可吞噬'],
['E-012','寄生體族','鑽地寄生體','特殊',17,'L03–L06','鑽地','地下突襲','短暫隱形','樹突揭露／範圍控制',200,0.8,3,'現身或失衡後可吞噬'],
['E-013','寄生體族','快速寄生體','特殊',18,'L03–L06','高速','突進撕咬','連續突進','T減速／抗體追蹤',140,1.8,3,'先造成硬直'],
['E-014','寄生體族','模仿寄生體','精英',20,'L03–L06','模仿','複製炮塔效果','錯誤模仿','樹突辨識真偽',380,0.7,8,'解除模仿後才可吞噬'],
['E-015','變異細胞族','變異細胞 I','精英',19,'L03–L06','爬行','突變攻擊','初階進化','T／NK快速處決',260,0.75,8,'破壞核心可中止進化'],
['E-016','變異細胞族','變異細胞 II','精英',25,'L04–L06','爬行','強化攻擊','高生命與護甲','抗體穿透／巨噬阻擋',460,0.65,8,'需先拆除護甲'],
['E-017','變異細胞族','變異細胞 III','精英',29,'L04–L06','爬行','特殊技能','核心爆裂','樹突預警／NK打斷',620,0.6,8,'技能準備時可打斷'],
['E-018','變異細胞族','自適應細胞','精英',33,'L05–L06','多形態','反制玩家傷害','根據傷害類型變化','切換攻擊類型',800,0.55,8,'同一類傷害不可連續使用'],
['E-019','Boss','流感核心','Boss',8,'L01','漂浮','召喚病毒群','感染肺泡區域','全家族協同／分區淨化',3000,0.4,0,'不可吞噬本體；殘核可處理'],
['E-020','Boss','腫瘤巨塊','Boss',16,'L02','膨脹','生成阻塞塊','吞噬周圍空間','巨噬控場／T穿透',5200,0.25,0,'階段殘塊可吞噬'],
['E-021','Boss','細菌母巢','Boss',24,'L03','固定巢穴','大量生產細菌','菌膜擴張','抗體風暴／樹突斷鏈',4600,0.15,0,'母巢核心不可直接吞噬'],
['E-022','Boss','寄生女王','Boss',32,'L04','移動','產卵與附著','召喚寄生卵','NK處決／全圖追獵',6000,0.45,0,'卵囊可作吞噬殘骸'],
['E-023','Boss','變異融合體','Boss',40,'L05','多形態','混合技能','階段形態變換','三家族融合／弱點切換',8500,0.5,0,'只可吞噬階段殘核'],
['E-024','Boss','感染本源','Boss',48,'L06','核心固定','扭曲戰場規則','全域感染','IMMUNE PRIME終局工具',12000,0.2,0,'不可吞噬；完成終局淨化']
];

const levelRows = [
['L01','第一區','黏膜入口','初次感染的紅色黏膜通道',1,8,'病毒族／細菌族','學習吞噬、標記及基本固定防守','E-019','初始區域'],
['L02','第二區','血流回廊','高速血流與裝甲細菌通道',9,16,'病毒族／細菌族／寄生體族','移動壓力、再生與生物膜','E-020','完成L01'],
['L03','第三區','淋巴濾站','免疫訊號匯聚的濾站',17,24,'細菌族／寄生體族／變異細胞族','偵察、鑽地、模仿與群落','E-021','完成L02'],
['L04','第四區','發炎病灶','腫脹、狹窄及高感染區',25,32,'病毒族／寄生體族／變異細胞族','持續失守、技能打斷及區域淨化','E-022','完成L03'],
['L05','第五區','腫瘤組織','高密度變異組織與多形態敵人',33,40,'全敵人族群／變異細胞族','反制玩家Build及三家族融合','E-023','完成L04'],
['L06','終局區','感染本源','人體深層感染核心',41,48,'全敵人族群／Boss','全域感染、終局條件及IMMUNE PRIME','E-024','完成L05']
];

const levelPools = {
'L01':['E-001','E-002','E-003','E-004','E-005','E-006','E-007'],
'L02':['E-002','E-003','E-005','E-007','E-008','E-009','E-010','E-011'],
'L03':['E-008','E-009','E-010','E-011','E-012','E-013','E-014','E-015'],
'L04':['E-003','E-006','E-011','E-012','E-013','E-015','E-016','E-017'],
'L05':['E-006','E-009','E-010','E-014','E-015','E-016','E-017','E-018'],
'L06':['E-003','E-005','E-006','E-010','E-014','E-017','E-018']
};
const levelBoss = {'L01':'E-019','L02':'E-020','L03':'E-021','L04':'E-022','L05':'E-023','L06':'E-024'};
const waveRows = [];
let waveId=1;
for (const l of levelRows) {
  const pool=levelPools[l[0]];
  for(let local=1;local<=8;local++){
    const wave=l[4]+local-1;
    const phase=local===1?'教學波':local===8?'Boss波':local===7?'Boss前壓力波':local===5?'精英波':local===6?'高密度波':local===4?'特殊機制波':'混合波';
    const take = local===1?2:local===2?3:local===3?4:local===4?5:local===5?Math.min(6,pool.length):local===6?pool.length:Math.min(pool.length,Math.max(3,pool.length-1));
    const spawn=pool.slice(0,take).join(', ');
    const count=local===1?'6–8':local===2?'8–12':local===3?'10–14':local===4?'12–16':local===5?'2精英＋12–18':local===6?'16–24':local===7?'2精英＋18–26':'Boss＋12–20';
    const boss=local===8?levelBoss[l[0]]:'';
    const rule=local===1?'首次介紹本區敵人':local===2?'增加出生點或移動壓力':local===3?'加入第二敵人家族':local===4?'啟用本區特殊機制':local===5?'至少1個精英或重型':local===6?'感染速度提高20%':local===7?'Boss機制預告':local===8?'Boss＋可吞噬殘核':'';
    waveRows.push(['W-'+String(waveId).padStart(3,'0'),l[0],wave,phase,spawn,count,boss,rule,local===8?'Boss獎勵＋一度來源':'一般波次獎勵']);
    waveId++;
  }
}

const wb=Workbook.create();
const overview=wb.worksheets.add('00_總覽');
const cs=wb.worksheets.add('角色主表');
const ss=wb.worksheets.add('技能資料');
const rs=wb.worksheets.add('組合關係');
const bs=wb.worksheets.add('平衡參數');
const es=wb.worksheets.add('敵人圖鑑');
const ls=wb.worksheets.add('關卡資料');
const ws=wb.worksheets.add('波次生成');
for(const s of [overview,cs,ss,rs,bs,es,ls,ws]) s.showGridLines=false;
const navy='#172A46',blue='#2F6FED',teal='#0F766E',purple='#7C3AED',gold='#C58A1B',light='#E8EEF7',text='#1F2937';
function title(s,range,v,fill=navy){s.getRange(range).merge();s.getRange(range.split(':')[0]).values=[[v]];s.getRange(range).format={fill,font:{bold:true,color:'#FFFFFF',size:16},verticalAlignment:'center'};}
function header(s,range,fill=blue){s.getRange(range).format={fill,font:{bold:true,color:'#FFFFFF'},horizontalAlignment:'center',verticalAlignment:'center',wrapText:true,borders:{preset:'all',style:'thin',color:'#D7E0EF'}};}
function body(s,range){s.getRange(range).format={font:{color:text,size:10},verticalAlignment:'top',wrapText:true,borders:{preset:'inside',style:'thin',color:'#D9E2F0'}};}

title(overview,'A1:H1','IMMUNE｜角色、技能與組合資料集');
overview.getRange('A3:B9').values=[['資料集版本','v0.3'],['專案定位','可愛免疫細胞＋危險人體世界'],['圖鑑身份總數',''],['核心命名身份',''],['隱藏Apex形態',''],['數學上的多家族關係',''],['永久材料／資料用途','一度原質（UI簡稱：一度）／角色、技能、融合、平衡、3D製作']];
overview.getRange('B5').formulas=[["=COUNTA('角色主表'!A4:A34)"]];overview.getRange('B6').formulas=[["=COUNTIF('角色主表'!B4:B34,\"<>隱藏Apex\")"]];overview.getRange('B7').formulas=[["=COUNTIF('角色主表'!B4:B34,\"隱藏Apex\")"]];overview.getRange('B8').formulas=[["=COUNTIF('組合關係'!B4:B63,\">=2\")"]];
overview.getRange('A3:A9').format={fill:light,font:{bold:true,color:navy}};overview.getRange('A3:B9').format.borders={preset:'all',style:'thin',color:'#C9D5E6'};
overview.getRange('A12:H15').values=[['工作表','用途','','','','','',''],['角色主表','6個基礎、15個雙融合、6個三融合、1個全六、3個隱藏Apex','','','','','',''],['技能資料','每個角色身份的屬性、移動技能、固定技能及Apex能力','','','','','',''],['組合關係／平衡參數','完整57種關係及吞噬／一度初版參數','','','','','','']];
overview.getRange('A12:H12').merge(true);header(overview,'A12:H12',teal);overview.getRange('A13:H15').merge(true);body(overview,'A13:H15');

overview.getRange('D17:E20').values=[['Steam產品目標',''],['主線完成時間','4–6 小時'],['完整內容完成時間','15–25 小時'],['定位','短主線＋高重玩價值']];overview.getRange('D17:E17').format={fill:'#C58A1B',font:{bold:true,color:'#FFFFFF'}};overview.getRange('D18:D20').format={fill:'#FFF7E6',font:{bold:true,color:'#7A4E00'}};overview.getRange('D17:E20').format.borders={preset:'all',style:'thin',color:'#E5C98B'};
const ch=['ID','身份類型','名稱','家族／配方','3D主體','核心定位','移動形態','固定形態','核心屬性','主動技能','固定／融合技能','Apex／終極效果','技能樹方向','製作狀態'];
title(cs,'A1:N1','角色主表');cs.getRange('A3:N3').values=[ch];header(cs,'A3:N3');cs.getRange('A4:N34').values=characterRows;body(cs,'A4:N34');cs.freezePanes.freezeRows(3);cs.freezePanes.freezeColumns(3);cs.tables.add('A3:N34',true,'CharacterTable');

const sh=['ID','名稱','身份類型','家族／配方','玩法定位','核心屬性','主動技能','移動形態行為','固定技能','固定形態行為','Apex／終極技能','技能樹方向','資產備註'];
title(ss,'A1:M1','技能資料');ss.getRange('A3:M3').values=[sh];header(ss,'A3:M3',purple);ss.getRange('A4:M34').values=skillRows;body(ss,'A4:M34');ss.freezePanes.freezeRows(3);ss.freezePanes.freezeColumns(2);ss.tables.add('A3:M34',true,'SkillTable');

const rh=['關係ID','家族數','配方代碼','完整家族名稱','命名身份','是否命名','實體融合','解鎖／狀態'];
title(rs,'A1:H1','組合關係');rs.getRange('A3:H3').values=[rh];header(rs,'A3:H3',teal);rs.getRange('A4:H63').values=relationRows;body(rs,'A4:H63');rs.freezePanes.freezeRows(3);rs.freezePanes.freezeColumns(2);rs.tables.add('A3:H63',true,'RelationTable');

const bh=['分類','參數','數值','單位／格式','用途'];
title(bs,'A1:E1','平衡參數');bs.getRange('A3:E3').values=[bh];header(bs,'A3:E3',gold);bs.getRange('A4:E18').values=balanceRows;body(bs,'A4:E18');bs.freezePanes.freezeRows(3);bs.tables.add('A3:E18',true,'BalanceTable');
bs.getRange('A22:E24').values=[['產品目標','數值','單位','用途','狀態'],['主線完成時間','4–6','小時','Steam主線通關目標','已鎖定'],['完整內容完成時間','15–25','小時','含大部分內容與重玩','已鎖定']];bs.getRange('A22:E22').format={fill:'#C58A1B',font:{bold:true,color:'#FFFFFF'}};bs.getRange('A23:A24').format={fill:'#FFF7E6',font:{bold:true,color:'#7A4E00'}};bs.getRange('A22:E24').format.borders={preset:'all',style:'thin',color:'#E5C98B'};
const eh=['敵人ID','族群','名稱','威脅層級','首次波數','出現關卡','移動方式','基本攻擊','特殊技能','建議對策','基礎生命','速度','生物質','吞噬規則'];
title(es,'A1:N1','敵人圖鑑');es.getRange('A3:N3').values=[eh];header(es,'A3:N3','#9B2C2C');es.getRange('A4:N27').values=enemyRows;body(es,'A4:N27');es.freezePanes.freezeRows(3);es.freezePanes.freezeColumns(3);es.tables.add('A3:N27',true,'EnemyTable');
const lh=['關卡ID','章節','區域名稱','人體環境','起始波數','結束波數','主要敵人族群','關卡機制','Boss ID','解鎖條件'];
title(ls,'A1:J1','關卡資料');ls.getRange('A3:J3').values=[lh];header(ls,'A3:J3','#8B5E34');ls.getRange('A4:J9').values=levelRows;body(ls,'A4:J9');ls.freezePanes.freezeRows(3);ls.tables.add('A3:J9',true,'LevelTable');
const wh=['波次ID','關卡ID','全局波數','波次階段','敵人池','數量／壓力','Boss ID','特殊規則','獎勵方向'];
title(ws,'A1:I1','波次生成');ws.getRange('A3:I3').values=[wh];header(ws,'A3:I3','#6B46C1');ws.getRange('A4:I51').values=waveRows;body(ws,'A4:I51');ws.freezePanes.freezeRows(3);ws.freezePanes.freezeColumns(2);ws.tables.add('A3:I51',true,'WaveTable');

overview.getRange('A17:B22').values=[['敵人圖鑑統計',''],['敵人身份數',''],['關卡數',''],['總波數',''],['Boss數',''],['敵人與波次關係','敵人圖鑑→關卡資料→波次生成']];
overview.getRange('B18').formulas=[["=COUNTA('敵人圖鑑'!A4:A27)"]];overview.getRange('B19').formulas=[["=COUNTA('關卡資料'!A4:A9)"]];overview.getRange('B20').formulas=[["=COUNTA('波次生成'!A4:A51)"]];overview.getRange('B21').formulas=[["=COUNTIF('敵人圖鑑'!D4:D27,\"Boss\")"]];overview.getRange('A17:B17').format={fill:'#9B2C2C',font:{bold:true,color:'#FFFFFF'}};overview.getRange('A18:A22').format={fill:'#FDECEC',font:{bold:true,color:'#7F1D1D'}};overview.getRange('A17:B22').format.borders={preset:'all',style:'thin',color:'#E5B7B7'};
for(const s of [overview,cs,ss,rs,bs,es,ls,ws]){const u=s.getUsedRange();u.format.font.name='Aptos';u.format.verticalAlignment='top';}
cs.getRange('A: N').format.columnWidth=17;ss.getRange('A:M').format.columnWidth=19;rs.getRange('A:H').format.columnWidth=21;bs.getRange('A:E').format.columnWidth=20;overview.getRange('A:H').format.columnWidth=24;es.getRange('A:N').format.columnWidth=18;ls.getRange('A:J').format.columnWidth=21;ws.getRange('A:I').format.columnWidth=22;
es.getRange('F4:J27').format.columnWidth=24;ls.getRange('D4:H9').format.columnWidth=28;ws.getRange('E4:I51').format.columnWidth=25;
cs.getRange('F4:M34').format.columnWidth=28;ss.getRange('E:M').format.columnWidth=25;rs.getRange('D:H').format.columnWidth=27;
cs.getRange('A4:N34').format.rowHeight=40;ss.getRange('A4:M34').format.rowHeight=40;rs.getRange('A4:H63').format.rowHeight=28;es.getRange('A4:N27').format.rowHeight=34;ls.getRange('A4:J9').format.rowHeight=36;ws.getRange('A4:I51').format.rowHeight=30;
rs.getRange('F4:F63').conditionalFormats.add('containsText',{text:'是',format:{fill:'#DCFCE7',font:{color:'#166534',bold:true}}});
cs.getRange('B4:B34').conditionalFormats.add('containsText',{text:'隱藏Apex',format:{fill:'#F3E8FF',font:{color:'#6B21A8',bold:true}}});

for (const sheetName of ['00_總覽','角色主表','技能資料','組合關係','平衡參數','敵人圖鑑','關卡資料','波次生成']) {
  const preview=await wb.render({sheetName,autoCrop:'all',scale:1,format:'png'});
  await fs.writeFile(outDir+'/immune_'+sheetName+'_preview.png',new Uint8Array(await preview.arrayBuffer()));
}
const inspect=await wb.inspect({kind:'table',range:"'角色主表'!A1:N12",include:'values,formulas',tableMaxRows:12,tableMaxCols:14,maxChars:5000});
console.log(inspect.ndjson);
const enemyInspect=await wb.inspect({kind:'table',range:"'敵人圖鑑'!A1:N12",include:'values,formulas',tableMaxRows:12,tableMaxCols:14,maxChars:5000});
console.log(enemyInspect.ndjson);
const waveInspect=await wb.inspect({kind:'table',range:"'波次生成'!A1:I12",include:'values,formulas',tableMaxRows:12,tableMaxCols:9,maxChars:5000});
console.log(waveInspect.ndjson);
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\\\?|#N/A',options:{useRegex:true,maxResults:100},summary:'formula error scan'});
console.log(errors.ndjson);
const xlsx=await SpreadsheetFile.exportXlsx(wb);
await xlsx.save(outDir+'/IMMUNE_character_dataset_v0.3.xlsx');
