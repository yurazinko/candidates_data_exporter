export const getCsrfToken = (): string => {
  const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  if (!token) {
    console.error("CSRF token not found. Is csrf_meta_tags included in the HTML head?");
    throw new Error("CSRF token is required");
  }
  return token;
};