import { serverSupabaseClient } from '#supabase/server'
import { generateMerchantKHQR } from '../../utils/khqr'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  const amount = Number(body.amount)
  const paymentMethodId = Number(body.paymentMethodId)

  if (!Number.isFinite(amount) || amount <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Amount must be greater than 0',
    })
  }

  if (!Number.isInteger(paymentMethodId) || paymentMethodId <= 0) {
    throw createError({
      statusCode: 400,
      statusMessage: 'A valid payment method is required',
    })
  }

  try {
    const supabase = await serverSupabaseClient(event)
    const { data: paymentMethod, error } = await supabase
      .from('payment_methods')
      .select('name, bank_account, merchant_city, currency, store_label')
      .eq('id', paymentMethodId)
      .eq('is_active', true)
      .eq('is_cashed', false)
      .maybeSingle()

    if (error) throw error
    if (!paymentMethod) {
      throw createError({
        statusCode: 404,
        statusMessage: 'The selected payment method is unavailable',
      })
    }
    if (!paymentMethod.bank_account?.trim()) {
      throw createError({
        statusCode: 422,
        statusMessage: 'The selected payment method has no bank account',
      })
    }

    const generated = generateMerchantKHQR({
      amount,
      billNumber: typeof body.billNumber === 'string' && body.billNumber.trim()
        ? body.billNumber.trim()
        : `SAL-${Date.now()}`,
      bankAccount: paymentMethod.bank_account,
      merchantName: paymentMethod.name,
      merchantCity: paymentMethod.merchant_city,
      currency: paymentMethod.currency,
      storeLabel: paymentMethod.store_label,
    })

    return {
      success: true,
      data: generated,
    }
  }
  catch (error: any) {
    if (typeof error?.statusCode === 'number') throw error

    console.error('KHQR ERROR:', error)

    throw createError({
      statusCode: 500,

      statusMessage:
        error?.message ??
        'Unable to generate KHQR',
    })
  }
})
