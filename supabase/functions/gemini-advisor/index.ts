import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }})
  }

  try {
    const { query, context } = await req.json()
    
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is missing from environment")
    }

    const payload = {
      contents: [{
        parts: [{
          text: `You are an expert agronomist AI for a smart farming application.
          
Context about the farm:
${JSON.stringify(context, null, 2)}

Farmer's Query:
${query}

Respond with actionable, professional advice.`
        }]
      }]
    }

    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    return new Response(
      JSON.stringify(data),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } },
    )
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      status: 400,
    })
  }
})
