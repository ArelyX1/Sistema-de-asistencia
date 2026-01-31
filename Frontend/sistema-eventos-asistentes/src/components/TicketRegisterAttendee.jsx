import React, { useState } from "react";
import { searchClients } from "../api/clients";
import { getTicketsByClient, updateTicket } from "../api/tickets";

function TicketRegisterAttendee({ eventId }) {
  const [query, setQuery] = useState("");
  const [clientes, setClientes] = useState([]);
  const [selectedClient, setSelectedClient] = useState(null);
  const [tickets, setTickets] = useState([]);
  const [msg, setMsg] = useState("");

  async function handleSearch() {
    const res = await searchClients(query);
    setClientes(res);
  }
  async function handleSelect(cliente) {
    setSelectedClient(cliente);
    const tickets = await getTicketsByClient(cliente.idClient, eventId);
    setTickets(tickets);
  }
  async function handleRegister(ticket) {
    if (ticket.status === "REGISTRADO") {
      setMsg("Ticket ya registrado.");
      return;
    }
    await updateTicket(ticket.idTicket, { status: "REGISTRADO" });
    setMsg("Asistente registrado.");
  }
  return (
    <div>
      <h2>Registrar Asistentes</h2>
      <input value={query} onChange={e => setQuery(e.target.value)} placeholder="Nombre o DNI" />
      <button onClick={handleSearch}>Buscar</button>
      <ul>
        {clientes.map(cli =>
          <li key={cli.idClient}>
            {cli.fullName} - {cli.documentNumber}
            <button onClick={() => handleSelect(cli)}>Ver Tickets</button>
          </li>
        )}
      </ul>
      {selectedClient && (
        <div>
          <h3>Tickets de {selectedClient.fullName}</h3>
          <ul>
            {tickets.map(t =>
              <li key={t.idTicket}>{t.ticketCode} - {t.status}
                <button onClick={() => handleRegister(t)}>
                  Registrar Asistencia
                </button>
              </li>
            )}
          </ul>
        </div>
      )}
      <div>{msg}</div>
    </div>
  );
}
export default TicketRegisterAttendee;
