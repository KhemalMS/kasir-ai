const BASE_URL = `${import.meta.env.VITE_API_URL || 'http://localhost:3001'}/api`;

async function handleResponse(response) {
    if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Network error' }));
        throw new Error(error.error || `HTTP ${response.status}`);
    }
    return response.json();
}

export const apiClient = {
    get: (path) =>
        fetch(`${BASE_URL}${path}`, {
            credentials: 'include',
        }).then(handleResponse),

    post: (path, data) =>
        fetch(`${BASE_URL}${path}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify(data),
        }).then(handleResponse),

    put: (path, data) =>
        fetch(`${BASE_URL}${path}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify(data),
        }).then(handleResponse),

    delete: (path) =>
        fetch(`${BASE_URL}${path}`, {
            method: 'DELETE',
            credentials: 'include',
        }).then(handleResponse),

    upload: (path, formData) =>
        fetch(`${BASE_URL}${path}`, {
            method: 'POST',
            credentials: 'include',
            body: formData, // Don't set Content-Type, browser sets multipart boundary
        }).then(handleResponse),
};
