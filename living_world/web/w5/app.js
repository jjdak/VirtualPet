"use strict";

const $ = (id) => document.getElementById(id);
const names = {A: "阿禾", B: "小岚"};
const foods = {p: "青禾地", q: "紫穗地"};
const clothing = {A: "#a95e49", B: "#66678b"};
const marks = {experience: "亲历", hint: "私下建议", message: "分享亲历", decision: "出发"};
const people = {A: $("person-a"), B: $("person-b")};
const beat = 2600;
const namespace = "http://www.w3.org/2000/svg";

let current = null;
let pending = null;
let failed = null;
let playing = false;
let timer;
let drawnEvents = 0;

function svg(tag, attributes, label) {
  const element = document.createElementNS(namespace, tag);
  Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value));
  if (label) element.textContent = label;
  return element;
}

function gridPoint([x, y]) {
  return [85 + x * 59, 73 + y * 46];
}

function translation(point) {
  return `translate(${point.join(" ")})`;
}

function scatterMeadow() {
  const decoration = $("texture");
  for (let i = 0; i < 81; i += 1) {
    const x = 14 + (i * 151) % 732;
    const y = 5 + (i * 83) % 434;
    if ((x > 590 && y > 296) || (y > 128 && y < 283 && x > 95 && x < 648)) continue;
    decoration.append(svg("use", {
      href: "#tuft", transform: `translate(${x} ${y}) scale(${.53 + (i % 4) * .17})`,
      color: i % 3 ? "#6d895a" : "#f0ddab", opacity: .65,
    }));
  }
}

function drawPlaces(map) {
  const places = $("places");
  places.replaceChildren();
  for (const [x, y] of map.walls) {
    const location = gridPoint([x, y]);
    places.append(svg("use", {
      href: "#tree", transform: `${translation(location)} scale(.61)`, color: "#829567",
    }));
  }
  for (const [kind, pos] of Object.entries(map.food)) {
    const field = svg("g", {class: "place field", id: `field-${kind}`, transform: translation(gridPoint(pos))});
    const purple = kind === "q";
    field.append(svg("path", {
      d: "M-63 18Q-65-10-35-16 7-30 49-11 78 4 54 24 7 40-51 30Z",
      fill: purple ? "#c4afc2" : "#b9c58c", stroke: purple ? "#a28c9f" : "#96a379", "stroke-width": 1.5,
    }));
    const stalks = svg("g", {class: "stalks", color: purple ? "#805d89" : "#6f803d"});
    for (let i = 0; i < 18; i += 1) {
      const x = -48 + (i % 9) * 11 + Math.floor(i / 9) * 3;
      const y = 6 + Math.floor(i / 9) * 12 + Math.abs(i % 9 - 4) * .9;
      stalks.append(svg("use", {href: "#grain", transform: `translate(${x} ${y}) rotate(${i % 5 * 8 - 15})`}));
    }
    field.append(stalks, svg("text", {y: 57}, foods[kind]));
    places.append(field);
  }
  for (const [person, pos] of Object.entries(map.home)) {
    const [x, y] = gridPoint(pos);
    const home = svg("g", {class: "place home", transform: translation([x, y + 51])});
    home.append(svg("use", {href: "#cottage", color: clothing[person]}));
    home.append(svg("text", {y: 36}, `${names[person]}的小屋`));
    places.append(home);
  }
}

function where(person, frame) {
  const {phase, target, pos} = frame.people[person];
  if (phase === "homebound") return target ? `从${foods[target]}回小屋` : "在回小屋的路上";
  if (phase === "outbound" && target) return `动身去${foods[target]}`;
  if (frame.map.home[person].every((value, index) => value === pos[index])) return "在小屋前歇息";
  return "在庭院里";
}

