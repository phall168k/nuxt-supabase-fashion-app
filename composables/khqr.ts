import * as BakongKhqrModule from 'bakong-khqr'

const { BakongKHQR, khqrData } = BakongKhqrModule

// @types/bakong-khqr incorrectly exposes MerchantInfo only as an interface,
// while the package also exports it as a runtime constructor.
const { MerchantInfo } = BakongKhqrModule as unknown as {
  MerchantInfo: new (
    bakongAccountID: string,
    merchantName: string,
    merchantCity: string,
    merchantID: string,
    acquiringBank: string,
    optional?: Record<string, unknown>,
  ) => import('bakong-khqr').MerchantInfo
}
interface MerchantKhqrOptions {
  amount?: number
  billNumber?: string
  expirationMinutes?: number
}

interface MerchantKhqrData {
  qr: string
  md5: string
}

const primitiveString = (value: unknown) => {
  if (typeof value === 'string') return value
  if (value instanceof String) return value.valueOf()
  if (value && typeof value === 'object' && 'toString' in value) {
    const text = String(value)
    if (text !== '[object Object]') return text
  }
  return ''
}

// EMVCo QR uses CRC-16/CCITT-FALSE. Keep this browser-native because the SDK's
// verify() path relies on Node Buffer and can incorrectly fail in Nuxt clients.
const crc16 = (value: string) => {
  let crc = 0xFFFF
  for (const byte of new TextEncoder().encode(value)) {
    crc ^= byte << 8
    for (let bit = 0; bit < 8; bit += 1) {
      crc = crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1
      crc &= 0xFFFF
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0')
}

export const generateMerchantKhqr = (options: MerchantKhqrOptions = {}) => {
  const optionalData = {
    currency: khqrData.currency.usd,
    amount: options.amount ?? 0.5,
    billNumber: options.billNumber ?? '#0001',
    mobileNumber: "0972444595",
    storeLabel: "Phall Shop",
    terminalLabel: "POS-01",
    expirationTimestamp: Date.now() + (options.expirationMinutes ?? 1) * 60 * 1000,
    merchantCategoryCode: "5999", // optional: default value 5999
  };

  const merchantInfo = new MerchantInfo(
      "phal_eom@aclb",
      "phall",
      "Phnom Penh",
      '1243546472',
      "DEVBKKHPXXX",
      optionalData
  );

  const response = new BakongKHQR().generateMerchant(merchantInfo);
  if (response.status.code !== 0 || !response.data) {
    throw new Error(response.status.message || 'Unable to generate merchant KHQR')
  }
  
  const data = response.data as { qr?: unknown; md5?: unknown }
  const qr = primitiveString(data.qr)
  const md5 = primitiveString(data.md5)
  console.log('QR', qr)

  if (!qr.startsWith('000201') || qr.length < 12 || qr.slice(-8, -4) !== '6304') {
    throw new Error('The KHQR SDK returned an invalid QR payload')
  }

  const payloadWithoutChecksum = qr.slice(0, -4)
  const normalizedQr = `${payloadWithoutChecksum}${crc16(payloadWithoutChecksum)}`

  return { qr: normalizedQr, md5 } satisfies MerchantKhqrData
}
