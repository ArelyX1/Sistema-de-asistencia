export async function createClient(data) {
  const res = await fetch("/api/clients", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return await res.json();
}
export async function searchClients(query) {
  const res = await fetch(`/api/clients?filter=${encodeURIComponent(query)}`);
  return await res.json();
}
