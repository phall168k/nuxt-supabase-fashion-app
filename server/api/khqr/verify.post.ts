import { verifyKHQR } from '../../utils/khqr'

const MAX_KHQR_LENGTH = 4096

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const khqr = typeof body?.khqr === 'string' ? body.khqr.trim() : ''

  if (!khqr) {
    throw createError({
      statusCode: 400,
      statusMessage: 'KHQR payload is required',
    })
  }

  if (khqr.length > MAX_KHQR_LENGTH) {
    throw createError({
      statusCode: 400,
      statusMessage: 'KHQR payload is too long',
    })
  }

  return {
    success: true,
    data: {
      isValid: verifyKHQR(khqr),
    },
  }
})
