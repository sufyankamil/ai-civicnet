export default {
    async fetch(request, env) {
        const url = new URL(request.url)
        url.hostname = 'zofkjhpfeqkvajglltlf.supabase.co'
        url.protocol = 'https:'
        url.port = ''

        // Build fresh mutable headers from the incoming request
        const newHeaders = new Headers(request.headers)
        newHeaders.set('Host', 'zofkjhpfeqkvajglltlf.supabase.co')
        newHeaders.set('Origin', 'https://zofkjhpfeqkvajglltlf.supabase.co')
        // Accept plain JSON so Supabase does not gzip the response
        newHeaders.set('Accept-Encoding', 'identity')

        // Check if it's a websocket (Realtime) request
        const upgradeHeader = request.headers.get('Upgrade')
        if (upgradeHeader && upgradeHeader === 'websocket') {
            const wsRequest = new Request(url.toString(), {
                method: request.method,
                headers: newHeaders,
                body: request.body,
            })
            return fetch(wsRequest)
        }

        // Standard REST proxy — read body once then forward
        const body = request.method !== 'GET' && request.method !== 'HEAD'
            ? await request.arrayBuffer()
            : undefined

        const proxyRequest = new Request(url.toString(), {
            method: request.method,
            headers: newHeaders,
            body: body,
        })

        // redirect: 'manual' ensures 302 responses (e.g. to civicnet://) are
        // passed through to the browser rather than being followed server-side.
        let response = await fetch(proxyRequest, { redirect: 'manual' })

        // Stream the body through without re-encoding
        let newResponse = new Response(response.body, {
            status: response.status,
            statusText: response.statusText,
            headers: response.headers,
        })

        // Remove encoding headers to avoid double-decode on the Flutter client
        newResponse.headers.delete('content-encoding')
        newResponse.headers.delete('content-length')
        newResponse.headers.set('Access-Control-Allow-Origin', '*')
        newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')

        return newResponse
    }
}
