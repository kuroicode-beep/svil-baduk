/**
 * 로컬 KataGo GTP HTTP 브리지 (브라우저 ↔ stdin/stdout).
 * 사용: npm run katago:bridge
 * 기본 포트 17419 — CORS 허용(localhost 앱용)
 */
import http from 'node:http'
import { spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const ROOT = path.resolve(__dirname, '..')
const PORT = Number(process.env.KATAGO_BRIDGE_PORT || 17419)

const defaults = {
  exe: process.env.KATAGO_EXE || path.join(ROOT, 'katago', 'bin', 'katago.exe'),
  model: process.env.KATAGO_MODEL || '',
  config: process.env.KATAGO_CONFIG || '',
}

let child = null
let buf = ''
let pending = []
let ready = false

function findDefaultModel() {
  if (defaults.model && fs.existsSync(defaults.model)) return defaults.model
  const dir = path.join(ROOT, 'katago', 'models')
  if (!fs.existsSync(dir)) return ''
  const hit = fs.readdirSync(dir).find((f) => f.endsWith('.bin.gz') || f.endsWith('.bin'))
  return hit ? path.join(dir, hit) : ''
}

function findDefaultConfig() {
  if (defaults.config && fs.existsSync(defaults.config)) return defaults.config
  const candidates = [
    path.join(ROOT, 'katago', 'gtp_play.cfg'),
    path.join(ROOT, 'katago', 'default_gtp.cfg'),
    path.join(ROOT, 'katago', 'bin', 'default_gtp.cfg'),
  ]
  return candidates.find((p) => fs.existsSync(p)) || ''
}

function settleAll(err) {
  const q = pending
  pending = []
  for (const p of q) p.reject(err)
}

function onData(chunk) {
  buf += chunk.toString('utf8')
  while (true) {
    const m = buf.match(/\n\n|\r\n\r\n/)
    if (!m) break
    const idx = m.index
    const block = buf.slice(0, idx).trim()
    buf = buf.slice(idx + m[0].length)
    const line = block
      .split(/\r?\n/)
      .map((l) => l.trim())
      .find((l) => l.startsWith('=') || l.startsWith('?'))
    const waiter = pending.shift()
    if (!waiter) continue
    if (!line) {
      waiter.reject(new Error('empty_gtp'))
      continue
    }
    if (line.startsWith('?')) waiter.reject(new Error(line.slice(1).trim() || 'gtp_error'))
    else waiter.resolve(line.slice(1).trim())
  }
}

function stopKataGo() {
  if (!child) return
  try {
    child.stdin.write('quit\n')
  } catch {
    /* ignore */
  }
  try {
    child.kill()
  } catch {
    /* ignore */
  }
  child = null
  ready = false
  buf = ''
  settleAll(new Error('stopped'))
}

function startKataGo(opts = {}) {
  stopKataGo()
  const exe = opts.exe || defaults.exe
  const model = opts.model || findDefaultModel()
  const config = opts.config || findDefaultConfig()
  if (!fs.existsSync(exe)) {
    throw new Error(`katago_exe_missing: ${exe}`)
  }
  if (!model || !fs.existsSync(model)) {
    throw new Error('katago_model_missing — place .bin.gz in katago/models/')
  }

  const args = ['gtp', '-model', model]
  if (config && fs.existsSync(config)) args.push('-config', config)

  child = spawn(exe, args, { stdio: ['pipe', 'pipe', 'pipe'] })
  ready = true
  child.stdout.on('data', onData)
  child.stderr.on('data', (d) => process.stderr.write(d))
  child.on('exit', () => {
    ready = false
    child = null
    settleAll(new Error('katago_exited'))
  })
  return { exe, model, config: config || null }
}

function sendGtp(line) {
  if (!child || !ready) return Promise.reject(new Error('not_running'))
  return new Promise((resolve, reject) => {
    pending.push({ resolve, reject })
    child.stdin.write(line.trim() + '\n')
  })
}

function json(res, code, body) {
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  })
  res.end(JSON.stringify(body))
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = []
    req.on('data', (c) => chunks.push(c))
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8')
        resolve(raw ? JSON.parse(raw) : {})
      } catch (e) {
        reject(e)
      }
    })
    req.on('error', reject)
  })
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return json(res, 204, {})

  try {
    if (req.method === 'GET' && req.url === '/health') {
      return json(res, 200, {
        ok: true,
        running: !!(child && ready),
        platform: {
          os: process.platform,
          arch: process.arch,
          node: process.version,
        },
        defaults: {
          exe: defaults.exe,
          model: findDefaultModel() || null,
          config: findDefaultConfig() || null,
          hasExe: fs.existsSync(defaults.exe),
          hasModel: !!findDefaultModel(),
        },
      })
    }

    if (req.method === 'POST' && req.url === '/start') {
      const body = await readBody(req)
      const info = startKataGo(body)
      // warm-up
      await sendGtp('protocol_version').catch(() => {})
      return json(res, 200, { ok: true, ...info })
    }

    if (req.method === 'POST' && req.url === '/stop') {
      stopKataGo()
      return json(res, 200, { ok: true })
    }

    if (req.method === 'POST' && req.url === '/gtp') {
      const body = await readBody(req)
      if (!body.line) return json(res, 400, { ok: false, error: 'line_required' })
      const response = await sendGtp(String(body.line))
      return json(res, 200, { ok: true, response })
    }

    json(res, 404, { ok: false, error: 'not_found' })
  } catch (e) {
    json(res, 500, { ok: false, error: e instanceof Error ? e.message : String(e) })
  }
})

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[katago-bridge] http://127.0.0.1:${PORT}`)
  console.log(`[katago-bridge] exe default: ${defaults.exe}`)
  console.log(`[katago-bridge] model: ${findDefaultModel() || '(none)'}`)
})

process.on('SIGINT', () => {
  stopKataGo()
  server.close()
  process.exit(0)
})
