const stride = 48;
const focusZoom = 1.68;

const palette = {
  A: ["#b86e50", "#543e35"], B: ["#7778a6", "#3b3e51"],
  C: ["#bf984d", "#59492d"], D: ["#588682", "#463e36"],
};
const fields = {
  p: ["#c4cd8c", "#657b3b"],
  q: ["#c9b1be", "#794d7e"],
  r: ["#d4b586", "#9e5140"],
};
function point(value) {
  return Array.isArray(value) ? value : [value.x, value.y];
}

function rect(ctx, color, x, y, width, height) {
  ctx.fillStyle = color;
  ctx.fillRect(x, y, width, height);
}

function tree(ctx, x, y, shade) {
  const leaf = shade ? "#71915b" : "#4e7458";
  rect(ctx, "#78985f", x - 14, y + 13, 34, 9);
  rect(ctx, "#74533e", x - 3, y + 1, 7, 18);
  rect(ctx, "#3d634b", x - 17, y - 11, 35, 24);
  rect(ctx, leaf, x - 18, y - 16, 33, 23);
  rect(ctx, leaf, x - 11, y - 22, 20, 33);
  rect(ctx, shade ? "#94a76a" : "#75965f", x - 13, y - 14, 12, 7);
  rect(ctx, "#adc072", x - 8, y - 18, 7, 4);
}

function cottage(ctx, x, y, shirt) {
  rect(ctx, "#889362", x - 20, y + 10, 41, 7);
  rect(ctx, "#edd5a5", x - 16, y - 9, 31, 25);
  rect(ctx, "#9e784f", x + 3, y + 3, 7, 13);
  rect(ctx, "#a0a785", x - 11, y + 1, 9, 8);
  rect(ctx, "#5a5241", x - 19, y - 14, 38, 5);
  rect(ctx, shirt, x - 17, y - 20, 34, 7);
  rect(ctx, shirt, x - 11, y - 25, 22, 6);
  rect(ctx, shirt, x - 5, y - 30, 10, 5);
  rect(ctx, "#f0d2a7", x - 8, y - 23, 8, 2);
}

function tileTexture(ctx, x, y, i) {
  const x0 = x * stride, y0 = y * stride;
  const tints = ["#aec37e", "#a6bd76", "#acc17a", "#a1b975", "#a8bc77"];
  rect(ctx, tints[i % tints.length], x0, y0, stride, stride);
  rect(ctx, "#738d5a35", x0, y0 + stride - 1, stride, 1);
  rect(ctx, "#718e5835", x0 + stride - 1, y0, 1, stride);
  const u = x0 + 5 + (i * 17) % 30;
  const v = y0 + 8 + (i * 11) % 29;
  rect(ctx, "#7e9b5e", u, v, 2, 6);
  rect(ctx, "#8da766", u + 2, v + 3, 3, 2);
  if (i % 4 === 0) rect(ctx, i % 8 ? "#e4d5a0" : "#f7dfa1", u, v - 2, 2, 2);
}

function paintLandscape(terrain, world) {
  const ctx = terrain.getContext("2d");
  const {width, height, walls, homes} = world.map;
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) tileTexture(ctx, x, y, x * 31 + y * 53 + x * y * 7);
  }
  // Small sandy landings connect the homes to the surrounding grass.
  ctx.lineJoin = "round";
  ctx.lineCap = "square";
  ctx.strokeStyle = "#82905b70";
  ctx.lineWidth = 17;
  const loop = [[2, 2], [2, 4], [4, 4], [4, 6], [6, 6], [6, 5], [8, 5], [8, 7], [9, 7]];
  const upper = [[4, 4], [9, 4], [9, 2]];
  const roads = new Path2D();
  [loop, upper].forEach((road) => road.forEach(([x, y], i) =>
    roads[i === 0 ? "moveTo" : "lineTo"](x * stride + 24, y * stride + 25)));
  ctx.stroke(roads);
  ctx.strokeStyle = "#ded2a3";
  ctx.lineWidth = 13;
  ctx.stroke(roads);
  ctx.strokeStyle = "#eae0b6";
  ctx.setLineDash([3, 10]);
  ctx.lineWidth = 1.5;
  ctx.stroke(roads);
  ctx.setLineDash([]);
  for (const [i, wall] of walls.entries()) {
    const [x, y] = point(wall).map((value) => value * stride + 24);
    tree(ctx, x, y, i % 2 === 0);
  }
  for (const [name, home] of Object.entries(homes ?? {})) {
    const [x, y] = point(home).map((value) => value * stride + 24);
    cottage(ctx, x + 10, y + 14, palette[name][0]);
  }
}

