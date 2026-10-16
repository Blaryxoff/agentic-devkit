import json
import secrets
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from . import core


PAGE = """<!doctype html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Локальные проекты</title><style>
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
.log-row { display: flex; align-items: center; flex-wrap: wrap; gap: 12px; margin-top: 16px; }
.log-toggle { align-self: flex-start; min-height: 0; padding: 0; border: 0; background: transparent; color: #829187; font-size: 11px; font-weight: 600; }
.log-toggle:hover:not(:disabled), .log-toggle:focus-visible { border: 0; background: transparent; color: #28764f; text-decoration: underline; }
.log-service { min-height: 30px; padding: 5px 9px; font-size: 11px; }
.log { overflow: auto; max-height: 240px; margin: 13px 0 0; padding: 14px; border-radius: 11px; background: #192922; color: #dcebe0; font: 11px/1.55 ui-monospace, SFMono-Regular, Menlo, monospace; white-space: pre-wrap; }
.log[hidden] { display: none; }
.hint { margin: 13px 0 0; padding: 10px 12px; border: 1px solid #f3e3c7; border-radius: 9px; background: #fffaf0; color: #8d693b; font-size: 11px; line-height: 1.45; }
.error { margin-top: 12px; color: #a74336; font-size: 12px; line-height: 1.45; }
.operation { margin-top: 13px; color: #367756; font-size: 11px; font-weight: 650; }
.progress { overflow: hidden; height: 5px; margin-top: 8px; border-radius: 5px; background: #e3f0e7; }
.progress::after { content: ""; display: block; width: 35%; height: 100%; border-radius: 5px; background: #58a976; animation: load 1.3s ease-in-out infinite; }
@keyframes load { from { transform: translateX(-100%); } to { transform: translateX(290%); } }
@media (prefers-reduced-motion: reduce) {
  .card { transition: none; }
  .card:hover { transform: none; }
  .progress::after { width: 100%; animation: none; }
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
  .avatar { grid-row: span 2; width: 48px; height: 48px; }
  .state { grid-column: 2; justify-self: start; }
  .body { padding: 17px 20px 20px; }
}
</style></head><body><header><div><span class="overline">Локальная разработка</span><h1>Локальные проекты</h1><p>Запускай, останавливай и открывай свои проекты.</p></div><span id="banner">На связи</span></header><div class="summary"><div class="overview"><span>Обзор</span><strong>Мои проекты</strong></div><div id="summary" class="metrics" aria-label="Статусы проектов">Загрузка…</div><button id="refresh" type="button">↻ Обновить</button></div><main id="grid" class="grid"></main>
<script>
let token=__TOKEN__;const home=__HOME__;const grid=document.querySelector('#grid');let latestProjects=[];const pending=new Map();const openLogs=new Set();const selectedLogs=new Map();const errors=new Map();
const labels={running:'Работает',stopped:'Остановлен',starting:'Запускается',degraded:'Требует внимания',conflict:'Конфликт порта'};
function el(tag,cls,text){const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined)node.textContent=text;return node}
function displayPath(path){return path===home?'~':path.startsWith(home+'/')?'~'+path.slice(home.length):path}
async function api(path,options={}){const request=()=>fetch(path,{...options,headers:{'Content-Type':'application/json','X-Devkit-Token':token}});let response=await request();const currentToken=response.headers.get('X-Devkit-Token');if(currentToken&&currentToken!==token){token=currentToken;if(response.status===403&&options.method==='POST')response=await request()}const body=await response.json();if(!response.ok)throw Error(body.error||response.statusText);return body}
async function act(id,action,profile){if(pending.has(id))return;pending.set(id,action);errors.delete(id);render();try{await api('/api/action',{method:'POST',body:JSON.stringify({project:id,action,profile})})}catch(error){errors.set(id,error.message)}finally{pending.delete(id);await refresh()}}
function card(project){
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
  if(project.state==='conflict')body.append(el('p','hint','Порты '+project.services.flatMap(s=>s.busy_ports).join(', ')+' заняты процессами вне панели. Остановите их в терминале, чтобы управлять проектом здесь.'));
  if(pending.has(project.id)){
    const operation=el('div','operation',{'start':'Запуск проекта…','stop':'Остановка проекта…','profile':'Смена бренда…'}[pending.get(project.id)]);
    const progress=el('div','progress');progress.setAttribute('role','progressbar');progress.setAttribute('aria-label',operation.textContent);
    operation.append(progress);body.append(operation);
  }
  const logRow=el('div','log-row');const toggle=el('button','log-toggle','▸ Журнал запуска');logRow.append(toggle);
  let logService=null;
  if(project.services.length>1){
    logService=el('select','log-service');
    for(const service of project.services){const option=el('option','',service.id);option.value=service.id;logService.append(option)}
    logService.value=selectedLogs.get(project.id)||project.services[0].id;
    logService.setAttribute('aria-label','Сервис журнала '+project.name);
    logService.onchange=()=>{selectedLogs.set(project.id,logService.value);if(openLogs.has(project.id))loadLog()};
    logRow.append(logService);
  }
  const log=el('pre','log');log.hidden=!openLogs.has(project.id);
  async function loadLog(){
    const service=logService?logService.value:project.services[0].id;
    try{const response=await api('/api/logs?project='+encodeURIComponent(project.id)+'&service='+encodeURIComponent(service));log.textContent=response.log||'Нет записей'}
    catch(error){log.textContent=error.message}
  }
  toggle.onclick=()=>{if(openLogs.has(project.id))openLogs.delete(project.id);else openLogs.add(project.id);log.hidden=!openLogs.has(project.id);if(!log.hidden)loadLog()};
  if(!log.hidden)loadLog();
  const error=el('div','error',errors.get(project.id)||'');body.append(logRow,log,error);article.append(body);
  return article;
}
function render(){grid.replaceChildren(...latestProjects.map(card));const counts=[['Работают',latestProjects.filter(p=>p.state==='running').length,'running'],['Остановлены',latestProjects.filter(p=>p.state==='stopped').length,'stopped'],['Внимание',latestProjects.filter(p=>!['running','stopped'].includes(p.state)).length,'attention']];document.querySelector('#summary').replaceChildren(...counts.map(([label,count,state])=>{const metric=el('span','metric '+state);metric.append(el('strong','',String(count)),el('span','',label));return metric}))}
async function refresh(){try{latestProjects=await api('/api/projects');render();document.querySelector('#banner').textContent='На связи';document.querySelector('#banner').classList.remove('offline')}catch(error){document.querySelector('#banner').textContent='Нет связи: '+error.message;document.querySelector('#banner').classList.add('offline')}}
document.querySelector('#refresh').onclick=refresh;refresh();setInterval(refresh,5000);
</script></body></html>"""


def serve(projects, port, origin=None):
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
                elif path.path == "/api/projects":
                    self._send(200, [core.status(project) for project in projects])
                elif path.path == "/api/logs":
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
                project = core.find_project(projects, data["project"])
                if data["action"] == "start":
                    result = core.start(project)
                elif data["action"] == "stop":
                    result = core.stop(project)
                elif data["action"] == "profile":
                    result = core.select_profile(project, data["profile"])
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
