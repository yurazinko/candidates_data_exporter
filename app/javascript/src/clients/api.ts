import axios from 'axios';
import { getCsrfToken } from '../utils/csrf';

const api = axios.create({
  baseURL: '/',
  headers: {
    'Content-Type': 'application/json',
  },
});


api.interceptors.request.use((config) => {
  if (['post', 'put', 'patch', 'delete'].includes(config.method!)) {
    const csrfToken = getCsrfToken();
    config.headers['X-CSRF-Token'] = csrfToken;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

export default api;
