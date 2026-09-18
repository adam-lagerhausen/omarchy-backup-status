.pragma library

function emptyJob(title, id) {
  return {
    id: id,
    title: title,
    state: "missing",
    running: false,
    lastFinishedAt: 0,
    lastStartedAt: 0,
    nextAt: 0,
    archive: "",
    sqlite: "",
    error: ""
  }
}

function emptyStatus() {
  return {
    ok: false,
    state: "failed",
    linger: false,
    checkedAt: 0,
    lastOffsiteAt: 0,
    quota: { known: false, percent: 0, uniqueLabel: "", quotaLabel: "" },
    jobs: {
      databases: emptyJob("Databases", "databases"),
      workstation: emptyJob("Workstation", "workstation")
    },
    notes: []
  }
}

function parseStatus(raw) {
  try {
    var parsed = JSON.parse(String(raw || ""))
    if (!parsed || parsed.ok !== true) return emptyStatus()
    if (!parsed.jobs) parsed.jobs = emptyStatus().jobs
    if (!parsed.quota) parsed.quota = emptyStatus().quota
    if (!parsed.notes) parsed.notes = []
    return parsed
  } catch (error) {
    return emptyStatus()
  }
}

function relative(unix, nowMs, past, future) {
  var ts = Number(unix || 0)
  if (!ts) return ""
  var now = Number(nowMs || Date.now()) / 1000
  var delta = Math.round(now - ts)
  var abs = Math.abs(delta)
  var phrase = ""
  if (abs < 45) phrase = delta >= 0 ? "just now" : "in a moment"
  else if (abs < 3600) phrase = Math.round(abs / 60) + "m"
  else if (abs < 48 * 3600) {
    var hours = Math.floor(abs / 3600)
    var minutes = Math.round((abs % 3600) / 60)
    phrase = minutes === 0 || hours >= 10 ? hours + "h" : hours + "h " + minutes + "m"
  } else phrase = Math.round(abs / 86400) + "d"
  if (phrase === "just now" || phrase === "in a moment") return phrase
  return delta >= 0 ? past.replace("%s", phrase) : future.replace("%s", phrase)
}

function pillFor(state) {
  if (state === "running") return { text: "RUN", kind: "run" }
  if (state === "failed" || state === "missing") return { text: "FAIL", kind: "fail" }
  if (state === "warning") return { text: "WARN", kind: "warn" }
  return { text: "OK", kind: "ok" }
}

function jobSub(job, nowMs) {
  if (!job) return ""
  if (job.running) {
    var started = relative(job.lastStartedAt, nowMs, "%s ago", "in %s")
    return started ? "Started " + started : "Archive in progress"
  }
  var last = relative(job.lastFinishedAt, nowMs, "%s ago", "in %s")
  var next = relative(job.nextAt, nowMs, "%s ago", "in %s")
  var parts = []
  if (last) parts.push("Last " + last)
  if (next) parts.push("next " + next)
  return parts.join(" · ")
}

function heroMeta(status, nowMs) {
  var state = String(status && status.state || "failed")
  var jobs = status && status.jobs ? status.jobs : {}
  var db = jobs.databases || {}
  var ws = jobs.workstation || {}
  if (state === "running") {
    if (db.running) return "Database archive in progress"
    if (ws.running) return "Workstation archive in progress"
    return "Archive in progress"
  }
  if (state === "failed") {
    if (db.state === "failed" || db.state === "missing")
      return "Database backup failed"
    if (ws.state === "failed" || ws.state === "missing")
      return "Workstation backup failed"
    return "Backup failed"
  }
  var quota = status && status.quota ? status.quota : {}
  if (state === "warning" && quota.known && Number(quota.percent) >= 90)
    return "Jobs ok · repo at " + Math.round(Number(quota.percent)) + "% of quota"
  var last = relative(status && status.lastOffsiteAt, nowMs, "%s ago", "in %s")
  return last ? "Last off-site " + last : "Waiting for the first archive"
}

function present(status, nowMs) {
  var src = status && status.ok ? status : emptyStatus()
  var db = src.jobs.databases || emptyJob("Databases", "databases")
  var ws = src.jobs.workstation || emptyJob("Workstation", "workstation")
  var quota = src.quota || {}
  var pill = pillFor(src.state)
  var notes = src.notes || []
  return {
    state: src.state,
    pill: pill.text,
    pillKind: pill.kind,
    meta: heroMeta(src, nowMs),
    quotaKnown: quota.known === true,
    quotaLeft: "Unique data",
    quotaRight: quota.known
      ? quota.uniqueLabel + " of " + quota.quotaLabel + " · " + quota.percent + "%"
      : "Not in the last log yet",
    quotaPercent: Number(quota.percent || 0),
    databases: {
      title: db.title || "Databases",
      state: db.state,
      pill: pillFor(db.state).text,
      pillKind: pillFor(db.state).kind,
      sub: jobSub(db, nowMs),
      archive: db.archive || "",
      err: db.error || ""
    },
    workstation: {
      title: ws.title || "Workstation",
      state: ws.state,
      pill: pillFor(ws.state).text,
      pillKind: pillFor(ws.state).kind,
      sub: jobSub(ws, nowMs),
      archive: ws.archive || "",
      err: ws.error || ""
    },
    notes: notes,
    showNotes: src.state !== "healthy" && notes.length > 0,
    showQuota: quota.known === true,
    label: pill.text.toLowerCase()
  }
}