function drawMap(frame, fresh) {
  if (fresh) drawPlaces(frame.map);
  for (const [kind, info] of Object.entries(frame.food)) {
    $(`field-${kind}`).dataset.available = info.available;
  }
  const together = frame.people.A.pos.every((value, index) => value === frame.people.B.pos[index]);
  const recent = frame.events.filter((event) => event.tick === frame.start + frame.elapsed);
  for (const [name, resident] of Object.entries(people)) {
    const [x, y] = gridPoint(frame.people[name].pos);
    const shift = together ? (name === "A" ? -24 : 24) : 0;
    if (fresh) resident.classList.add("instant");
    resident.style.transform = `translate(${x + shift}px, ${y}px)`;
    resident.setAttribute("visibility", "visible");
    if (fresh) requestAnimationFrame(() => requestAnimationFrame(() => resident.classList.remove("instant")));
    let cue = "";
    for (const event of recent) {
      if (event.type === "experience" && event.actor === name) cue = event.reward > 0 ? "尝着不错" : "有些不舒服";
      if (event.type === "message" && event.sender === name) cue = name === "A" ? "告诉小岚" : "告诉阿禾";
      if (event.type === "hint" && name === "B") cue = "收到私下提醒";
      if (event.type === "decision" && name === "B") cue = "出发了";
    }
    resident.classList.toggle("signaling", Boolean(cue));
    resident.querySelector(".cue").textContent = cue;
  }
  const positions = Object.keys(people).map((name) => `${names[name]}${where(name, frame)}`).join(" · ");
  $("positions").textContent = positions;
  $("map-description").textContent = `${positions}。两间小屋的北面是青禾地和紫穗地，东南有一方池塘。`;
  const dispatch = $("dispatch-path");
  dispatch.setAttribute("visibility", frame.ended ? "visible" : "hidden");
  if (frame.ended) {
    const to = frame.result.actual.kind;
    const [x, y] = gridPoint(frame.people.B.pos);
    const [toX, toY] = gridPoint(frame.map.food[to]);
    const direction = toX > x ? 1 : -1;
    dispatch.setAttribute("d", `M${x + 20 * direction} ${y} Q${toX} ${y} ${toX} ${toY + 32}`);
    dispatch.setAttribute("stroke", to === "q" ? "#765782" : "#587854");
  }
}

function moment(offset) {
  return offset === 0 ? "开场" : `第 ${offset} 步`;
}

function drawJournal(frame) {
  const journal = $("events");
  for (const event of frame.events.slice(drawnEvents)) {
    const entry = document.createElement("li");
    const time = document.createElement("span");
    const text = document.createElement("p");
    const type = event.type === "decision" && event.actor !== "B" ? "去找吃的" : marks[event.type];
    entry.className = "entry";
    entry.dataset.type = event.type;
    time.textContent = [moment(event.tick - frame.start), type].filter(Boolean).join(" · ");
    const message = event.text.replace(/^(晴天|雨天) · /, "");
    const evidence = event.type === "message" && Object.values(frame.people[event.receiver].heard).find(
      (report) => report.source === event.sender && report.tick === event.evidence_tick,
    );
    const detail = evidence ? (evidence.claim > 0 ? "吃完觉得不错。" : "吃完有些不舒服。") : "";
    text.textContent = message + detail;
    entry.append(time, text);
    journal.append(entry);
  }
  drawnEvents = frame.events.length;
}

function drawResult(frame) {
  const {actual, waiting, first, waiting_first: waitingFirst} = frame.result;
  const decision = frame.events.findIndex((event) => event.type === "decision" && event.actor === "B");
  const heard = [];
  let heardReport = false;
  for (const event of frame.events.slice(0, decision)) {
    const time = moment(event.tick - frame.start);
    if (event.type === "hint") {
      heard.push(`${time}，小岚听到你的私下建议：去紫穗地看看。`);
    }
    if (event.type === "message" && event.sender === "A" && event.receiver === "B" && event.evidence_tick === frame.start) {
      heard.push(`${time}，阿禾告诉小岚，这次尝紫穗感觉不错。`);
      heardReport = true;
    }
  }
  if (!heardReport) heard.push("直到出发，小岚还没听到阿禾这次的紫穗亲历。");
  if (heardReport && frame.hint && first) {
    heard.push(first.speaker === "A" ? "阿禾先开了口。" : "你先开了口。");
  }
  $("result-title").textContent = `小岚出发去${foods[actual.kind]}了`;
  $("heard").textContent = heard.join("");
  const timing = waitingFirst && waitingFirst.speaker === "A" ?
    `她出发前在${moment(waitingFirst.offset)}听到了阿禾的亲历。` : "她出发前还没听到阿禾这次的亲历。";
  let comparison = "";
  if (frame.hint) {
    comparison = actual.kind === waiting.kind ? "这一次，地点没有变。" : "这一次，小岚去了另一个地点。";
  }
  $("baseline").textContent = `如果从同一个开场一直等，小岚会在${moment(waiting.offset)}出发去${foods[waiting.kind]}。${timing}${comparison}`;
  $("result").hidden = false;
}

