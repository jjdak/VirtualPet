import { RULE_VERSION, PLACES, NAMES, createWorld, cloneWorld, step, suggest, mindView } from "./world.mjs";
import { createTileView, cueNames } from "./tile-view.mjs";

const $ = (id) => document.getElementById(id);
const key = "virtualpet-w6";

const beat = 380;
const windowSize = 12;
let latest;
let view;
let fork;
let playing = false;
let timer;
let work = null;
let note = "";
let storageIssue = "";
let written = "";
let saveTimer;
let resident = "B";
let mindBranch = "actual";
const branches = ["actual", "baseline"];
const maps = Object.fromEntries(branches.map((branch) => [
  branch, createTileView($(`${branch}-map`), $(`${branch}-summary`), beat, (id) => selectResident(id, branch, true)),
]));

function element(tag, text, className) {
  const node = document.createElement(tag);
  if (text) node.textContent = text;
  if (className) node.className = className;
  return node;
}

function drawNotebook(world) {
  $("hint-note").textContent = fork ?
    `第 ${fork.input.tick} 步，你选择了${PLACES[fork.input.place].name}。` :
    "可以在眼前这一刻私下建议一个地点。";
  const items = world.events.slice(-5).reverse().map((event) => {
    const item = element("li", event.text);
    item.dataset.type = event.type;
    item.prepend(element("small", `第 ${event.tick} 步`));
    return item;
  });
  if (items.length === 0) items.push(element("li", "庭院里还很安静。"));
  $("events").replaceChildren(...items);
  const landmarks = Object.entries(world.places).map(([id, item]) => {
    const label = element("span", `${PLACES[id].name} · ${item.available ? "有食物" : "待恢复"}`);
    const marker = element("i", "", `place-icon icon-${id}`);
    marker.setAttribute("aria-hidden", "true");
    label.prepend(marker);
    return label;
  });
  $("landmark-key").replaceChildren(...landmarks);
}

function selectResident(id, branch = mindBranch, fromMap = false) {
  resident = id;
  mindBranch = branch;
  $("mind-context").open = true;
  draw();
  if (fromMap && matchMedia("(max-width: 680px)").matches) {
    const thought = $("mind-summary").getBoundingClientRect();
    if (thought.top < 0 || thought.bottom > window.innerHeight) {
      $("resident-mind").scrollIntoView({block: "start"});
    }
  }
}

const residentButtons = Object.fromEntries(Object.entries(NAMES).map(([id, name]) => {
  const node = element("li");
  const button = element("button", name);
  const marker = element("i", "", `resident-icon icon-${id}`);
  marker.setAttribute("aria-hidden", "true");
  button.type = "button";
  button.dataset.resident = id;
  button.prepend(marker);
  button.addEventListener("click", () => selectResident(id));
  node.append(button);
  $("residents").append(node);
  return [id, button];
}));

function drawInspector(mind) {
  const world = view[mindBranch] ?? view.actual;
  const person = world.residents[resident];
  const {curiosity, speed, sight} = person.traits;
  const {cue, summary, details, growth} = mind;
  for (const [id, button] of Object.entries(residentButtons)) {
    button.setAttribute("aria-pressed", String(id === resident));
  }
  $("mind-branch").hidden = !view.baseline;
  $("mind-branch-label").hidden = !view.baseline;
  $("mind-branch").value = mindBranch;
  const perspective = $("camera").value === "follow" ? `跟随${person.name}` : `观察${person.name}`;
  $("camera-subject").textContent = `${perspective} · ${cueNames[cue]} · 成长 ${growth.earned} / ${growth.total}`;
  $("mind-name").textContent = person.name;
  $("resident-mind").dataset.cue = cue;
  $("resident-mind").dataset.branch = mindBranch;
  $("mind-summary").textContent = `${cueNames[cue]} · ${summary}`;
  $("mind-details").replaceChildren(...[
    `好奇 ${Math.round(curiosity * 100)}％ · 走一格用 ${speed} 步 · 能看 ${sight} 格 · 已出发 ${person.tripCount} 趟`,
    ...details,
  ].map((detail) => element("li", detail)));
  $("growth-status").textContent = `成长阶段 ${growth.earned} / ${growth.total}`;
  $("growth-stages").replaceChildren(...growth.milestones.map((milestone) => {
    const node = element("li");
    const medal = element("span", milestone.earnedAt == null ? "○" : "◆", "medal");
    medal.setAttribute("aria-hidden", "true");
    node.dataset.milestone = milestone.id;
    if (milestone.earnedAt != null) node.dataset.earnedAt = milestone.earnedAt;
    const title = element("strong", milestone.title);
    const result = milestone.earnedAt == null ? `${milestone.progress} / ${milestone.target}` : `第 ${milestone.earnedAt} 步达成`;
    node.append(medal, title, element("small", result), element("p", milestone.description));
    return node;
  }));
}

