// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from "../_shared/cors.ts"

const FATSECRET_DEFAULT_API_URL = "https://platform.fatsecret.com/rest/server.api"
const FATSECRET_DEFAULT_TOKEN_URL = "https://oauth.fatsecret.com/connect/token"

interface RequestPayload {
  mode?: "search" | "barcode"
  query?: string
  barcode?: string
  maxResults?: number
}

interface NutritionItem {
  name: string
  calories: number
  serving_size_g: number
  fat_total_g: number
  fat_saturated_g: number
  protein_g: number
  sodium_mg: number
  potassium_mg: number
  cholesterol_mg: number
  carbohydrates_total_g: number
  fiber_g: number
  sugar_g: number
}

interface FatSecretTokenResponse {
  access_token: string
  token_type?: string
  expires_in?: number
}

let tokenCache: { token: string; expiresAtMs: number } | null = null

console.info("fatsecret-proxy server started")

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const auth = req.headers.get("Authorization") ?? ""
    if (!auth) {
      return jsonResponse({ error: "Missing authorization header" }, 401)
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")
    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse({ error: "Missing Supabase env vars" }, 500)
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: auth } },
    })
    const { data: userData, error: userErr } = await supabase.auth.getUser()
    if (userErr || !userData.user) {
      return jsonResponse(
        { error: "Unauthorized", details: userErr?.message ?? "Invalid JWT" },
        401,
      )
    }

    const payload: RequestPayload = await req.json()
    const mode = payload.mode ?? "search"

    if (mode === "barcode") {
      const barcode = (payload.barcode ?? "").trim()
      if (!barcode) {
        return jsonResponse({ error: "Missing barcode" }, 400)
      }

      const item = await lookupByBarcode(barcode)
      const items = item ? [item] : []
      return jsonResponse({ items }, 200)
    }

    const query = (payload.query ?? "").trim()
    if (!query) {
      return jsonResponse({ items: [] }, 200)
    }

    const maxResults = clamp(payload.maxResults ?? 25, 1, 50)
    const items = await searchFoods(query, maxResults)
    return jsonResponse({ items }, 200)
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    console.error("fatsecret-proxy error:", message)
    return jsonResponse({ error: "Internal server error", details: message }, 500)
  }
})

async function searchFoods(query: string, maxResults: number): Promise<NutritionItem[]> {
  const response = await fatSecretMethodRequest(
    ["foods.search.v3", "foods.search"],
    {
      search_expression: query,
      max_results: String(maxResults),
      page_number: "0",
    },
  )

  const foodNodes = toArray(response?.foods?.food)
  return foodNodes
    .map((food: any) => mapFoodSearchResult(food))
    .filter((item): item is NutritionItem => item !== null)
}

async function lookupByBarcode(barcode: string): Promise<NutritionItem | null> {
  const findResponse = await fatSecretMethodRequest(
    ["food.find_id_for_barcode.v2", "food.find_id_for_barcode"],
    { barcode },
  )

  const rawFoodId = findResponse?.food_id?.value ?? findResponse?.food_id
  const foodId = String(rawFoodId ?? "").trim()
  if (!foodId) return null

  const detailsResponse = await fatSecretMethodRequest(
    ["food.get.v5", "food.get"],
    { food_id: foodId },
  )

  return mapFoodGetResult(detailsResponse?.food)
}

async function fatSecretMethodRequest(
  methodCandidates: string[],
  params: Record<string, string>,
): Promise<any> {
  let lastError: Error | null = null

  for (const method of methodCandidates) {
    try {
      return await fatSecretRequest({
        method,
        format: "json",
        ...params,
      })
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      // If a method version is unsupported, try the next candidate.
      if (/Invalid method/i.test(message)) {
        lastError = error instanceof Error ? error : new Error(message)
        continue
      }
      throw error
    }
  }

  throw lastError ?? new Error("No supported FatSecret method found")
}

async function fatSecretRequest(params: Record<string, string>): Promise<any> {
  const token = await getFatSecretAccessToken()
  const url = (Deno.env.get("FATSECRET_UPSTREAM_BASE_URL") ?? FATSECRET_DEFAULT_API_URL).trim()
  const body = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    body.set(key, value)
  }

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  })

  const raw = await response.text()
  if (!response.ok) {
    throw new Error(`FatSecret request failed (${response.status}): ${raw}`)
  }

  let parsed: any
  try {
    parsed = JSON.parse(raw)
  } catch {
    throw new Error("FatSecret returned non-JSON response")
  }

  if (parsed?.error) {
    const code = parsed.error.code ?? "unknown"
    const message = parsed.error.message ?? "FatSecret API error"
    throw new Error(`FatSecret API error (${code}): ${message}`)
  }

  return parsed
}

