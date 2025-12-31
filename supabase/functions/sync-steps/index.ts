// Edge Function: sync-steps
// Handles rate-limited step synchronization with validation
// Deploy: supabase functions deploy sync-steps

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const RATE_LIMIT_PER_MIN = 30
const RATE_LIMIT_PER_HOUR = 4
const MAX_STEPS_PER_HOUR = 10000 // Reasonable max for validation

interface SyncStepsRequest {
  day?: string // ISO date string (YYYY-MM-DD)
  steps: number
  device_id?: string
}

interface RateLimitRecord {
  user_id: string
  bucket: string
  count: number
  reset_at: string
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Extract auth token
    const auth = req.headers.get('Authorization') ?? ''
    if (!auth) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract metadata
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
    const userAgent = req.headers.get('user-agent') ?? 'unknown'

    // Initialize Supabase client with user's JWT
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: { headers: { Authorization: auth } }
      }
    )

    // 1) Verify user identity from JWT
    const { data: { user }, error: userErr } = await supabase.auth.getUser()
    if (userErr || !user) {
      console.error('Auth error:', userErr)
      return new Response(
        JSON.stringify({ error: 'Unauthorized', details: userErr?.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Step sync request from user: ${user.id}`)

    // 2) Parse request body
    const body: SyncStepsRequest = await req.json()
    const { day, steps, device_id } = body

    // Validate input
    if (typeof steps !== 'number' || steps < 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid steps value' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (steps > 100000) {
      return new Response(
        JSON.stringify({ 
          error: 'Suspicious step count',
          message: 'Step count exceeds reasonable daily maximum'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3) Check rate limits
    const rateLimitError = await checkRateLimit(supabase, user.id)
    if (rateLimitError) {
      return new Response(
        JSON.stringify({ 
          error: 'Rate limit exceeded',
          message: rateLimitError,
          retry_after: 60 // seconds
        }),
        { 
          status: 429, 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json',
            'Retry-After': '60'
          } 
        }
      )
    }

    // 4) Call server-side RPC with audit trail
    const { data, error } = await supabase.rpc('sync_daily_steps', {
      p_day: day ?? null,
      p_steps: steps,
      p_source: 'healthkit',
      p_device_id: device_id ?? 'unknown',
      p_ip: ip,
      p_user_agent: userAgent
    })

    if (error) {
      console.error('RPC error:', error)
      return new Response(
        JSON.stringify({ 
          error: 'Step sync failed', 
          details: error.message 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`✅ Steps synced for user ${user.id}: ${steps}`)

    return new Response(
      JSON.stringify({
        success: true,
        data: data,
        message: 'Steps synced successfully'
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: err.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Check rate limits for a user
 * Returns error message if rate limit exceeded, null otherwise
 */
async function checkRateLimit(
  supabase: any, 
  userId: string
): Promise<string | null> {
  const now = new Date()
  
  // Check per-minute limit
  const minuteBucket = now.toISOString().substring(0, 16) // YYYY-MM-DDTHH:MM
  const minuteLimit = await getRateLimit(supabase, userId, `minute:${minuteBucket}`)
  
  if (minuteLimit && minuteLimit.count >= RATE_LIMIT_PER_MIN) {
    return `Too many requests. Limit: ${RATE_LIMIT_PER_MIN} per minute.`
  }

  // Check per-hour limit
  const hourBucket = now.toISOString().substring(0, 13) // YYYY-MM-DDTHH
  const hourLimit = await getRateLimit(supabase, userId, `hour:${hourBucket}`)
  
  if (hourLimit && hourLimit.count >= RATE_LIMIT_PER_HOUR) {
    return `Too many requests. Limit: ${RATE_LIMIT_PER_HOUR} per hour.`
  }

  // Increment counters
  await incrementRateLimit(supabase, userId, `minute:${minuteBucket}`, 60) // 60 sec TTL
  await incrementRateLimit(supabase, userId, `hour:${hourBucket}`, 3600) // 1 hour TTL

  return null
}

/**
 * Get current rate limit count
 */
async function getRateLimit(
  supabase: any,
  userId: string,
  bucket: string
): Promise<RateLimitRecord | null> {
  const { data, error } = await supabase
    .from('rate_limits')
    .select('*')
    .eq('user_id', userId)
    .eq('bucket', bucket)
    .gte('reset_at', new Date().toISOString())
    .single()

  if (error || !data) return null
  return data as RateLimitRecord
}

/**
 * Increment rate limit counter
 */
async function incrementRateLimit(
  supabase: any,
  userId: string,
  bucket: string,
  ttlSeconds: number
): Promise<void> {
  const resetAt = new Date(Date.now() + ttlSeconds * 1000)

  // Try to increment existing record
  const { error: updateError } = await supabase.rpc('increment_rate_limit', {
    p_user_id: userId,
    p_bucket: bucket,
    p_reset_at: resetAt.toISOString()
  })

  if (updateError) {
    console.error('Failed to increment rate limit:', updateError)
  }
}