function elapsedLabel(trip) {
  return `提醒后 +${trip.departure - fork.input.tick} 步出发`;
}

function foodResult(trip) {
  if (trip.arrived == null) return "在路上";
  if (trip.reward == null || trip.reward === 0) return "到时没有食物";
  return trip.reward > 0 ? "亲历 · 感觉不错" : "亲历 · 感到不适";
}

function describeTrip(trip, branch) {
  const cell = element("td");
  cell.dataset.branch = branch;
  if (!trip) {
    cell.textContent = "此刻还没有对应记录";
    return cell;
  }
  cell.dataset.place = trip.place;
  cell.dataset.departure = trip.departure;
  cell.dataset.reward = trip.reward ?? "";
  cell.append(
    element("strong", PLACES[trip.place].name),
    element("small", elapsedLabel(trip)),
    element("small", foodResult(trip)),
  );
  return cell;
}

function compare(actual, baseline) {
  if (!actual || !baseline) return "还不能对照";
  const details = [];
  if (actual.place !== baseline.place) details.push("去处不同");
  const delta = actual.departure - baseline.departure;
  if (delta !== 0) details.push(`提醒侧${delta > 0 ? "晚" : "早"} ${Math.abs(delta)} 步`);
  if (actual.arrived != null && baseline.arrived != null) {
    if (actual.reward !== baseline.reward) details.push("亲历不同");
  } else {
    details.push("等待两边亲历");
  }
  return details.length ? details.join(" · ") : "当前相同";
}

function drawComparison() {
  $("comparison").hidden = !fork;
  $("baseline").hidden = !fork;
  $("actual-title").hidden = !fork;
  $("maps").classList.toggle("paired", Boolean(fork));
  if (!fork) return;
  $("actual-title").textContent = view.scheduled ? "提醒前" : "给了提醒";
  const behind = view !== latest;
  $("present").hidden = !behind;
  $("rewind").disabled = Boolean(work) || view.scheduled;
  $("present").disabled = Boolean(work);
  $("comparison-note").textContent = view.scheduled ?
    `已回到第 ${fork.input.tick} 步，提醒还没发出。继续时只有左边会收到提醒。` :
    `从第 ${fork.input.tick} 步提醒前的同一状态分开，目前两边都在第 ${view.actual.tick} 步。`;

  const selectTrips = (world) => world.residents.B.trips.filter((trip) => trip.id > fork.tripCount);
  const left = selectTrips(view.actual);
  const right = selectTrips(view.baseline);
  const byId = (all) => new Map(all.map((item) => [item.id, item]));
  const real = byId(left), wait = byId(right);
  const ids = [...new Set([...real.keys(), ...wait.keys()])].sort((a, b) => a - b).slice(-windowSize);
  $("empty-trips").hidden = ids.length > 0;
  $("window-note").textContent = ids[0] > fork.tripCount + 1 ?
    `显示最近至多 ${windowSize} 个序号，更早的趟次已略过。` :
    `按提醒后两边各自第几趟排列，最多显示最近 ${windowSize} 个序号。`;
  $("trips").querySelector("tbody").replaceChildren(...ids.map((id) => {
    const row = element("tr");
    const ordinal = id - fork.tripCount;
    row.dataset.ordinal = ordinal;
    row.dataset.trip = id;
    const label = element("th", String(ordinal));
    label.scope = "row";
    row.append(label, describeTrip(real.get(id), "actual"), describeTrip(wait.get(id), "baseline"),
      element("td", compare(real.get(id), wait.get(id))));
    return row;
  }));
}