function draw(frame, fresh) {
  $("clock").textContent = moment(frame.elapsed);
  drawMap(frame, fresh);
  drawJournal(frame);
  if (frame.ended) drawResult(frame);
}

function updateControls() {
  const ended = current?.ended ?? false;
  const unavailable = !current || ended || Boolean(failed);
  $("play").disabled = unavailable || Boolean(pending && !playing);
  $("step").disabled = unavailable || Boolean(pending);
  $("hint").disabled = unavailable || Boolean(current?.hint) || pending?.action === "hint";
  $("play").textContent = playing ? "暂停" : "继续等待";
  $("retry").hidden = !failed;

  const note = ended ? "小岚已经出发。" : current?.hint ? "小岚听见了你的私下建议。" : "出发前，可以私下提醒她一次。";
  $("hint-note").textContent = note;
  const status = failed ? "暂时连不上庭院。可以从刚才那一步重试。" :
    ended ? "本幕结束" :
    !current ? "正在打开庭院…" :
    pending?.action === "hint" ? "正在轻声提醒…" :
    playing ? "等待中" : "已暂停";
  if ($("status").textContent !== status) $("status").textContent = status;
}

function stopPlaying() {
  playing = false;
  clearTimeout(timer);
}

function cancelPending() {
  const request = pending;
  pending = null;
  request?.controller.abort();
}

function queueStep() {
  clearTimeout(timer);
  if (playing && !document.hidden && !current?.ended) {
    timer = setTimeout(() => next("auto"), beat);
  }
}

async function requestFrame(recipe, action) {
  const request = {recipe, action, controller: new AbortController()};
  pending = request;
  failed = null;
  updateControls();
  const timeout = setTimeout(() => request.controller.abort(), 8000);
  try {
    const response = await fetch("/api/frame", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(recipe),
      signal: request.controller.signal,
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const frame = await response.json();
    if (pending !== request) return;
    const fresh = !current;
    draw(frame, fresh);
    current = frame;
    if (frame.ended) stopPlaying();
  } catch {
    if (pending !== request) return;
    failed = request;
    stopPlaying();
  } finally {
    clearTimeout(timeout);
    if (pending === request) {
      pending = null;
      updateControls();
      queueStep();
    }
  }
}

function restart() {
  stopPlaying();
  cancelPending();
  failed = null;
  current = null;
  drawnEvents = 0;
  $("events").replaceChildren();
  $("result").hidden = true;
  $("clock").textContent = "庭院准备中";
  $("positions").textContent = "";
  $("map-description").textContent = "正在打开庭院。";
  $("dispatch-path").setAttribute("visibility", "hidden");
  Object.values(people).forEach((person) => person.setAttribute("visibility", "hidden"));
  requestFrame({opening: $("opening").value, elapsed: 0, hint: null}, "open");
}

function next(action) {
  if (!current || current.ended || pending || failed) return;
  requestFrame({opening: $("opening").value, elapsed: current.elapsed + 1, hint: current.hint}, action);
}

function pause() {
  stopPlaying();
  if (pending?.action === "auto") cancelPending();
  updateControls();
}

$("opening").addEventListener("change", restart);
$("replay").addEventListener("click", restart);
$("play").addEventListener("click", () => {
  if (playing) {
    pause();
  } else {
    playing = true;
    updateControls();
    queueStep();
  }
});
$("step").addEventListener("click", () => {
  stopPlaying();
  next("step");
});
$("hint").addEventListener("click", () => {
  if (!current || current.ended || current.hint || failed || pending?.action === "hint") return;
  stopPlaying();
  cancelPending();
  requestFrame({opening: $("opening").value, elapsed: current.elapsed, hint: {offset: current.elapsed, kind: "q"}}, "hint");
});
$("retry").addEventListener("click", () => {
  if (failed) requestFrame(failed.recipe, failed.action);
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden && playing) pause();
});

scatterMeadow();
restart();
