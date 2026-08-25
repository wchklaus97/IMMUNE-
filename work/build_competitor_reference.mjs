import fs from 'node:fs/promises';
import { SpreadsheetFile, Workbook } from '@oai/artifact-tool';

const outDir='C:/Users/wchkl/Documents/Codex/2026-08-12/https-chatgpt-com-share-6a7b9aee-e840-2/outputs';
await fs.mkdir(outDir,{recursive:true});
const wb=Workbook.create();
const s=wb.worksheets.add('競品研究');
const a=wb.worksheets.add('估算方法');
const d=wb.worksheets.add('直接競品與差異化');
for(const sh of [s,a,d]) sh.showGridLines=false;
const navy='#172A46', blue='#2F6FED', gold='#C58A1B', light='#E8EEF7', text='#1F2937';
function title(sh,range,value){sh.getRange(range).merge();sh.getRange(range.split(':')[0]).values=[[value]];sh.getRange(range).format={fill:navy,font:{bold:true,color:'#FFFFFF',size:16},verticalAlignment:'center'};}
function header(sh,range){sh.getRange(range).format={fill:blue,font:{bold:true,color:'#FFFFFF'},horizontalAlignment:'center',verticalAlignment:'center',wrapText:true,borders:{preset:'all',style:'thin',color:'#D7E0EF'}};}
function body(sh,range){sh.getRange(range).format={font:{color:text,size:10},verticalAlignment:'top',wrapText:true,borders:{preset:'inside',style:'thin',color:'#D9E2F0'}};}
title(s,'A1:Q1','IMMUNE Steam 競品研究資料表');
s.getRange('A3:Q3').values=[['遊戲','發售日','評論數','評論率','團隊規模','團隊資料狀態','主線／內容時長','國區原價（元）','估算銷量下限','估算銷量上限','估算毛收入下限（元）','估算毛收入上限（元）','Steam Deck','對 IMMUNE 的參考','發售資料來源','團隊資料來源','備註']];
header(s,'A3:Q3');
const rows=[
['Relic Guardian',new Date('2025-10-22'),600,'90%上下','1–3人','推估（公開頁面未列完整團隊）','10–50h',68,null,null,null,null,'可玩','可愛塔防、低配置、長期重玩','https://store.steampowered.com/app/2064610/','https://steamdb.info/app/2064610/charts/','評論量以約0.6K–1K的市場快照估算'],
['Tower Dominion',new Date('2025-05-08'),4000,'87%','約10人','公開訪談／社群推估','10–50h',66,null,null,null,null,'可玩','Demo、題材清楚、團隊擴張後內容量提升','https://store.steampowered.com/app/3226530/','https://www.reddit.com/r/TowerDefense/comments/','SteamRev曾估算約195萬美元毛收入，非官方'],
['There Are No Orcs',new Date('2025-11-05'),700,'94%','1–3人','推估；BaseTrade Studio未公開完整人數','10–50h',36,null,null,null,null,'不支持','獨特名稱、Roguelite＋塔防、可形成記憶點','https://store.steampowered.com/app/3480990/','https://www.pcgamingwiki.com/wiki/There_Are_No_Orcs','官方社群曾公告已售出超過50,000份'],
['Rift Riff',new Date('2025-05-09'),400,'96%','5人','公開列出5位核心成員','10–50h',52,null,null,null,null,'良好','小團隊也能做出有深度的塔防；Demo很重要','https://store.steampowered.com/app/3320170/','https://store.steampowered.com/app/3320170/','官方頁面列出設計、美術、波次、音樂、程式等5人'],
['Islets Defense',new Date('2025-06-18'),200,'95%','1–3人','推估','10–50h',38,null,null,null,null,'良好','小而完整，但需要更強商店曝光','https://store.steampowered.com/','', '公開團隊資料有限'],
['Gnomes',new Date('2025-04-05'),1000,'96%','1–4人','推估','10–50h',49,null,null,null,null,'可玩','可愛美術能提升點擊與推薦率','https://store.steampowered.com/','', '公開團隊資料有限'],
['The King is Watching',new Date('2025-07-21'),2000,'82%','1–5人','推估','10h以内',49,null,null,null,null,'可玩','短主線＋策略重玩，接近IMMUNE目標時長','https://store.steampowered.com/','', '評論率較低，需重視首發品質'],
['Galaxy Defense War',new Date('2025-12-15'),200,'98%','1–3人','推估','10h以内',41.25,null,null,null,null,'未知','普通科幻塔防需要更強差異化','https://store.steampowered.com/','', '公開團隊資料有限'],
['Nordhold',new Date('2025-03-26'),2000,'88%','1–5人','推估','10h以内',78,null,null,null,null,'可玩','系統深度可支撐較高定價','https://store.steampowered.com/','', '適合作為深度系統參考'],
['ShapeHero Factory',new Date('2025-09-17'),600,'88%','1–4人','推估','50–100h',68,null,null,null,null,'可玩','組合、建造、成長系統能延長遊戲時長','https://store.steampowered.com/','', '長時長主要來自系統重玩，不是單純主線']
];
s.getRange('A4:Q13').values=rows;
// Review-to-sales estimates: 20–60 units per review; gross uses regional list price as a transparent upper proxy.
s.getRange('I4:I13').formulas=rows.map((_,i)=>[`=C${i+4}*'估算方法'!$B$4`]);
s.getRange('J4:J13').formulas=rows.map((_,i)=>[`=C${i+4}*'估算方法'!$B$5`]);
s.getRange('K4:K13').formulas=rows.map((_,i)=>[`=I${i+4}*H${i+4}*'估算方法'!$B$6`]);
s.getRange('L4:L13').formulas=rows.map((_,i)=>[`=J${i+4}*H${i+4}*'估算方法'!$B$7`]);
body(s,'A4:Q13'); s.freezePanes.freezeRows(3); s.freezePanes.freezeColumns(1); s.tables.add('A3:Q13',true,'CompetitorTable');
s.getRange('B4:B13').format.numberFormat='yyyy-mm-dd'; s.getRange('C4:C13').format.numberFormat='#,##0'; s.getRange('H4:L13').format.numberFormat='#,##0';
s.getRange('A:Q').format.columnWidth=18; s.getRange('A4:A13').format.columnWidth=22; s.getRange('N4:Q13').format.columnWidth=30; s.getRange('A4:Q13').format.rowHeight=46;
title(a,'A1:E1','估算方法與資料可信度');
a.getRange('A3:E3').values=[['項目','數值','單位','用途','可信度']]; header(a,'A3:E3');
a.getRange('A4:E9').values=[['評論→銷量下限',20,'份／評論','保守銷量估算','研究假設'],['評論→銷量上限',60,'份／評論','樂觀銷量估算','研究假設'],['毛收入折算下限',0.55,'比例','考慮折扣、區域定價前的簡化折算','研究假設'],['毛收入折算上限',0.85,'比例','考慮折扣差異的簡化折算','研究假設'],['資料分類','已知／推估分開','文字','團隊人數若沒有官方披露則標示推估','方法規則'],['注意事項','收入非官方數字','文字','Steam分成、退款、稅務、套包與促銷未完整建模','重要']];
body(a,'A4:E9'); a.getRange('A:A').format.columnWidth=24; a.getRange('B:B').format.columnWidth=18; a.getRange('C:E').format.columnWidth=28; a.getRange('B6:B7').format.numberFormat='0%';
a.getRange('A11:E15').values=[['研究結論','','','',''],['最可比樣本','Rift Riff、The King is Watching','','',''],['IMMUNE建議價格','人民幣48–68元','','',''],['IMMUNE時長目標','主線4–6小時；完整15–25小時','','',''],['核心差異化','可愛免疫細胞＋吞噬＋57種家族關係＋五星Apex','','','']];
a.getRange('A11:E11').merge(true); a.getRange('A11:E11').format={fill:gold,font:{bold:true,color:'#FFFFFF'}}; body(a,'A12:E15');
title(d,'A1:J1','IMMUNE 直接競品與差異化地圖');
d.getRange('A3:J3').values=[['遊戲','人體／免疫題材','TD','Roguelite','細胞組合','敵人變異','3D','核心玩法定位','對 IMMUNE 的威脅','IMMUNE 應對策略']]; header(d,'A3:J3');
d.getRange('A4:J9').values=[
['Cell Defense','是','是','是','部分','是','是','2D俯視、增量式TD、卡牌Build','高：題材與玩法交集最接近','以3D實體融合、雙形態與吞噬經濟作明確區隔'],
['Auto Immune','是','部分','是','是','是','是','物理自動戰鬥、Deckbuilding、細胞協同','高：機制競品','強化固定／移動雙形態、空間部署與塔防路線'],
['Magic Cells Demo','微觀細胞','是','部分','是','是','是','合併格子、升級細胞、病原體Boss','中高：細胞合成與突變相似','以免疫家族關係、五星Apex與3D視覺成長區隔'],
['Supre-Immune','是','部分','是','是','是','是','可愛免疫細胞、擊殺、進化、每局Build','中高：美術與題材接近','聚焦塔防決策、固定塔／移動塔切換及狀態化學'],
['Tower Defense for Virus','病毒','是','是','否','部分','否','病毒題材塔防，但偏電腦病毒','中：關鍵字重疊、題材不同','明確使用人體內部戰場與真實免疫細胞'],
['Cells of Immunity','是','否','否','部分','否','部分','T細胞、巨噬細胞等即時戰鬥','中：題材先行者','以塔防、融合、組合星級與重玩流程建立新類別']
]; body(d,'A4:J9'); d.freezePanes.freezeRows(3); d.tables.add('A3:J9',true,'DirectCompetitorTable'); d.getRange('A:J').format.columnWidth=21; d.getRange('H:J').format.columnWidth=34; d.getRange('A4:J9').format.rowHeight=54;
 d.getRange('A11:J15').values=[['建議USP','','','','','','','','',''],['英文定位','A 3D roguelite tower-defense game where immune cells physically fuse into evolving towers, while pathogens mutate in response to your build.','','','','','','','',''],['中文定位','玩家融合免疫細胞創造新塔；敵人會根據你的Build反向突變。','','','','','','','',''],['首發展示重點','T+B實體融合、吞噬敵人、狀態反應、固定／移動雙形態、五星Apex','','','','','','','',''],['命名提醒','IMMUNE 可作為專案名；正式發售前仍應檢查 Steam 與 Class 009／041 商標可用性。','','','','','','','','']];
 d.getRange('A11:J11').merge(true); d.getRange('A11:J11').format={fill:gold,font:{bold:true,color:'#FFFFFF'}}; d.getRange('B12:J15').merge(true); body(d,'A12:J15');