function controls() {
  const busy = Boolean(work);
  const rewound = Boolean(fork && view?.scheduled);
  $("play").disabled = !view || work?.type === "restore";
  $("play").textContent = playing || work?.type === "fast" ? "暂停" : "继续观察";
  $("step").disabled = !view || busy;
  $("fast").disabled = !view || busy;
  $("hint").disabled = !view || Boolean(fork) || busy;
  $("place").disabled = !view || Boolean(fork) || busy;
  $("rewind").disabled = !fork || busy || rewound;
  $("present").disabled = busy;
  $("save-status").textContent = storageIssue || (latest ? `种子 ${latest.actual.seed} · 本机自动保存` : "");
  const status = work?.type === "restore" ? work.message :
    work?.type === "fast" ? "正在等小岚下次出发…" :
    playing ? "观察中" : note || "已暂停";
  if ($("status").textContent !== status) $("status").textContent = status;
}

function draw(animate = false) {
  if (view) {
    const tick = view.actual.tick;
    $("clock").dataset.tick = tick;
    $("clock").textContent = `第 ${tick} 步`;
    for (const branch of branches) {
      const world = view[branch];
      if (!world) continue;
      const minds = Object.fromEntries(Object.keys(NAMES).map((id) => [id, mindView(world, id)]));
      const cues = Object.fromEntries(Object.entries(minds).map(([id, mind]) => [id, mind.cue]));
      maps[branch].render(world, $("camera").value === "follow" ? resident : null, resident, cues, animate);
      if (branch === mindBranch) drawInspector(minds[resident]);
    }
    drawNotebook(view.actual);
    drawComparison();
  }
  controls();
}

function recipeOf(world) {
  return {version: RULE_VERSION, seed: world.seed, tick: world.tick, input: world.input};
}

function flushSave() {
  clearTimeout(saveTimer);
  saveTimer = undefined;
  if (!latest) return;
  const serialized = JSON.stringify(recipeOf(latest.actual));
  if (serialized === written) return;
  try {
    localStorage.setItem(key, serialized);
    written = serialized;
    storageIssue = "";
  } catch {
    storageIssue = "本机暂时不能保存";
  }
}

function queueSave() {
  if (!saveTimer) saveTimer = setTimeout(() => {
    flushSave();
    controls();
  }, 650);
}

function takeStep() {
  if (view.scheduled) {
    suggest(view.actual, fork.input.place);
    view.scheduled = false;
  }
  step(view.actual);
  if (view.baseline) step(view.baseline);
  if (view.actual.tick >= latest.actual.tick) {
    latest = view;
    queueSave();
  }
}

function pause() {
  playing = false;
  clearTimeout(timer);
  if (work?.type === "fast") work = null;
  flushSave();
  controls();
}

function playNext() {
  if (!playing) return;
  takeStep();
  draw(true);
  timer = setTimeout(playNext, beat);
}

const yieldControl = () => new Promise((resolve) => setTimeout(resolve, 0));

async function fastForward() {
  pause();
  const task = {type: "fast"};
  const before = view.actual.residents.B.tripCount;
  work = task;
  controls();
  let remaining = 2048;
  while (work === task && remaining > 0 && view.actual.residents.B.tripCount === before) {
    await yieldControl();
    if (work !== task) return;
    const chunk = Math.min(64, remaining);
    for (let index = 0; index < chunk && view.actual.residents.B.tripCount === before; index += 1) {
      takeStep();
      remaining -= 1;
    }
    draw();
  }
  if (work !== task) return;
  work = null;
  note = view.actual.residents.B.tripCount > before ?
    `小岚第 ${view.actual.residents.B.tripCount} 趟出发` : "这段时间小岚还没出发，可以接着等。";
  flushSave();
  draw();
}

function applyHint() {
  pause();
  const place = $("place").value;
  const before = cloneWorld(view.actual);
  if (!suggest(view.actual, place)) return;
  fork = {before, input: {...view.actual.input}, tripCount: before.residents.B.tripCount};
  view.baseline = cloneWorld(before);
  note = "你把地点私下告诉了小岚。";
  flushSave();
  draw();
}

function rewind() {
  pause();
  view = {actual: cloneWorld(fork.before), baseline: cloneWorld(fork.before), scheduled: true};
  note = "回到提醒前，现有进度仍已保留。";
  draw();
}

function present() {
  pause();
  view = latest;
  note = "已回到现在";
  draw();
}

function cleanKeys(data, fields) {
  return data !== null && typeof data === "object" && !Array.isArray(data) &&
    Object.keys(data).length === fields.length && fields.every((field) => Object.hasOwn(data, field));
}

