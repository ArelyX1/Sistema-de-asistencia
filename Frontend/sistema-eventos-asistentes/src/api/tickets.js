export async function getTicketsByEvent(eventId) {
  const res = await fetch(`/api/tickets?eventId=${eventId}`);
  return await res.json();
}
export async function getTicketsByClient(clientId, eventId) {
  const res = await fetch(`/api/tickets?clientId=${clientId}&eventId=${eventId}`);
  return await res.json();
}
export async function createTicket(data) {
  const res = await fetch("/api/tickets", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return await res.json();
}
export async function updateTicket(id, data) {
  const res = await fetch(`/api/tickets/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });
  return await res.json();
}
