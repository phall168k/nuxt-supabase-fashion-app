interface BakongTransaction {
  hash?: string
  fromAccountId?: string
  toAccountId?: string
  currency?: string
  amount?: number | string
  description?: string
}

interface BakongTransactionResponse {
  responseCode?: number
  responseMessage?: string
  errorCode?: number | null
  data?: BakongTransaction | null
}

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const md5 = typeof body?.md5 === 'string' ? body.md5.trim().toLowerCase() : ''

  if (!/^[a-f0-9]{32}$/.test(md5)) {
    throw createError({ statusCode: 400, statusMessage: 'A valid KHQR MD5 is required' })
  }

  const config = useRuntimeConfig(event)
  if (!config.bakongApiToken) {
    throw createError({ statusCode: 503, statusMessage: 'Bakong API token is not configured' })
  }

  try {
    const response = await $fetch<BakongTransactionResponse>('/v1/check_transaction_by_md5', {
      baseURL: config.bakongApiBaseUrl,
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.bakongApiToken}`,
      },
      body: { md5 },
    })

    return {
      success: true,
      data: {
        paid: response.responseCode === 0 && Boolean(response.data?.hash),
        transaction: response.responseCode === 0 ? response.data : null,
      },
    }
  }
  catch (error: any) {
    const statusCode = Number(error?.response?.status ?? error?.statusCode)
    if (statusCode === 401 || statusCode === 403) {
      throw createError({ statusCode: 502, statusMessage: 'Bakong API authorization failed' })
    }

    throw createError({
      statusCode: 502,
      statusMessage: error?.data?.responseMessage ?? error?.message ?? 'Unable to check Bakong payment',
    })
  }
})