function checkedRecipe(raw) {
  if (raw.length > 512) throw new RangeError("存档无效");
  const recipe = JSON.parse(raw);
  if (!cleanKeys(recipe, ["version", "seed", "tick", "input"]) ||
      recipe.version !== RULE_VERSION ||
      !Number.isInteger(recipe.seed) || recipe.seed < 0 || recipe.seed > 0xffffffff ||
      !Number.isSafeInteger(recipe.tick) || recipe.tick < 0 ||
      (recipe.input !== null && (!cleanKeys(recipe.input, ["tick", "place"]) ||
        !Number.isSafeInteger(recipe.input.tick) || recipe.input.tick < 0 ||
        recipe.input.tick > recipe.tick || typeof recipe.input.place !== "string" ||
        !Object.hasOwn(PLACES, recipe.input.place)))) {
    throw new RangeError("存档无效");
  }
  return recipe;
}

async function restore(recipe) {
  $("seed").value = recipe.seed;
  const task = {type: "restore", message: "正在恢复庭院…"};
  work = task;
  controls();
  const actual = createWorld(recipe.seed);
  let baseline;
  let snapshot;
  while (work === task) {
    const limit = Math.min(recipe.tick, actual.tick + 256);
    for (;;) {
      if (recipe.input && actual.tick === recipe.input.tick && !snapshot) {
        snapshot = cloneWorld(actual);
        baseline = cloneWorld(actual);
        suggest(actual, recipe.input.place);
      }
      if (actual.tick === limit) break;
      step(actual);
      if (baseline) step(baseline);
    }
    if (actual.tick === recipe.tick) break;
    task.message = `正在恢复庭院 · 第 ${actual.tick} / ${recipe.tick} 步`;
    controls();
    await yieldControl();
  }
  if (work !== task) return;
  work = null;
  fork = snapshot ? {before: snapshot, input: actual.input, tripCount: snapshot.residents.B.tripCount} : null;
  view = latest = {actual, baseline};
  note = recipe.tick || recipe.input ? "已恢复上次进度" : "";
  draw();
}

function create(seed, status = "") {
  work = null;
  resident = "B";
  mindBranch = "actual";
  $("camera").value = "follow";
  $("mind-context").open = false;
  pause();
  fork = null;
  const actual = createWorld(seed);
  view = latest = {actual, baseline: null};
  $("seed").value = seed;
  $("place").value = "q";
  note = status;
  flushSave();
  draw();
}

function confirmReset() {
  return !(work || latest?.actual.tick || latest?.actual.input) ||
    window.confirm("当前庭院的进度会被替换。要重新开始吗？");
}

for (const [id, place] of Object.entries(PLACES)) {
  const option = element("option", place.name);
  option.value = id;
  $("place").append(option);
}
$("place").value = "q";
$("play").addEventListener("click", () => {
  if (playing || work?.type === "fast") {
    note = "";
    pause();
    draw();
  } else if (view && !work) {
    playing = true;
    controls();
    timer = setTimeout(playNext, beat);
  }
});
$("step").addEventListener("click", () => {
  pause();
  note = "";
  takeStep();
  flushSave();
  draw();
});
$("fast").addEventListener("click", fastForward);
$("hint").addEventListener("click", applyHint);
$("rewind").addEventListener("click", rewind);
$("present").addEventListener("click", present);
$("world-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const seed = $("seed").valueAsNumber;
  if (Number.isInteger(seed) && seed >= 0 && seed <= 0xffffffff && confirmReset()) create(seed);
});
$("replay").addEventListener("click", () => {
  const seed = latest?.actual.seed ?? $("seed").valueAsNumber;
  if (Number.isInteger(seed) && seed >= 0 && seed <= 0xffffffff && confirmReset()) create(seed);
});
$("camera").addEventListener("change", () => draw());
$("mind-branch").addEventListener("change", () => {
  mindBranch = $("mind-branch").value;
  draw();
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) {
    pause();
    draw();
  }
});
window.addEventListener("pagehide", flushSave);

function start() {
  let raw;
  try {
    raw = localStorage.getItem(key);
  } catch {
    storageIssue = "本机暂时不能读取存档";
  }
  if (raw == null) {
    create(42);
    return;
  }
  try {
    const recipe = checkedRecipe(raw);
    written = JSON.stringify(recipe);
    restore(recipe);
  } catch {
    create(42, "上次存档无法恢复，已打开新庭院。");
  }
}

start();
