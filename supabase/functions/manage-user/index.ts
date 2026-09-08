import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return json({ error: 'Missing authorization' }, 401)

  const token = authHeader.replace('Bearer ', '')
  const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: `Bearer ${token}` } } })
  const { data: { user: caller }, error: callerError } = await userClient.auth.getUser(token)
  if (callerError || !caller) return json({ error: 'Invalid session' }, 401)

  const adminClient = createClient(supabaseUrl, serviceRoleKey)
  const { data: callerProfile, error: profileError } = await adminClient
    .from('profiles').select('role').eq('id', caller.id).maybeSingle()
  if (profileError || callerProfile?.role !== 'admin') return json({ error: 'Administrator access required' }, 403)

  try {
    const body = await req.json()
    const action = body.action || 'create'

    if (action === 'create') {
      const name = String(body.name || '').trim()
      const email = String(body.email || '').trim().toLowerCase()
      const password = String(body.password || '')
      const role = String(body.role || 'learner').toLowerCase()
      const department = String(body.department || '').trim() || null

      if (!name || !email || !password) return json({ error: 'Name, email and temporary password are required.' }, 400)
      if (password.length < 8) return json({ error: 'Temporary password must be at least 8 characters.' }, 400)
      if (!['learner', 'staff', 'admin', 'src'].includes(role)) return json({ error: 'Invalid role.' }, 400)

      const { data: created, error: createError } = await adminClient.auth.admin.createUser({
        email, password, email_confirm: true,
        user_metadata: { name, role, must_change_password: true }
      })
      if (createError) return json({ error: createError.message }, 400)

      const { error: insertError } = await adminClient.from('profiles').insert({
        id: created.user.id, name, email, role, department
      })
      if (insertError) {
        await adminClient.auth.admin.deleteUser(created.user.id)
        return json({ error: insertError.message }, 400)
      }
      return json({ ok: true, user: { id: created.user.id, name, email, role, department } })
    }

    if (action === 'update') {
      const id = String(body.id || '')
      const name = String(body.name || '').trim()
      const email = String(body.email || '').trim().toLowerCase()
      const role = String(body.role || 'learner').toLowerCase()
      const department = String(body.department || '').trim() || null
      if (!id || !name || !email) return json({ error: 'Member id, name and email are required.' }, 400)
      if (!['learner', 'staff', 'admin', 'src'].includes(role)) return json({ error: 'Invalid role.' }, 400)

      const { error: profileUpdateError } = await adminClient.from('profiles')
        .update({ name, email, role, department }).eq('id', id)
      if (profileUpdateError) return json({ error: profileUpdateError.message }, 400)
      const { data: existingAuth, error: existingAuthError } = await adminClient.auth.admin.getUserById(id)
      if (existingAuthError || !existingAuth.user) return json({ error: existingAuthError?.message || 'User account not found.' }, 400)
      const { error: authUpdateError } = await adminClient.auth.admin.updateUserById(id, {
        email,
        user_metadata: { ...(existingAuth.user.user_metadata || {}), name, role }
      })
      if (authUpdateError) return json({ error: authUpdateError.message }, 400)
      return json({ ok: true })
    }

    if (action === 'delete') {
      const id = String(body.id || '')
      if (!id) return json({ error: 'Member id is required.' }, 400)
      if (id === caller.id) return json({ error: 'You cannot delete your own administrator account.' }, 400)
      const { error } = await adminClient.auth.admin.deleteUser(id)
      if (error) return json({ error: error.message }, 400)
      return json({ ok: true })
    }

    return json({ error: 'Unknown action.' }, 400)
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : 'Unexpected server error.' }, 500)
  }
})