function plot(ctx, id, site) {
  const x = site.x * stride + 24, y = site.y * stride + 24;
  const [soil, crop] = fields[id];
  rect(ctx, "#8b9168", x - 20, y - 12, 40, 29);
  rect(ctx, soil, x - 18, y - 14, 36, 28);
  rect(ctx, soil, x - 15, y - 16, 30, 30);
  for (let offset = -12; offset <= 12; offset += 6) {
    rect(ctx, crop, x + offset, y + 1, 2, 7);
    if (!site.available) continue;
    rect(ctx, crop, x + offset - 1, y - 7 - Math.abs(offset % 4), 4, 9);
    rect(ctx, id === "r" ? "#d98965" : "#f2dea6", x + offset, y - 6 - Math.abs(offset % 4), 2, 2);
  }
}

function sprite(ctx, resident, x, y, walker) {
  const bounce = walker ? 1 : 0;
  y -= bounce;
  const [shirt, hair] = palette[resident.id];
  rect(ctx, "#45523955", x - 8, y + 10, 16, 4);
  rect(ctx, "#3b4941", x - 5, y + 8 - bounce, 4, 4);
  rect(ctx, "#3b4941", x + 2, y + 8 + bounce, 4, 4);
  rect(ctx, "#44503d", x - 7, y, 14, 10);
  rect(ctx, shirt, x - 6, y - 1, 12, 9);
  rect(ctx, "#f3c89b", x - 5, y - 12, 11, 12);
  rect(ctx, hair, x - 6, y - 14, 13, 6);
  rect(ctx, hair, x - 6, y - 9, 2, 5);
  rect(ctx, hair, x + 2, y - 6, 2, 2);
  rect(ctx, "#f4e5ba", x - 4, y + 1, 4, 2);
}

export const cueNames = {
  rest: "歇息", listen: "留意符号", hint: "留意你的建议",
  explore: "去探索", forage: "去找食物", return: "回营地",
};

function drawCue(ctx, cue, x, y) {
  rect(ctx, "#f9edcb", x - 8, y - 8, 16, 14);
  rect(ctx, "#f9edcb", x - 3, y + 6, 4, 2);
  ctx.strokeStyle = "#44533e";
  ctx.lineWidth = 1.25;
  ctx.beginPath();
  if (cue === "rest") {
    ctx.moveTo(x - 4, y - 3); ctx.lineTo(x + 4, y - 3);
    ctx.moveTo(x - 4, y + 1); ctx.lineTo(x + 1, y + 1);
  } else if (cue === "listen") {
    ctx.arc(x - 2, y - 1, 3, -1, 1);
    ctx.moveTo(x + 2, y - 6); ctx.quadraticCurveTo(x + 8, y - 1, x + 2, y + 4);
  } else if (cue === "hint") {
    ctx.moveTo(x, y + 4); ctx.bezierCurveTo(x - 11, y - 7, x + 11, y - 7, x, y + 4);
  } else if (cue === "explore") {
    ctx.moveTo(x - 4, y + 4); ctx.lineTo(x + 3, y + 1);
    ctx.lineTo(x + 5, y - 5); ctx.lineTo(x - 1, y - 2); ctx.closePath();
  } else if (cue === "forage") {
    ctx.moveTo(x, y + 4); ctx.lineTo(x, y - 3);
    ctx.moveTo(x, y); ctx.quadraticCurveTo(x - 5, y, x - 5, y - 4);
    ctx.moveTo(x, y - 1); ctx.quadraticCurveTo(x + 5, y - 1, x + 4, y - 5);
  } else {
    ctx.moveTo(x - 5, y - 1); ctx.lineTo(x, y - 6); ctx.lineTo(x + 5, y - 1);
    ctx.moveTo(x - 4, y - 2); ctx.lineTo(x - 4, y + 4);
    ctx.lineTo(x + 4, y + 4); ctx.lineTo(x + 4, y - 2);
  }
  ctx.stroke();
}

function pose(person, group) {
  const slot = group.indexOf(person);
  const offsetX = group.length > 1 ? (slot % 2 ? 9 : -9) : 0;
  const offsetY = group.length > 2 ? (slot > 1 ? 7 : -6) : 0;
  return {x: person.x * stride + 24 + offsetX, y: person.y * stride + 24 + offsetY};
}

function between(track, now) {
  const progress = track.duration ? Math.max(0, Math.min(1, (now - track.start) / track.duration)) : 1;
  return {
    x: track.from.x + (track.to.x - track.from.x) * progress,
    y: track.from.y + (track.to.y - track.from.y) * progress,
    progress,
  };
}

function camera(width, height, followedPose) {
  if (!followedPose) return {x: width / 2, y: height / 2, zoom: 1};
  const padX = width / (2 * focusZoom), padY = height / (2 * focusZoom);
  return {
    x: Math.max(padX, Math.min(width - padX, followedPose.x)),
    y: Math.max(padY, Math.min(height - padY, followedPose.y)),
    zoom: focusZoom,
  };
}