for(const sh of [s,a]){const u=sh.getUsedRange();u.format.font.name='Aptos';u.format.verticalAlignment='top';}
const p=await wb.render({sheetName:'競品研究',autoCrop:'all',scale:1,format:'png'}); await fs.writeFile(outDir+'/immune_競品研究_preview.png',new Uint8Array(await p.arrayBuffer()));
const q=await wb.render({sheetName:'估算方法',autoCrop:'all',scale:1,format:'png'}); await fs.writeFile(outDir+'/immune_估算方法_preview.png',new Uint8Array(await q.arrayBuffer()));
const r=await wb.render({sheetName:'直接競品與差異化',autoCrop:'all',scale:1,format:'png'}); await fs.writeFile(outDir+'/immune_直接競品與差異化_preview.png',new Uint8Array(await r.arrayBuffer()));
const check=await wb.inspect({kind:'table',range:"'競品研究'!A1:Q13",include:'values,formulas',tableMaxRows:13,tableMaxCols:17,maxChars:6000}); console.log(check.ndjson);
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A',options:{useRegex:true,maxResults:100},summary:'formula error scan'}); console.log(errors.ndjson);
const xlsx=await SpreadsheetFile.exportXlsx(wb); await xlsx.save(outDir+'/IMMUNE_competitor_reference_v0.2.xlsx');
