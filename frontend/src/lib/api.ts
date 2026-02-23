const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3080'

const getToken = (): string | null => localStorage.getItem('token')

function getHeaders(includeAuth = false): HeadersInit {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  const token = getToken()
  if (includeAuth && token) {
    headers['Authorization'] = `Bearer ${token}`
  }
  return headers
}

export async function login(email: string, password: string) {
  const res = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify({ email, password })
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || 'Login failed')
  if (data.token) {
    localStorage.setItem('token', data.token)
    localStorage.setItem('user', JSON.stringify(data.user))
  }
  return data
}

export function logout() {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
}

export function getSession(): { user: { id: string; email: string } } | null {
  const token = getToken()
  const userStr = localStorage.getItem('user')
  if (!token || !userStr) return null
  try {
    const user = JSON.parse(userStr)
    return { user }
  } catch {
    return null
  }
}

export async function getMe() {
  const res = await fetch(`${BASE_URL}/api/auth/me`, {
    headers: getHeaders(true)
  })
  if (!res.ok) return null
  return res.json()
}

async function parseJsonOrThrow(res: Response, context: string): Promise<unknown> {
  const text = await res.text()
  try {
    return text ? JSON.parse(text) : []
  } catch {
    throw new Error(`${context}: API returned invalid response (not JSON). Check that the API URL is correct and the server is running.`)
  }
}

export async function getCompanies() {
  const res = await fetch(`${BASE_URL}/api/companies`, { headers: getHeaders() })
  if (!res.ok) throw new Error('Failed to load companies')
  return parseJsonOrThrow(res, 'Companies') as Promise<Array<{ id: string; name: string }>>
}

export async function getLocations() {
  const res = await fetch(`${BASE_URL}/api/locations`, { headers: getHeaders() })
  if (!res.ok) throw new Error('Failed to load locations')
  return parseJsonOrThrow(res, 'Locations') as Promise<Array<{ id: string; name: string; company_id: string }>>
}

export async function createAsset(formData: FormData) {
  const token = getToken()
  const headers: Record<string, string> = {}
  if (token) headers['Authorization'] = `Bearer ${token}`
  const res = await fetch(`${BASE_URL}/api/assets`, {
    method: 'POST',
    headers,
    body: formData
  })
  const data = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(data.error || 'Failed to create asset')
  return data
}

export async function getAssets() {
  const res = await fetch(`${BASE_URL}/api/assets`, { headers: getHeaders(true) })
  if (!res.ok) throw new Error('Failed to load assets')
  return res.json()
}

export async function getAssetCountByCompany() {
  const res = await fetch(`${BASE_URL}/api/assets/count-by-company`, {
    headers: getHeaders(true)
  })
  if (!res.ok) throw new Error('Failed to load counts')
  return res.json()
}

export async function getFileViewUrl(fileId: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/files/${fileId}`, {
    headers: getHeaders(true)
  })
  if (!res.ok) throw new Error('Failed to load file')
  const blob = await res.blob()
  return URL.createObjectURL(blob)
}
