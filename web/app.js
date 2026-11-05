'use strict';
const URL = 'https://results.eci.gov.in/ResultAcGenMay2026/election-json-S22-live.json';
const TOTAL = 234;
const colors = {TVK:'#ff00ed',DMK:'#00e600',ADMK:'#fff000',BJP:'#ffa500',INC:'#00aaff',PMK:'#00ad88',AMMK:'#ff8700',VCK:'#aaff00',MDMK:'#5faf00',CPI:'#ff2020','CPI(M)':'#ff2020',IUML:'#008700',DMDK:'#ffdf00'};
// Illustrative figures, based on the layout in the original README screenshot.
const demoCounts = [['TVK',103],['DMK',61],['ADMK',49],['PMK',5],['INC',4],['BJP',2],['CPI',2],['DMDK',2],['IUML',2],['VCK',2],['OTHER',1],['CPI(M)',1]];
const demoNames = ['S. VIJAYAKUMAR','DR. RAVI M. S','G. HARI','DR. T. ARUNKUMAR','PRAKASAM. R','R. RAMESH KUMAR','RHEVANTH CHARAN','BALAMURUGAN. G','M. L. VIJAYPRABHU','SENTHIL KUMAR. N','N. MARIE WILSON','C. JOSEPH VIJAY','V. S. BABU','AADHAV ARJUNA','M. R. PALLAVI','RAJMOHAN','K. V. VIJAY DAMU','P. K. SEKARBABU','UDHAYANIDHI STALIN','PRABHAKAR. J. C. D','V. K. RAMKUMAR','SABARINATHAN. R','ARUL PRAKASAM. M','ANAND N','VENKATARAMANAN. P','KUMAR. R','ECR P SARAVANAN','M. HARISH','THENNARASU. K','J. KAMATCHI','D. SARATHKUMAR','S. THIYAGARAJAN','B. VIJAYARAJ'];
const demo = {tableData:demoCounts.flatMap(([party,n])=>Array.from({length:n},()=>[party])),chartData:demoNames.map((name,i)=>[i===2?'ADMK':(i===17||i===18?'DMK':'TVK'),'',i+1,name])};
const $ = id => document.getElementById(id);
let interval = 10, next = Date.now(), busy = false;
function el(tag, className, value) { const node = document.createElement(tag); node.className = className; if (value !== undefined) node.textContent = value; return node; }
function bar(value,max,color) { const track=el('div','bar'); track.setAttribute('aria-hidden','true'); const fill=el('div','fill'); fill.style.width=`${Math.min(100, value / max * 100)}%`; fill.style.setProperty('--color',color); track.append(fill); return track; }
function render(data, live) {
  const counts = new Map(); data.tableData.forEach(row=>counts.set(String(row[0]),(counts.get(String(row[0]))||0)+1));
  const sorted=[...counts].sort((a,b)=>b[1]-a[1]); const max=Math.max(1,...sorted.map(x=>x[1]));
  $('tally').replaceChildren(...sorted.map(([party,count])=>{const color=colors[party]||'#ddd', row=el('div','tally-row'); row.style.setProperty('--color',color); const label=el('span','party',party); label.style.color=color; row.append(label,bar(count,max,color),el('span','count',count),el('span','pct',`${Math.floor(count/TOTAL*100)}%`)); return row;}));
  $('candidates').replaceChildren(...data.chartData.filter(row=>row[3] && row[3]!=='NA').sort((a,b)=>Number(a[2])-Number(b[2])).map(row=>{const line=el('div','candidate'), party=el('span','party',String(row[0])); party.style.color=colors[row[0]]||'#ddd'; line.append(el('span','number',row[2]),party,el('span','name',row[3])); return line;}));
  const sum = parties => parties.reduce((n,p)=>n+(counts.get(p)||0),0);
  const spa=sum(['DMK','INC','CPI','CPI(M)','VCK','IUML','DMDK','MDMK']), nda=sum(['ADMK','BJP','PMK','AMMK']), tvk=sum(['TVK']);
  const groups=[['SPA/INDIA+ (DMK-led)',spa,'#00e600'],['AIADMK+/NDA',nda,'#fff000'],['TVK (solo)',tvk,'#ff00ed'],['Others / independents',Math.max(0,data.tableData.length-spa-nda-tvk),'#888']];
  $('alliances').replaceChildren(...groups.map(([label,count,color])=>{const row=el('div','alliance-row'), name=el('span','alliance-label',label), number=el('span','alliance-count',count); name.style.color=color; number.append(el('span','',`/${TOTAL}`)); row.append(name,bar(count,TOTAL,color),number); return row;}));
  $('declared').textContent=data.tableData.length; $('headline-status').textContent=live?'LIVE':'DEMO';
  $('notice').textContent=live?'LIVE DATA · Source: Election Commission of India. Alliance groupings follow the original CLI.':'DEMO DATA · The election endpoint is unavailable. Figures and candidates are illustrative.';
}
async function refresh() {
  if (busy) return; busy=true;
  try { const response=await fetch(URL,{cache:'no-store',signal:AbortSignal.timeout(8000)}); if(!response.ok) throw new Error('Endpoint unavailable'); const json=await response.json(); if(!json.S22 || !Array.isArray(json.S22.tableData) || !Array.isArray(json.S22.chartData)) throw new Error('Unexpected data'); render(json.S22,true); }
  catch { render(demo,false); }
  finally { $('last').textContent=new Date().toLocaleTimeString('en-GB'); next=Date.now()+interval*1000; busy=false; }
}
function changeInterval(delta){interval=Math.max(2,Math.min(120,interval+delta)); $('interval').textContent=interval; next=Date.now()+interval*1000;}
$('refresh').addEventListener('click',refresh); $('faster').addEventListener('click',()=>changeInterval(-2)); $('slower').addEventListener('click',()=>changeInterval(2));
document.addEventListener('keydown',event=>{if(event.target.matches('button, input, textarea, select') || event.ctrlKey || event.metaKey || event.altKey) return; if(event.key.toLowerCase()==='r') refresh(); if(event.key==='+') changeInterval(-2); if(event.key==='-') changeInterval(2);});
render(demo,false); refresh(); setInterval(()=>{const seconds=Math.max(0,Math.ceil((next-Date.now())/1000)); $('countdown').textContent=seconds; if(!seconds && !busy) refresh();},250);