export function createTileView(canvas, summary, beat, select) {
  const ctx = canvas.getContext("2d");
  const terrain = document.createElement("canvas");
  const {width, height} = canvas;
  terrain.width = width;
  terrain.height = height;
  const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
  let currentFrame;
  let raf;
  let tracks = new Map();
  let visible = [];
  let currentCamera;

  function paint(now) {
    const {world, followed, selected, cues, glyphs} = currentFrame;
    const poses = new Map();
    for (const [id, track] of tracks) poses.set(id, between(track, now));
    currentCamera = camera(width, height, poses.get(followed));
    const {x, y, zoom} = currentCamera;
    canvas.dataset.viewX = x / stride;
    canvas.dataset.viewY = y / stride;
    canvas.dataset.zoom = zoom;
    canvas.dataset.follow = followed || "overview";
    canvas.dataset.tick = world.tick;
    ctx.setTransform(zoom, 0, 0, zoom, width / 2 - x * zoom, height / 2 - y * zoom);
    ctx.drawImage(terrain, 0, 0);
    Object.entries(world.places).forEach(([id, site]) => plot(ctx, id, site));

    const edge = {top: y - height / (2 * zoom), left: x - width / (2 * zoom),
      bottom: y + height / (2 * zoom), right: x + width / (2 * zoom)};
    visible = [...poses].filter(([, p]) => p.x >= edge.left && p.x <= edge.right && p.y >= edge.top && p.y <= edge.bottom)
      .sort(([, a], [, b]) => a.y - b.y);
    for (const [id, p] of visible) {
      if (id === selected) rect(ctx, "#f5e5a8", p.x - 9, p.y + 11, 18, 3);
      sprite(ctx, world.residents[id], p.x, p.y, p.progress < 1 && Math.floor(p.progress * 6) % 2);
    }
    for (const [id, p] of visible) {
      const busy = visible.some(([other, pose]) => other !== id && Math.abs(pose.x - p.x) < 20 && pose.y < p.y && p.y - pose.y < 22);
      const cueX = Math.max(edge.left + 9, Math.min(edge.right - 9, p.x + (busy ? 13 : 0)));
      const cueY = Math.max(edge.top + 9, p.y - 25 + (busy ? 12 : 0));
      drawCue(ctx, cues[id], cueX, cueY);
      const glyph = glyphs.get(id);
      if (glyph && cueX + 24 < edge.right) {
        rect(ctx, "#e8ddf0", cueX + 9, cueY - 8, 15, 14);
        ctx.fillStyle = "#4d3d56";
        ctx.font = "bold 12px system-ui";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(glyph, cueX + 16.5, cueY - 1);
      }
    }
    const description = visible.map(([id]) => `${world.residents[id].name}${cueNames[cues[id]]}`).join(" · ");
    if (summary.textContent !== description) summary.textContent = description;
    if ([...poses.values()].some((p) => p.progress < 1)) raf = requestAnimationFrame(paint);
  }

  function render(world, followed, selected, cues, animate) {
    cancelAnimationFrame(raf);
    if (!currentFrame || currentFrame.seed !== world.seed) paintLandscape(terrain, world);
    const glyphs = new Map();
    world.events.filter((event) => event.glyph && event.sender && world.tick - event.tick < 4)
      .forEach(({sender, glyph}) => glyphs.set(sender, glyph));
    currentFrame = {world, followed, selected, cues, glyphs, seed: world.seed};
    const now = performance.now();
    const tween = animate && !reducedMotion.matches;
    const residents = Object.values(world.residents);
    tracks = new Map(residents.map((person) => {
      const group = residents.filter((peer) => peer.x === person.x && peer.y === person.y);
      const to = pose(person, group);
      const old = tracks.get(person.id);
      if (tween && old && old.to.x === to.x && old.to.y === to.y) return [person.id, old];
      const from = tween && old ? between(old, now) : to;
      const adjacent = old && Math.abs(old.tileX - person.x) + Math.abs(old.tileY - person.y) === 1;
      return [person.id, {to, from, start: now, duration: tween && adjacent ? beat * person.traits.speed : 0,
        tileX: person.x, tileY: person.y}];
    }));
    paint(now);
  }

  canvas.addEventListener("click", (event) => {
    if (!currentCamera) return;
    const bounds = canvas.getBoundingClientRect();
    const scale = bounds.width / width;
    const {x, y, zoom} = currentCamera;
    const atX = x + ((event.clientX - bounds.left) / scale - width / 2) / zoom;
    const atY = y + ((event.clientY - bounds.top) * height / bounds.height - height / 2) / zoom;
    let hit;
    let best = Math.max(14, 12 / (scale * zoom));
    for (const [id, p] of visible) {
      const distance = Math.hypot(atX - p.x, Math.max(0, Math.abs(atY - p.y + 2) - 8));
      if (distance < best) {
        best = distance;
        hit = id;
      }
    }
    if (hit) select(hit);
  });

  return {render};
}
