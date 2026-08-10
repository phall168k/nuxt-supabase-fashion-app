import {
  BakongKHQR,
  MerchantInfo,
  khqrData,
} from 'bakong-khqr'

interface GenerateMerchantOptions {
  amount: number
  billNumber?: string
  bankAccount: string
  merchantName: string
  merchantCity: string
  currency?: string | null
  storeLabel?: string | null
  expirationMinutes?: number
}

const DEFAULT_EXPIRATION_MINUTES = 15

export const verifyKHQR = (payload: string): boolean => {
  const khqr = payload.trim()
  if (!khqr) return false

  try {
    return BakongKHQR.verify(khqr).isValid === true
  }
  catch {
    return false
  }
}

export const generateMerchantKHQR = (
  options: GenerateMerchantOptions,
) => {
  const expirationMinutes = options.expirationMinutes ?? DEFAULT_EXPIRATION_MINUTES
  if (!Number.isFinite(expirationMinutes) || expirationMinutes <= 0) {
    throw new Error('Expiration time must be greater than 0 minutes')
  }

  const expirationTimestamp = Date.now() + expirationMinutes * 60 * 1000
  const billNumber = options.billNumber ?? `SAL-${Date.now()}`
  const currency = options.currency?.trim().toUpperCase() === 'KHR'
    ? khqrData.currency.khr
    : khqrData.currency.usd

  if (!options.bankAccount.trim()) throw new Error('The selected payment method has no bank account')
  if (!options.merchantName.trim()) throw new Error('Merchant name is required')
  if (!options.merchantCity.trim()) throw new Error('Merchant city is required')

  const optionalData = {
    currency,

    amount: options.amount,

    billNumber,

    mobileNumber: '0972444595',

    storeLabel: options.storeLabel?.trim() || options.merchantName.trim(),

    terminalLabel: 'POS-min',

    expirationTimestamp,

    merchantCategoryCode: '5999',
  }

  const merchantInfo = new MerchantInfo(
    options.bankAccount.trim(),

    options.merchantName.trim(),

    options.merchantCity.trim(),

    1243546472,

    'DEVBKKHPXXX',

    optionalData,
  )

  const khqr = new BakongKHQR()

  const response: any =
    khqr.generateMerchant(merchantInfo)

  const qr = response?.data?.qr

  /*
   * Important:
   * The SDK can incorrectly put an Error string
   * inside data.qr.
   */
  if (
    typeof qr !== 'string'
    || !qr.startsWith('000201')
  ) {
    throw new Error(
      typeof qr === 'string'
        ? qr
        : 'Invalid KHQR payload',
    )
  }

  return {
    qr,
    md5: response.data.md5,

    amount: options.amount,
    billNumber,
    expirationMinutes,
    expiresAt: expirationTimestamp,
  }
}
