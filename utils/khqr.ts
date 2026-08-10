// utils/khqr.ts

import {
  BakongKHQR,
  khqrData,
  IndividualInfo,
} from 'bakong-khqr'

export interface GenerateIndividualKHQROptions {
  accountId: string
  merchantName: string
  merchantCity?: string

  amount: number
  currency?: 'usd' | 'khr'

  billNumber?: string
  storeLabel?: string
  terminalLabel?: string
  purpose?: string

  expirationMinutes?: number
}

export interface GeneratedKhqr {
  qr: string
  md5: string
  amount: number
  invoiceNumber: string
}

export const generateIndividualKHQR = (
  options: GenerateIndividualKHQROptions,
): GeneratedKhqr => {
  const {
    accountId,
    merchantName,
    merchantCity = 'PHNOM PENH',

    amount,
    currency = 'usd',

    billNumber,
    storeLabel,
    terminalLabel,
    purpose,

    expirationMinutes = 15,
  } = options

  if (!accountId) {
    throw new Error('Bakong account ID is required')
  }

  if (!merchantName) {
    throw new Error('Merchant name is required')
  }

  if (!amount || amount <= 0) {
    throw new Error('Amount must be greater than 0')
  }

  // KHQR SDK requires expiration timestamp in milliseconds.
  const expirationTimestamp = String(
    Date.now() + expirationMinutes * 60 * 1000,
  )

  const optionalData = {
    currency:
      currency.toLowerCase() === 'khr'
        ? khqrData.currency.khr
        : khqrData.currency.usd,

    amount,

    merchantCategoryCode: '5999',

    ...(billNumber && {
      billNumber,
    }),

    ...(storeLabel && {
      storeLabel,
    }),

    ...(terminalLabel && {
      terminalLabel,
    }),

    ...(purpose && {
      purposeOfTransaction: purpose,
    }),

    expirationTimestamp,
  }

  console.log('KHQR optionalData:', optionalData)

  const individualInfo = new IndividualInfo(
    accountId,
    merchantName,
    merchantCity,
    optionalData,
  )

  const khqr = new BakongKHQR()

  const response = khqr.generateIndividual(individualInfo)

  console.log('KHQR SDK response:', response)

  if (response?.status?.code !== 0) {
    throw new Error(
      response?.status?.message ||
      response?.status?.errorCode ||
      'KHQR generation failed',
    )
  }

  const qr = response?.data?.qr
  const md5 = response?.data?.md5

  if (
    typeof qr !== 'string' ||
    !qr.length ||
    typeof md5 !== 'string' ||
    !md5.length
  ) {
    console.error('Invalid KHQR response:', response)

    throw new Error(
      'The KHQR SDK returned an invalid payload',
    )
  }

  return {
    qr,
    md5,
    amount,
    invoiceNumber: billNumber ?? '',
  }
}