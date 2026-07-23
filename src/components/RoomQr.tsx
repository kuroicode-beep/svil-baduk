import { useEffect, useState } from 'react'
import QRCode from 'qrcode'

interface RoomQrProps {
  value: string
  label: string
}

export function RoomQr({ value, label }: RoomQrProps) {
  const [dataUrl, setDataUrl] = useState('')
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    if (!value) {
      setDataUrl('')
      return
    }
    let cancelled = false
    QRCode.toDataURL(value, {
      width: 220,
      margin: 2,
      color: { dark: '#000000', light: '#f5f5f7' },
      errorCorrectionLevel: 'M',
    })
      .then((url) => {
        if (!cancelled) {
          setDataUrl(url)
          setFailed(false)
        }
      })
      .catch(() => {
        if (!cancelled) setFailed(true)
      })
    return () => {
      cancelled = true
    }
  }, [value])

  if (!value) return null

  return (
    <figure className="room-qr">
      <figcaption>{label}</figcaption>
      {failed && <p className="error" role="alert">QR 생성 실패 — ID를 복사해 전달하세요.</p>}
      {dataUrl && (
        <img
          src={dataUrl}
          width={220}
          height={220}
          alt={`방 ID QR: ${value}`}
        />
      )}
    </figure>
  )
}
