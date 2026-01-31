// /src/api/sites.js
export async function createSite(data) {
  const res = await fetch("/api/event-site", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return await res.json();
}

// Optionally, export other functions if needed
export async function getAllSites() {
  const res = await fetch("/api/event-site");
  return await res.json();
}
