import json
import secrets
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from . import core


FAVICON = b"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<rect width="64" height="64" rx="16" fill="#183a2e"/>
<rect x="13" y="14" width="16" height="16" rx="5" fill="#e8f5eb"/>
<rect x="35" y="14" width="16" height="16" rx="5" fill="#e8f5eb"/>
<rect x="13" y="36" width="16" height="16" rx="5" fill="#e8f5eb"/>
<rect x="35" y="36" width="16" height="16" rx="5" fill="#7ee1a1"/>
</svg>"""


PAGE = """<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Локальные проекты</title><link rel="icon" type="image/svg+xml" href="/favicon.svg"><style>
:root {
  font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #1b3029;
  background: #f3f6f3;
}
* { box-sizing: border-box; }
body {
  min-height: 100vh;
  margin: 0;
  padding: 28px 28px 72px;
  background: radial-gradient(circle at 50% -260px, #e3eee6 0, transparent 58%), #f3f6f3;
}
body > header, body > .summary, body > .grid { max-width: 1240px; margin-inline: auto; }
button, select { font: inherit; }
button, select, a.button { -webkit-tap-highlight-color: transparent; }
header {
  position: relative;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 24px;
  overflow: hidden;
  padding: 20px 30px;
  border: 1px solid #204a3a;
  border-radius: 18px;
  color: #fff;
  background: radial-gradient(circle at 88% -50%, #3b8667 0, transparent 42%), linear-gradient(125deg, #183a2e 0%, #10291f 100%);
  box-shadow: 0 20px 44px -30px #17392c8c;
}
header::after {
  content: "";
  position: absolute;
  right: -90px;
  bottom: -205px;
  width: 450px;
  height: 450px;
  border: 1px solid #ffffff18;
  border-radius: 50%;
  box-shadow: 0 0 0 66px #ffffff08, 0 0 0 132px #ffffff05;
  pointer-events: none;
}
header > * { position: relative; z-index: 1; }
.overline {
  color: #a9ddbd;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .17em;
  text-transform: uppercase;
}
h1 { margin: 8px 0 5px; font-size: clamp(27px, 2.5vw, 32px); line-height: 1.08; letter-spacing: -.045em; }
header p { margin: 0; color: #c6d9cd; font-size: 13px; }
#banner {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  flex: none;
  padding: 9px 13px;
  border: 1px solid #ffffff26;
  border-radius: 999px;
  background: #ffffff14;
  color: #e9f8ec;
  font-size: 12px;
  white-space: nowrap;
}
#banner::before {
  content: "";
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #7ee1a1;
  box-shadow: 0 0 0 4px #7ee1a122;
}
#banner.loading::before { background: #e6c879; box-shadow: 0 0 0 4px #e6c87922; }
#banner.offline::before { background: #ffb37f; box-shadow: 0 0 0 4px #ffb37f22; }
.summary {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-top: 22px;
  margin-bottom: 18px;
}
.overview { display: flex; flex-direction: column; gap: 3px; margin-right: auto; }
.overview span { color: #7a9085; font-size: 10px; font-weight: 700; letter-spacing: .16em; text-transform: uppercase; }
.overview strong { color: #20392e; font-size: 18px; letter-spacing: -.025em; }
.metrics { display: flex; flex-wrap: wrap; gap: 8px; }
.metric {
  display: inline-flex;
  align-items: baseline;
  gap: 7px;
  min-height: 39px;
  padding: 8px 12px;
  border: 1px solid #e0e9e2;
  border-radius: 11px;
  background: #fff;
  color: #718279;
  white-space: nowrap;
}
.metric strong { color: #365144; font-size: 17px; font-variant-numeric: tabular-nums; line-height: 1; }
.metric span { font-size: 12px; }
.metric.running strong { color: #277451; }
.metric.attention strong { color: #b17031; }
.grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }
.card {
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
  border: 1px solid #dfe8e0;
  border-radius: 20px;
  background: #fff;
  box-shadow: 0 8px 26px -20px #18372c52, 0 2px 6px #18372c08;
  transition: box-shadow .18s ease, transform .18s ease;
}
.card:hover { transform: translateY(-2px); box-shadow: 0 18px 34px -24px #18372c70, 0 3px 10px #18372c0d; }
.skeleton-card { pointer-events: none; }
.skeleton-card:hover { transform: none; }
.skeleton-head { display: flex; align-items: center; gap: 15px; padding: 23px 25px 21px; border-bottom: 1px solid #eef2ed; }
.skeleton-title { display: grid; flex: 1; gap: 9px; }
.skeleton-body { display: grid; gap: 14px; padding: 19px 25px 22px; }
.skeleton-row { display: flex; gap: 8px; }
.skeleton-actions { margin-top: 5px; padding-top: 17px; border-top: 1px solid #eef2ed; }
.skeleton-block { display: block; flex: none; border-radius: 7px; background: linear-gradient(100deg, #edf2ee 25%, #f7faf7 45%, #edf2ee 65%); background-size: 220% 100%; animation: skeleton-shimmer 1.5s ease-in-out infinite; }
.skeleton-avatar { width: 50px; height: 50px; border-radius: 15px; }
.skeleton-title .skeleton-block:first-child { width: 42%; height: 17px; }
.skeleton-title .skeleton-block:last-child { width: 58%; height: 11px; }
.skeleton-status { width: 83px; height: 27px; border-radius: 999px; }
.skeleton-label { width: 70px; height: 9px; }
.skeleton-chip { width: 96px; height: 28px; }
.skeleton-button { width: 128px; height: 38px; border-radius: 10px; }
.skeleton-button + .skeleton-button { width: 100px; }
.skeleton-expander { width: 118px; height: 11px; margin-top: 2px; }
.load-error { grid-column: 1 / -1; margin: 0; padding: 18px 20px; border: 1px solid #f3e2c9; border-radius: 12px; background: #fffaf0; color: #8d693b; }
@keyframes skeleton-shimmer { to { background-position-x: -220%; } }
.card-head { display: flex; align-items: center; gap: 15px; padding: 23px 25px 21px; border-bottom: 1px solid #eef2ed; }
.avatar {
  display: grid;
  place-items: center;
  flex: none;
  width: 50px;
  height: 50px;
  border-radius: 15px;
  background: #edeafd;
  color: #6551a7;
  font-size: 21px;
  font-weight: 750;
}
.card:nth-child(4n+2) .avatar { background: #f8ecdf; color: #9c6d3b; }
.card:nth-child(4n+3) .avatar { background: #e5f4ed; color: #38785d; }
.card:nth-child(4n+4) .avatar { background: #e9edf7; color: #53668e; }
.title { flex: 1; min-width: 0; }
.title strong { display: block; margin-bottom: 3px; font-size: 18px; line-height: 1.2; letter-spacing: -.025em; }
.title p { overflow: hidden; margin: 0; color: #8b9990; font: 11px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace; text-overflow: ellipsis; white-space: nowrap; }
.state {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  flex: none;
  padding: 7px 10px;
  border: 1px solid #e6ece7;
  border-radius: 999px;
  background: #f6f8f6;
  color: #6c7a71;
  font-size: 11px;
  font-weight: 650;
  white-space: nowrap;
}
.state::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: #a6b2a9; }
.state.running { border-color: #d6ebdc; background: #eff8f1; color: #267248; }
.state.running::before { background: #35a269; }
.state.conflict, .state.degraded { border-color: #f3e2c9; background: #fff7e9; color: #9b672b; }
.state.conflict::before, .state.degraded::before { background: #d39a47; }
.state.starting { border-color: #d8e9de; background: #f1f8f3; color: #347354; }
.state.starting::before { background: #5aad7b; }
.body { display: flex; flex: 1; flex-direction: column; padding: 18px 25px 22px; }
.section-label { margin-bottom: 10px; color: #93a095; font-size: 10px; font-weight: 700; letter-spacing: .15em; text-transform: uppercase; }
.checks { display: flex; flex-wrap: wrap; gap: 7px; min-height: 27px; }
.chip {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 6px 9px;
  border: 1px solid #e7ede7;
  border-radius: 8px;
  background: #f7f9f7;
  color: #66786b;
  font-size: 11px;
  line-height: 1.2;
}
.chip::before { content: ""; width: 6px; height: 6px; border-radius: 50%; background: #c4965c; }
.chip.ok::before { background: #44a477; }
.actions { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; margin-top: 17px; padding-top: 17px; border-top: 1px solid #eef2ed; }
button, select, a.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 38px;
  padding: 8px 13px;
  border: 1px solid #dfe8e0;
  border-radius: 10px;
  background: #fff;
  color: #33473a;
  font-size: 12px;
  font-weight: 650;
  line-height: 1.2;
  text-decoration: none;
  cursor: pointer;
  transition: background .15s ease, border-color .15s ease, color .15s ease, box-shadow .15s ease;
}
button:hover:not(:disabled), a.button:hover { border-color: #b9d2c2; background: #f3f8f4; }
button:focus-visible, select:focus-visible, a.button:focus-visible { outline: 3px solid #79c799; outline-offset: 2px; }
button.primary { border-color: #28764f; background: #28764f; color: #fff; box-shadow: 0 4px 10px #28764f24; }
button.primary:hover:not(:disabled) { border-color: #1f6944; background: #1f6944; }
button.danger { border-color: #f1d7d2; background: #fff3f1; color: #ad5147; }
button.danger:hover:not(:disabled) { border-color: #e7bcb5; background: #ffe9e5; }
button:disabled { opacity: .46; cursor: default; box-shadow: none; }
.profile-select { position: relative; display: inline-flex; align-items: center; }
.profile-select select { appearance: none; min-width: 140px; max-width: 170px; padding-right: 36px; background: #fff; }
.chevron { position: absolute; right: 15px; top: 50%; width: 8px; height: 8px; border-right: 1.5px solid #788a7e; border-bottom: 1.5px solid #788a7e; transform: translateY(-70%) rotate(45deg); pointer-events: none; }
.expanders { display: flex; align-items: center; flex-wrap: wrap; gap: 16px; margin-top: 16px; }
.log-row { display: flex; align-items: center; flex-wrap: wrap; gap: 12px; }
.log-toggle { align-self: flex-start; min-height: 0; padding: 0; border: 0; background: transparent; color: #829187; font-size: 11px; font-weight: 600; }
.log-toggle:hover:not(:disabled), .log-toggle:focus-visible { border: 0; background: transparent; color: #28764f; text-decoration: underline; }
.worktree-toggle { gap: 6px; min-height: 0; padding: 0; border: 0; background: transparent; color: #526c5d; font-size: 11px; font-weight: 700; }
.worktree-toggle:hover:not(:disabled), .worktree-toggle:focus-visible { border: 0; background: transparent; color: #28764f; text-decoration: underline; }
.log-service { min-height: 30px; padding: 5px 9px; font-size: 11px; }
.expander-panel { display: grid; grid-template-rows: 0fr; overflow: hidden; opacity: 0; transition: grid-template-rows .24s ease, opacity .2s ease; }
.expander-panel.expanded { grid-template-rows: 1fr; opacity: 1; }
.expander-inner { min-height: 0; overflow: hidden; }
.log { overflow: auto; max-height: 240px; margin: 13px 0 0; padding: 14px; border-radius: 11px; background: #192922; color: #dcebe0; font: 11px/1.55 ui-monospace, SFMono-Regular, Menlo, monospace; white-space: pre-wrap; }
.hint { margin: 13px 0 0; padding: 10px 12px; border: 1px solid #f3e3c7; border-radius: 9px; background: #fffaf0; color: #8d693b; font-size: 11px; line-height: 1.45; }
.conflict-details { display: grid; gap: 9px; }
.conflict-owner { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; }
.conflict-owner strong { color: #75552f; font: 11px ui-monospace, SFMono-Regular, Menlo, monospace; }
.conflict-owner button { min-height: 29px; padding: 5px 9px; font-size: 11px; }
.worktree-list .conflict-details { margin: 0 12px 11px; }
.error { margin-top: 12px; color: #a74336; font-size: 12px; line-height: 1.45; }
.operation { margin-top: 13px; color: #367756; font-size: 11px; font-weight: 650; }
.progress { overflow: hidden; height: 5px; margin-top: 8px; border-radius: 5px; background: #e3f0e7; }
.progress::after { content: ""; display: block; width: 35%; height: 100%; border-radius: 5px; background: #58a976; animation: load 1.3s ease-in-out infinite; }
.worktree-count { padding: 3px 7px; border-radius: 99px; background: #eff4ef; color: #708478; font-size: 10px; }
.worktree-list { margin-top: 11px; border: 1px solid #e8eee8; border-radius: 11px; overflow: hidden; }
.worktree-bulk { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 9px 12px; background: #f8faf8; }
.worktree-bulk label { display: inline-flex; align-items: center; gap: 8px; color: #637368; font-size: 11px; cursor: pointer; }
.worktree-bulk button { min-height: 30px; padding: 5px 9px; font-size: 11px; }
.worktree-checkbox { width: 15px; height: 15px; margin: 0; flex: none; accent-color: #3e7654; cursor: pointer; }
.worktree-checkbox:disabled { cursor: not-allowed; }
.worktree-row { display: flex; align-items: center; gap: 10px; min-width: 0; padding: 11px 12px; }
.worktree-selection { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; cursor: pointer; }
.worktree-selection.disabled { cursor: not-allowed; }
.worktree-list > div + div { border-top: 1px solid #edf1ed; }
.worktree-info { flex: 1; min-width: 0; }
.worktree-info strong, .worktree-info small { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.worktree-info strong { font-size: 12px; }
.worktree-info small { margin-top: 3px; color: #8b9990; font: 10px ui-monospace, SFMono-Regular, Menlo, monospace; }
.worktree-date { color: #8b9990; font-size: 10px; white-space: nowrap; }
.worktree-sources, .worktree-empty { margin: 11px 0 0; color: #829087; font-size: 11px; line-height: 1.5; }
.worktree-empty { padding: 11px 12px; border: 1px solid #e8eee8; border-radius: 9px; }
.worktree-row .state { padding: 5px 8px; font-size: 10px; }
.worktree-row button, .worktree-row a.button { min-height: 31px; padding: 5px 9px; font-size: 11px; white-space: nowrap; }
.worktree-message { margin: 0; padding: 0 12px 11px; color: #a74336; font-size: 11px; }
.worktree-progress { margin: 0 12px 10px; }
.worktree-log { margin: 0 12px 11px; }
.worktree-flags { display: inline-flex; gap: 4px; color: #ae7431; font-size: 14px; font-weight: 700; }
.worktree-flags span { display: inline-flex; min-width: 18px; justify-content: center; cursor: help; }
.worktree-flags span:focus-visible { outline: 2px solid #79c799; border-radius: 4px; }
.flag-tooltip { position: fixed; z-index: 50; width: max-content; max-width: min(240px, calc(100vw - 16px)); padding: 7px 9px; border-radius: 7px; background: #24382b; color: #fff; box-shadow: 0 6px 18px #13281930; font-size: 11px; line-height: 1.35; pointer-events: none; }
.flag-tooltip[hidden] { display: none; }
.worktree-row .worktree-remove { display: inline-flex; align-items: center; justify-content: center; width: 32px; min-width: 32px; padding: 5px; color: #a04d44; }
.worktree-remove svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
.delete-dialog { width: min(520px, calc(100vw - 32px)); max-height: min(80vh, 700px); padding: 24px; border: 1px solid #e1e9e1; border-radius: 16px; box-shadow: 0 20px 70px #162b1e45; color: #26372c; }
.delete-dialog::backdrop { background: #17261c80; }
.delete-dialog h2 { margin: 0 0 9px; font-size: 19px; }
.delete-dialog p { margin: 8px 0; color: #647468; font-size: 12px; line-height: 1.5; }
.delete-dialog ul { max-height: 35vh; overflow: auto; margin: 14px 0; padding: 0; list-style: none; border: 1px solid #e8eee8; border-radius: 9px; }
.delete-dialog li { padding: 9px 11px; overflow-wrap: anywhere; font: 11px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace; }
.delete-dialog li + li { border-top: 1px solid #edf1ed; }
.delete-dialog .dialog-actions { display: flex; justify-content: flex-end; gap: 9px; margin-top: 20px; }
@keyframes load { from { transform: translateX(-100%); } to { transform: translateX(290%); } }
@media (prefers-reduced-motion: reduce) {
  .card { transition: none; }
  .card:hover { transform: none; }
  .progress::after { width: 100%; animation: none; }
  .expander-panel { transition: none; }
  .skeleton-block { animation: none; }
}
@media (max-width: 920px) { .grid { grid-template-columns: 1fr; } }
@media (max-width: 670px) {
  body { padding: 16px 14px 40px; }
  header { display: block; padding: 20px 22px; border-radius: 16px; }
  header::after { right: -200px; }
  h1 { margin: 20px 0 5px; font-size: 28px; }
  #banner { position: absolute; top: 18px; right: 20px; padding: 7px 10px; font-size: 11px; }
  .summary { align-items: flex-start; flex-wrap: wrap; gap: 14px; margin-top: 24px; }
  .overview { flex: 1; min-width: 0; }
  .metrics { order: 1; width: 100%; }
  .metric { flex: 1; justify-content: center; padding: 8px; }
  .grid { gap: 12px; }
  .card-head { display: grid; grid-template-columns: 48px minmax(0, 1fr); gap: 4px 13px; padding: 20px; }
  .skeleton-head { flex-wrap: wrap; padding: 20px; }
  .skeleton-status { margin-left: 63px; }
  .skeleton-body { padding: 17px 20px 20px; }
  .avatar { grid-row: span 2; width: 48px; height: 48px; }
  .state { grid-column: 2; justify-self: start; }
  .body { padding: 17px 20px 20px; }
  .worktree-row { flex-wrap: wrap; }
  .worktree-selection { flex-basis: 100%; }
}
</style></head><body><header><div><span class="overline">Локальная разработка</span><h1>Локальные проекты</h1><p>Запускай, останавливай и открывай свои проекты.</p></div><span id="banner" class="loading">Подключаемся</span></header><div class="summary"><div class="overview"><span>Обзор</span><strong>Мои проекты</strong></div><div id="summary" class="metrics" aria-label="Статусы проектов">Загрузка…</div><button id="refresh" type="button">↻ Обновить</button></div><main id="grid" class="grid" aria-busy="true"></main>
<script>
let token=__TOKEN__;const home=__HOME__;const grid=document.querySelector('#grid');let latestProjects=[];let lastSnapshot='';const pending=new Map();const openLogs=new Set();const openWorktrees=new Set();const selectedLogs=new Map();const errors=new Map();const worktreeFlags=new Map();const flagTimes=new Map();const flagLoading=new Set();const selectedWorktrees=new Set();let bulkDeleting=false;
const flagTooltip=el('div','flag-tooltip');flagTooltip.hidden=true;flagTooltip.setAttribute('role','tooltip');document.body.append(flagTooltip);
const labels={running:'Работает',stopped:'Остановлен',starting:'Запускается',degraded:'Требует внимания',conflict:'Конфликт порта'};
function el(tag,cls,text){const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined)node.textContent=text;return node}
function displayPath(path){return path===home?'~':path.startsWith(home+'/')?'~'+path.slice(home.length):path}
function setExpanded(button,panel,open,label){button.firstChild.textContent=(open?'▾':'▸')+' '+label;button.setAttribute('aria-expanded',String(open));panel.classList.toggle('expanded',open);panel.inert=!open}
function scrollLogToEnd(log){requestAnimationFrame(()=>{if(log.isConnected)log.scrollTop=log.scrollHeight})}
function showFlagTooltip(event){const badge=event.currentTarget;flagTooltip.textContent=badge.dataset.tooltip;flagTooltip.hidden=false;const rect=badge.getBoundingClientRect();const box=flagTooltip.getBoundingClientRect();flagTooltip.style.left=Math.max(8,Math.min(innerWidth-box.width-8,rect.left+(rect.width-box.width)/2))+'px';flagTooltip.style.top=(rect.top>box.height+12?rect.top-box.height-8:rect.bottom+8)+'px'}
function hideFlagTooltip(){flagTooltip.hidden=true}
function skeletonCard(){const card=el('article','card skeleton-card');card.setAttribute('aria-hidden','true');const head=el('div','skeleton-head');const title=el('div','skeleton-title');title.append(el('span','skeleton-block'),el('span','skeleton-block'));head.append(el('span','skeleton-block skeleton-avatar'),title,el('span','skeleton-block skeleton-status'));const body=el('div','skeleton-body');const checks=el('div','skeleton-row');checks.append(el('span','skeleton-block skeleton-chip'),el('span','skeleton-block skeleton-chip'));const actions=el('div','skeleton-row skeleton-actions');actions.append(el('span','skeleton-block skeleton-button'),el('span','skeleton-block skeleton-button'));body.append(el('span','skeleton-block skeleton-label'),checks,actions,el('span','skeleton-block skeleton-expander'));card.append(head,body);return card}
async function api(path,options={}){const request=()=>fetch(path,{...options,headers:{'Content-Type':'application/json','X-Devkit-Token':token}});let response=await request();const currentToken=response.headers.get('X-Devkit-Token');if(currentToken&&currentToken!==token){token=currentToken;if(response.status===403&&options.method==='POST')response=await request()}const body=await response.json();if(!response.ok)throw Error(body.error||response.statusText);return body}
async function loadWorktreeFlags(id,force=false){if(flagLoading.has(id)||(!force&&Date.now()-(flagTimes.get(id)||0)<30000))return;flagLoading.add(id);try{const flags=await api('/api/worktree-flags?project='+encodeURIComponent(id));for(const item of flags)worktreeFlags.set(item.id,item);errors.delete(id);flagTimes.set(id,Date.now());render()}catch(error){errors.set(id,error.message);flagTimes.set(id,Date.now());render()}finally{flagLoading.delete(id)}}
async function act(id,action,profile,confirmation,details={}){if(pending.has(id))return;pending.set(id,action);errors.delete(id);render();try{await api('/api/action',{method:'POST',body:JSON.stringify({project:id,action,profile,confirmation,...details})})}catch(error){errors.set(id,error.message)}finally{pending.delete(id);await refresh(true)}}
function canDeleteWorktree(project){const flags=worktreeFlags.get(project.id);return project.state==='stopped'&&!!flags&&!(flags.detached&&flags.unpushed)&&!pending.has(project.id)}
function confirmBulkDelete(projects){return new Promise(resolve=>{const dialog=el('dialog','delete-dialog');dialog.append(el('h2','','Удалить worktrees: '+projects.length),el('p','','Локальные checkout и файлы по этим путям будут удалены. Ветки останутся в Git.'));const paths=el('ul');paths.append(...projects.map(project=>el('li','',(project.source?project.source+' · ':'')+project.branch+' — '+displayPath(project.root))));dialog.append(paths);if(projects.some(project=>{const flags=worktreeFlags.get(project.id);return flags.dirty||flags.untracked||flags.ignored}))dialog.append(el('p','','В выбранных worktrees есть локальные изменения, новые или игнорируемые файлы (возможно, .env и зависимости). Они будут потеряны.'));const actions=el('div','dialog-actions');const cancel=el('button','','Отмена');const confirm=el('button','danger','Удалить '+projects.length);cancel.onclick=()=>dialog.close('cancel');confirm.onclick=()=>dialog.close('confirm');actions.append(cancel,confirm);dialog.append(actions);dialog.addEventListener('close',()=>{const accepted=dialog.returnValue==='confirm';dialog.remove();resolve(accepted)},{once:true});document.body.append(dialog);dialog.showModal();cancel.focus()})}
async function deleteSelectedWorktrees(children){if(bulkDeleting)return;const projects=children.filter(project=>selectedWorktrees.has(project.id)&&canDeleteWorktree(project));if(!projects.length||!await confirmBulkDelete(projects))return;bulkDeleting=true;for(const project of projects){pending.set(project.id,'delete');errors.delete(project.id)}render();for(const project of projects){const flags=worktreeFlags.get(project.id);try{await api('/api/action',{method:'POST',body:JSON.stringify({project:project.id,action:'delete',confirmation:flags.dirty||flags.untracked||flags.ignored?project.branch:undefined})});selectedWorktrees.delete(project.id)}catch(error){errors.set(project.id,error.message)}finally{pending.delete(project.id)}}bulkDeleting=false;await refresh(true)}
function conflictDetails(project){
  const box=el('div','hint conflict-details');const ports=project.services.flatMap(service=>service.busy_ports);
  box.append(el('span','','Порты '+ports.join(', ')+' заняты процессами вне панели.'));
  let shown=0;
  for(const service of project.services)for(const owner of service.listeners||[]){
    shown++;const row=el('div','conflict-owner');row.append(el('strong','',owner.port+' · '+owner.command+' (PID '+owner.pid+')'));
    if(owner.stoppable){const button=el('button','danger','Остановить процесс');button.disabled=pending.has(project.id);button.onclick=()=>{if(window.confirm('Остановить '+owner.command+' (PID '+owner.pid+') на порту '+owner.port+'? Это завершит весь процесс, включая другие обслуживаемые им порты.'))act(project.id,'release_port',undefined,undefined,{port:owner.port,pid:owner.pid,birth:owner.birth})};row.append(button)}
    else row.append(el('span','','Остановка здесь недоступна: '+({managed:'процесс запущен devkit',other_user:'другой пользователь',dashboard:'процесс dashboard',unknown:'не удалось проверить процесс'}[owner.reason]||'неизвестная причина')));
    box.append(row);
  }
  if(!shown||ports.some(port=>!project.services.some(service=>(service.listeners||[]).some(owner=>owner.port===port))))box.append(el('span','','Для остальных портов проверьте владельца в терминале.'));
  return box;
}
function worktreeRow(project,onSelectionChange){
  const wrap=el('div');const row=el('div','worktree-row');
  const worktreeName=(project.source?project.source+' · ':'')+project.branch;
  const selection=el('label','worktree-selection');const checkbox=el('input','worktree-checkbox');checkbox.type='checkbox';checkbox.checked=selectedWorktrees.has(project.id);checkbox.disabled=bulkDeleting||!canDeleteWorktree(project);selection.classList.toggle('disabled',checkbox.disabled);checkbox.setAttribute('aria-label','Выбрать worktree '+worktreeName+' для удаления');checkbox.onchange=()=>{if(checkbox.checked)selectedWorktrees.add(project.id);else selectedWorktrees.delete(project.id);onSelectionChange()};selection.append(checkbox);
  const info=el('div','worktree-info');info.append(el('strong','',worktreeName),el('small','',displayPath(project.root)));selection.append(info);
  if(project.created_at){const created=new Date(project.created_at*1000);const date=el('time','worktree-date',created.toLocaleDateString('ru-RU'));date.dateTime=created.toISOString();date.title='Создан (по локальным метаданным): '+created.toLocaleString('ru-RU');selection.append(date)}row.append(selection);
  const flags=worktreeFlags.get(project.id);if(flags){const indicators=el('span','worktree-flags');for(const [key,symbol,label] of [['dirty','✎','Изменены файлы под контролем Git'],['untracked','＋','Новые файлы, не добавленные в Git'],['unpushed','↑','Текущий коммит не найден в локально известных удалённых ветках']])if(flags[key]){const badge=el('span','',symbol);badge.dataset.tooltip=label;badge.tabIndex=0;badge.setAttribute('role','img');badge.setAttribute('aria-label',label);badge.onmouseenter=showFlagTooltip;badge.onfocus=showFlagTooltip;badge.onmouseleave=hideFlagTooltip;badge.onblur=hideFlagTooltip;indicators.append(badge)}row.append(indicators)}
  const canStop=project.services.some(s=>s.pid);const operation=pending.get(project.id);const controlText=operation?{start:'Запускается…',stop:'Останавливается…',delete:'Удаляется…',release_port:'Освобождается…'}[operation]:project.state==='conflict'?'Конфликт порта':canStop?project.state==='degraded'?'⚠ Остановить':'■ Остановить':'▶ Запустить';
  const control=el('button',canStop?'danger':project.state==='conflict'?'':'primary',controlText);control.title=(labels[project.state]||project.state)+' · '+(canStop?'остановить':'запустить')+' worktree '+worktreeName;
  control.disabled=pending.has(project.id)||(!canStop&&project.state==='conflict');control.onclick=()=>act(project.id,canStop?'stop':'start');row.append(control);
  const front=Object.values(project.links)[0];if(front&&canStop){const link=el('a','button','Открыть ↗');link.href=front;link.target='_blank';link.rel='noopener';row.append(link)}
  const remove=el('button','worktree-remove');remove.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M9 7V4h6v3m3 0-1 13H7L6 7m4 4v6m4-6v6"/></svg>';remove.setAttribute('aria-label','Удалить worktree '+worktreeName);
  remove.disabled=bulkDeleting||!canDeleteWorktree(project);
  remove.title=!flags?'Проверка файлов…':flags.detached&&flags.unpushed?'Текущий коммит не найден в локально известных удалённых ветках':project.state!=='stopped'?'Сначала остановите worktree':flags.dirty||flags.untracked?'Удалить checkout и локальные изменения; ветка останется':'Удалить checkout; ветка останется';
  remove.onclick=()=>{if(window.confirm('Удалить worktree '+worktreeName+'? Локальный checkout исчезнет, ветка останется.'+(flags.dirty?' Незафиксированные изменения отслеживаемых файлов будут потеряны.':'')+(flags.untracked?' Новые файлы вне Git будут удалены.':'')+(flags.ignored?' Игнорируемые локальные файлы, включая возможные .env и зависимости, будут удалены.':'')+(flags.unpushed?' Текущий коммит не найден в локально известных удалённых ветках.':'')))act(project.id,'delete',undefined,flags.dirty||flags.untracked||flags.ignored?project.branch:undefined)};row.append(remove);
  if(project.services.length){
    const log=el('pre','log worktree-log');const logPanel=el('div','expander-panel');const logInner=el('div','expander-inner');logInner.append(log);logPanel.append(logInner);
    async function loadLog(){try{const parts=await Promise.all(project.services.map(async service=>{const result=await api('/api/logs?project='+encodeURIComponent(project.id)+'&service='+encodeURIComponent(service.id));return service.id+'\\n'+(result.log||'Нет записей')}));log.textContent=parts.join('\\n\\n')}catch(error){log.textContent=error.message}scrollLogToEnd(log)}
    const toggle=el('button','','☷');toggle.title='Журнал '+worktreeName;toggle.setAttribute('aria-label',toggle.title);toggle.onclick=()=>{const open=!openLogs.has(project.id);if(open)openLogs.add(project.id);else openLogs.delete(project.id);logPanel.classList.toggle('expanded',open);logPanel.inert=!open;if(open)loadLog()};row.append(toggle);wrap.append(row,logPanel);logPanel.classList.toggle('expanded',openLogs.has(project.id));logPanel.inert=!openLogs.has(project.id);if(openLogs.has(project.id))loadLog();
  }else wrap.append(row);
  if(project.state==='conflict')wrap.append(conflictDetails(project));
  if(pending.has(project.id)){const progress=el('div','progress worktree-progress');progress.setAttribute('role','progressbar');progress.setAttribute('aria-label','Операция с worktree');wrap.append(progress)}
  if(errors.has(project.id))wrap.append(el('p','worktree-message',errors.get(project.id)));
  return wrap;
}
function card(project,children){
  const article=el('article','card');article.dataset.id=project.id;
  const head=el('div','card-head');head.append(el('div','avatar',project.name.slice(0,1).toUpperCase()));
  const title=el('div','title');title.append(el('strong','',project.name),el('p','',displayPath(project.root)));
  head.append(title,el('span','state '+(pending.has(project.id)?'starting':project.state),pending.has(project.id)?{start:'Запускается',stop:'Останавливается',profile:'Меняется бренд'}[pending.get(project.id)]:labels[project.state]||project.state));
  article.append(head);
  const body=el('div','body');const checks=el('div','checks');
  for(const service of project.services){
    if(service.checks.length){for(const check of service.checks)checks.append(el('span','chip '+(check.ok?'ok':'bad'),check.id))}
    else checks.append(el('span','chip '+(service.state==='running'?'ok':'bad'),service.id));
  }
  for(const check of project.external)checks.append(el('span','chip '+(check.ok?'ok':'bad'),check.id));
  body.append(el('div','section-label','Проверки'),checks);
  const actions=el('div','actions');const canStop=project.services.some(s=>s.pid);
  const control=el('button',canStop?'danger':'primary',canStop?'■ Остановить':'▶ Запустить');
  control.disabled=pending.has(project.id)||(!canStop&&project.state==='conflict');
  control.onclick=()=>act(project.id,canStop?'stop':'start');actions.append(control);
  for(const [name,url] of Object.entries(project.links)){
    const a=el('a','button',name+' ↗');a.href=url;a.target='_blank';a.rel='noopener';actions.append(a);
  }
  if(project.profiles.length){
    const select=el('select');const placeholder=el('option','','Выбрать бренд');placeholder.value='';placeholder.disabled=true;select.append(placeholder);
    for(const name of project.profiles){const option=el('option','',name);option.value=name;select.append(option)}
    select.value=project.profile||'';select.setAttribute('aria-label','Бренд '+project.name);
    select.disabled=pending.has(project.id);select.onchange=()=>act(project.id,'profile',select.value);
    const wrapper=el('label','profile-select');wrapper.append(select,el('span','chevron'));actions.append(wrapper);
  }
  body.append(actions);
  if(project.state==='conflict')body.append(conflictDetails(project));
  if(pending.has(project.id)){
    const operation=el('div','operation',{'start':'Запуск проекта…','stop':'Остановка проекта…','profile':'Смена бренда…',release_port:'Освобождение порта…'}[pending.get(project.id)]);
    const progress=el('div','progress');progress.setAttribute('role','progressbar');progress.setAttribute('aria-label',operation.textContent);
    operation.append(progress);body.append(operation);
  }
  const expanders=el('div','expanders');const logRow=el('div','log-row');const toggle=el('button','log-toggle',(openLogs.has(project.id)?'▾':'▸')+' Журнал запуска');toggle.setAttribute('aria-expanded',String(openLogs.has(project.id)));logRow.append(toggle);expanders.append(logRow);
  let logService=null;
  if(project.services.length>1){
    logService=el('select','log-service');
    for(const service of project.services){const option=el('option','',service.id);option.value=service.id;logService.append(option)}
    logService.value=selectedLogs.get(project.id)||project.services[0].id;
    logService.setAttribute('aria-label','Сервис журнала '+project.name);
    logService.onchange=()=>{selectedLogs.set(project.id,logService.value);if(openLogs.has(project.id))loadLog()};
    logRow.append(logService);
  }
  const log=el('pre','log');const logPanel=el('div','expander-panel');const logInner=el('div','expander-inner');logInner.append(log);logPanel.append(logInner);
  async function loadLog(){
    const service=logService?logService.value:project.services[0].id;
    try{const response=await api('/api/logs?project='+encodeURIComponent(project.id)+'&service='+encodeURIComponent(service));log.textContent=response.log||'Нет записей'}
    catch(error){log.textContent=error.message}
    scrollLogToEnd(log);
  }
  logPanel.classList.toggle('expanded',openLogs.has(project.id));logPanel.inert=!openLogs.has(project.id);
  if(openLogs.has(project.id))loadLog();
  let worktreePanel=null;let worktreeToggle=null;
  if(children.length||project.worktree_sources?.length){
    const active=children.filter(child=>child.services.some(service=>service.pid)).length;
    worktreeToggle=el('button','worktree-toggle',(openWorktrees.has(project.id)?'▾':'▸')+' Worktrees');worktreeToggle.setAttribute('aria-expanded',String(openWorktrees.has(project.id)));
    worktreeToggle.append(el('span','worktree-count',String(children.length)));if(active)worktreeToggle.append(el('span','worktree-count',active+' активн.'));
    worktreeToggle.onclick=()=>{const open=!openWorktrees.has(project.id);if(open)openWorktrees.add(project.id);else openWorktrees.delete(project.id);if(open)openLogs.delete(project.id);setExpanded(worktreeToggle,worktreePanel,open,'Worktrees');if(open)setExpanded(toggle,logPanel,false,'Журнал запуска');if(open&&children.length)loadWorktreeFlags(project.id)};
    expanders.append(worktreeToggle);
    worktreePanel=el('div','expander-panel');const worktreeInner=el('div','expander-inner');if(project.worktree_sources?.length)worktreeInner.append(el('p','worktree-sources',project.worktree_sources.map(source=>source.name+' · '+displayPath(source.root)).join('  /  ')));const worktreeList=el('div','worktree-list');const bulk=el('div','worktree-bulk');const allLabel=el('label');const all=el('input','worktree-checkbox');all.type='checkbox';all.setAttribute('aria-label','Выбрать все доступные worktrees '+project.name);allLabel.append(all,el('span','','Выбрать доступные'));const deleteButton=el('button','danger');deleteButton.onclick=()=>deleteSelectedWorktrees(children);bulk.append(allLabel,deleteButton);worktreeList.append(bulk);
    function updateSelection(){const available=children.filter(canDeleteWorktree);const selected=available.filter(child=>selectedWorktrees.has(child.id));all.checked=available.length>0&&selected.length===available.length;all.indeterminate=selected.length>0&&selected.length<available.length;all.disabled=bulkDeleting||!available.length;deleteButton.disabled=bulkDeleting||!selected.length;deleteButton.textContent=bulkDeleting?'Удаление…':'Удалить выбранные'+(selected.length?' · '+selected.length:'')}
    all.onchange=()=>{for(const child of children)if(canDeleteWorktree(child)){if(all.checked)selectedWorktrees.add(child.id);else selectedWorktrees.delete(child.id)}for(const checkbox of worktreeList.querySelectorAll('.worktree-row .worktree-checkbox'))checkbox.checked=selectedWorktrees.has(checkbox.dataset.id);updateSelection()};
    if(children.length){worktreeList.append(...children.map(child=>{const row=worktreeRow(child,updateSelection);row.querySelector('.worktree-checkbox').dataset.id=child.id;return row}));updateSelection();worktreeInner.append(worktreeList)}else worktreeInner.append(el('p','worktree-empty','Дополнительных worktrees пока нет.'));worktreePanel.append(worktreeInner);worktreePanel.classList.toggle('expanded',openWorktrees.has(project.id));worktreePanel.inert=!openWorktrees.has(project.id);
  }
  toggle.onclick=()=>{const open=!openLogs.has(project.id);if(open)openLogs.add(project.id);else openLogs.delete(project.id);if(open)openWorktrees.delete(project.id);setExpanded(toggle,logPanel,open,'Журнал запуска');if(open&&worktreePanel)setExpanded(worktreeToggle,worktreePanel,false,'Worktrees');if(open)loadLog()};
  const error=el('div','error',errors.get(project.id)||'');body.append(expanders,logPanel,error);if(worktreePanel)body.append(worktreePanel);article.append(body);
  return article;
}
function render(){hideFlagTooltip();const ids=new Set(latestProjects.map(project=>project.id));for(const id of selectedWorktrees)if(!ids.has(id))selectedWorktrees.delete(id);const parents=latestProjects.filter(p=>!p.parent_id);grid.replaceChildren(...parents.map(project=>card(project,latestProjects.filter(child=>child.parent_id===project.id))));grid.setAttribute('aria-busy','false');const counts=[['Работают',parents.filter(p=>p.state==='running').length,'running'],['Остановлены',parents.filter(p=>p.state==='stopped').length,'stopped'],['Внимание',parents.filter(p=>!['running','stopped'].includes(p.state)).length,'attention']];document.querySelector('#summary').replaceChildren(...counts.map(([label,count,state])=>{const metric=el('span','metric '+state);metric.append(el('strong','',String(count)),el('span','',label));return metric}))}
async function refresh(force=false){try{const projects=await api('/api/projects');const snapshot=JSON.stringify(projects);if(force||snapshot!==lastSnapshot){latestProjects=projects;lastSnapshot=snapshot;render()}for(const id of openWorktrees)loadWorktreeFlags(id,force===true);document.querySelector('#banner').textContent='На связи';document.querySelector('#banner').classList.remove('offline','loading')}catch(error){document.querySelector('#banner').textContent='Нет связи: '+error.message;document.querySelector('#banner').classList.remove('loading');document.querySelector('#banner').classList.add('offline');if(!lastSnapshot){grid.replaceChildren(el('p','load-error','Не удалось загрузить проекты. Проверьте соединение и обновите страницу.'));grid.setAttribute('aria-busy','false');document.querySelector('#summary').textContent='Нет данных'}}}
grid.replaceChildren(...Array.from({length:4},skeletonCard));document.querySelector('#refresh').onclick=refresh;refresh();setInterval(refresh,5000);
</script></body></html>"""


def serve(config_path, port, origin=None):
    local_origin = f"http://127.0.0.1:{port}"
    origins = {local_origin}
    if origin:
        parsed = urlsplit(origin)
        if parsed.scheme != "http" or not parsed.hostname or parsed.username or parsed.password or parsed.path or parsed.query or parsed.fragment:
            raise core.ProjectError("Dashboard origin must be an http URL without a path")
        origins.add(origin)
    hosts = {urlsplit(value).netloc for value in origins}
    token = secrets.token_urlsafe(24)

    class Handler(BaseHTTPRequestHandler):
        def _trusted_host(self):
            return self.headers.get("Host") in hosts

        def _send(self, code, data, content_type="application/json"):
            body = data if isinstance(data, bytes) else json.dumps(data, ensure_ascii=False).encode()
            self.send_response(code)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Frame-Options", "DENY")
            if self._trusted_host():
                self.send_header("X-Devkit-Token", token)
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if not self._trusted_host():
                self._send(403, {"error": "Forbidden"})
                return
            path = urlsplit(self.path)
            try:
                if path.path == "/":
                    page = PAGE.replace("__TOKEN__", json.dumps(token)).replace("__HOME__", json.dumps(str(Path.home())))
                    self._send(200, page.encode(), "text/html; charset=utf-8")
                elif path.path == "/favicon.svg":
                    self._send(200, FAVICON, "image/svg+xml")
                elif path.path == "/api/projects":
                    projects = core.load_config(config_path)
                    self._send(200, [core.status(project) for project in projects])
                elif path.path == "/api/worktree-flags":
                    projects = core.load_config(config_path)
                    parent = core.find_project(projects, parse_qs(path.query)["project"][0])
                    if parent.get("parent_id") or "worktrees" not in parent:
                        raise core.ProjectError("Project has no managed worktrees")
                    self._send(200, [core.worktree_flags(project) for project in projects if project.get("parent_id") == parent["id"]])
                elif path.path == "/api/logs":
                    projects = core.load_config(config_path)
                    query = parse_qs(path.query)
                    project = core.find_project(projects, query["project"][0])
                    self._send(200, {"log": core.logs(project, query["service"][0])})
                else:
                    self._send(404, {"error": "Not found"})
            except (core.ProjectError, KeyError, IndexError) as error:
                self._send(400, {"error": str(error)})

        def do_POST(self):
            if not self._trusted_host() or self.path != "/api/action" or self.headers.get("X-Devkit-Token") != token or self.headers.get("Origin") not in (None, *origins):
                self._send(403, {"error": "Forbidden"})
                return
            try:
                size = int(self.headers.get("Content-Length", "0"))
                if size > 4096:
                    raise ValueError("Request too large")
                data = json.loads(self.rfile.read(size))
                projects = core.load_config(config_path)
                project = core.find_project(projects, data["project"])
                if data["action"] == "start":
                    result = core.start(project)
                elif data["action"] == "stop":
                    result = core.stop(project)
                elif data["action"] == "release_port":
                    result = core.release_port(project, data["port"], data["pid"], data["birth"])
                elif data["action"] == "profile":
                    result = core.select_profile(project, data["profile"])
                elif data["action"] == "delete":
                    if not project.get("parent_id"):
                        raise core.ProjectError("Only worktrees can be deleted")
                    result = core.remove_worktree(project, core.find_project(projects, project["parent_id"]), data.get("confirmation"))
                else:
                    raise core.ProjectError("Unknown action")
                self._send(200, result)
            except (core.ProjectError, ValueError, KeyError, OSError) as error:
                self._send(400, {"error": str(error)})

        def log_message(self, *_):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Dashboard: {origin or local_origin}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
