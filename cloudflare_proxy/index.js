export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    url.hostname = 'zofkjhpfeqkvajglltlf.supabase.co'

    const proxyRequest = new Request(url, request)

    // Bypass Origin Header so Supabase CORS accepts the request
    proxyRequest.headers.set('Origin', 'https://zofkjhpfeqkvajglltlf.supabase.co')

    // Check if it's a websocket (Realtime) request
    const upgradeHeader = request.headers.get("Upgrade")
    if (upgradeHeader && upgradeHeader === "websocket") {
      return fetch(proxyRequest)
    }

    // Standard REST proxy
    let response = await fetch(proxyRequest)
    
    // Rewrite CORS headers back to Flutter client securely
    let newResponse = new Response(response.body, response)
    newResponse.headers.set('Access-Control-Allow-Origin', '*')
    newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    
    return newResponse
  }
}
