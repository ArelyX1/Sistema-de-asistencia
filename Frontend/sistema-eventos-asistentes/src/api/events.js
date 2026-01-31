export async function getAllEvents() {
  const res = await fetch("/api/events");
  return await res.json();
}
export async function createEvent(data) {
  const res = await fetch("/api/events", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return await res.json();
}
export async function getAllSites() {
  const res = await fetch("/api/event-site");
  return await res.json();
}
