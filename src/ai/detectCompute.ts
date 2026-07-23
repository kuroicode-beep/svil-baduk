/** 브라우저에서 KataGo용 GPU/CPU 힌트 (정확 백엔드 선택은 로컬 exe가 함) */

export type ComputeHint = {
  kind: 'gpu' | 'cpu' | 'unknown'
  detail: string
}

export async function detectComputeHint(): Promise<ComputeHint> {
  if (typeof navigator !== 'undefined' && 'gpu' in navigator) {
    try {
      const adapter = await (
        navigator as Navigator & { gpu?: { requestAdapter: () => Promise<unknown> } }
      ).gpu?.requestAdapter()
      if (adapter) {
        return {
          kind: 'gpu',
          detail: 'WebGPU adapter detected — KataGo OpenCL/CUDA recommended',
        }
      }
    } catch {
      /* ignore */
    }
  }

  if (typeof document !== 'undefined') {
    try {
      const canvas = document.createElement('canvas')
      const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl')
      if (gl && gl instanceof WebGLRenderingContext) {
        const dbg = gl.getExtension('WEBGL_debug_renderer_info')
        if (dbg) {
          const renderer = String(gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) || '')
          const vendor = String(gl.getParameter(dbg.UNMASKED_VENDOR_WEBGL) || '')
          const line = `${vendor} ${renderer}`.trim()
          if (/nvidia|geforce|radeon|amd|apple|adreno|mali|intel iris|intel\(r\) arc/i.test(line)) {
            return {
              kind: 'gpu',
              detail: `GPU: ${line} — OpenCL/CUDA KataGo recommended`,
            }
          }
          if (/swiftshader|llvmpipe|software/i.test(line)) {
            return {
              kind: 'cpu',
              detail: `Software GL: ${line} — Eigen (CPU) KataGo may be slower`,
            }
          }
          return { kind: 'unknown', detail: `Graphics: ${line}` }
        }
      }
    } catch {
      /* ignore */
    }
  }

  return {
    kind: 'unknown',
    detail: 'No GPU info — try OpenCL first, fall back to Eigen CPU build',
  }
}