async function getFatSecretAccessToken(): Promise<string> {
  const now = Date.now()
  if (tokenCache && now < tokenCache.expiresAtMs) {
    return tokenCache.token
  }

  const clientId = Deno.env.get("FATSECRET_CLIENT_ID")
  const clientSecret = Deno.env.get("FATSECRET_CLIENT_SECRET")
  if (!clientId || !clientSecret) {
    throw new Error("Missing FATSECRET_CLIENT_ID or FATSECRET_CLIENT_SECRET")
  }

  const credentials = btoa(`${clientId}:${clientSecret}`)
  const body = new URLSearchParams({ grant_type: "client_credentials", scope: "basic" })
  const tokenUrl = (Deno.env.get("FATSECRET_TOKEN_URL") ?? FATSECRET_DEFAULT_TOKEN_URL).trim()
  const response = await fetch(tokenUrl, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  })

  const raw = await response.text()
  if (!response.ok) {
    throw new Error(`FatSecret token request failed (${response.status}): ${raw}`)
  }

  let tokenPayload: FatSecretTokenResponse
  try {
    tokenPayload = JSON.parse(raw) as FatSecretTokenResponse
  } catch {
    throw new Error("Failed to parse FatSecret token response")
  }

  if (!tokenPayload.access_token) {
    throw new Error("FatSecret token response missing access_token")
  }

  const expiresIn = Math.max((tokenPayload.expires_in ?? 3600) - 30, 60)
  tokenCache = {
    token: tokenPayload.access_token,
    expiresAtMs: now + expiresIn * 1000,
  }
  return tokenPayload.access_token
}

function mapFoodSearchResult(food: any): NutritionItem | null {
  const name = String(food?.food_name ?? "").trim().toLowerCase()
  if (!name) return null

  const description = String(food?.food_description ?? "")
  const parsed = parseFoodDescription(description)

  return {
    name,
    calories: parsed.calories,
    serving_size_g: parsed.servingSizeG,
    fat_total_g: parsed.fatTotalG,
    fat_saturated_g: 0,
    protein_g: parsed.proteinG,
    sodium_mg: 0,
    potassium_mg: 0,
    cholesterol_mg: 0,
    carbohydrates_total_g: parsed.carbsG,
    fiber_g: 0,
    sugar_g: 0,
  }
}

function mapFoodGetResult(food: any): NutritionItem | null {
  const name = String(food?.food_name ?? "").trim().toLowerCase()
  if (!name) return null

  const servingNode = firstServing(food?.servings?.serving)
  const servingSizeG = parseNumber(servingNode?.metric_serving_amount, 100)
  const servingUnit = String(servingNode?.metric_serving_unit ?? "").toLowerCase()
  const normalizedServingG = servingUnit === "g" ? servingSizeG : 100

  return {
    name,
    calories: parseNumber(servingNode?.calories, 0),
    serving_size_g: normalizedServingG,
    fat_total_g: parseNumber(servingNode?.fat, 0),
    fat_saturated_g: parseNumber(servingNode?.saturated_fat, 0),
    protein_g: parseNumber(servingNode?.protein, 0),
    sodium_mg: parseNumber(servingNode?.sodium, 0),
    potassium_mg: 0,
    cholesterol_mg: parseNumber(servingNode?.cholesterol, 0),
    carbohydrates_total_g: parseNumber(servingNode?.carbohydrate, 0),
    fiber_g: parseNumber(servingNode?.fiber, 0),
    sugar_g: parseNumber(servingNode?.sugar, 0),
  }
}

function parseFoodDescription(text: string): {
  servingSizeG: number
  calories: number
  fatTotalG: number
  carbsG: number
  proteinG: number
} {
  const servingPer100 = /per\s+100g/i.test(text)
  const servingSizeG = servingPer100 ? 100 : 100
  const calories = extractMacro(text, "Calories")
  const fatTotalG = extractMacro(text, "Fat")
  const carbsG = extractMacro(text, "Carbs")
  const proteinG = extractMacro(text, "Protein")
  return { servingSizeG, calories, fatTotalG, carbsG, proteinG }
}

function extractMacro(description: string, label: string): number {
  const pattern = new RegExp(`${label}\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)`, "i")
  const match = description.match(pattern)
  return parseNumber(match?.[1], 0)
}

function parseNumber(value: unknown, fallback: number): number {
  if (typeof value === "number" && Number.isFinite(value)) return value
  if (typeof value === "string") {
    const normalized = value.replace(",", ".").trim()
    const parsed = Number(normalized)
    if (Number.isFinite(parsed)) return parsed
  }
  return fallback
}

function toArray<T>(value: T | T[] | null | undefined): T[] {
  if (Array.isArray(value)) return value
  if (value == null) return []
  return [value]
}

function firstServing(value: any): any {
  if (Array.isArray(value)) return value[0] ?? null
  return value ?? null
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      Connection: "keep-alive",
    },
  })
}
