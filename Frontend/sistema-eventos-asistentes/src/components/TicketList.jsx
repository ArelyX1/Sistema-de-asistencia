import React, { useEffect, useState } from "react";
import { getTicketsByEvent } from "../api/tickets";
import FloatingActionMenu from "./FloatingActionMenu";

function TicketList({ selectedEvent }) {
  const [tickets, setTickets] = useState([]);
  useEffect(() => {
    if (!selectedEvent) return;
    getTicketsByEvent(selectedEvent.idEvent).then(setTickets);
  }, [selectedEvent]);
  if (!selectedEvent) return <div>Selecciona un evento.</div>;
  return (
    <div>
      <h2>Tickets para: {selectedEvent.eventName}</h2>
      <ul>
        {tickets.map(tk =>
          <li key={tk.idTicket}>
            {tk.ticketCode} | {tk.status} | {tk.unitPrice} | Cliente: {tk.idClient}
          </li>
        )}
      </ul>
      <FloatingActionMenu eventId={selectedEvent.idEvent} />
      <button
        style={{
          position: "fixed", bottom: 20, right: 90, zIndex: 1000, background: "green", color: "#fff"
        }}
        onClick={() => window.location.href = `/eventos/${selectedEvent.idEvent}/asistencia`}>
        Registrar asistentes
      </button>
      <button
        style={{
          position: "fixed", bottom: 20, right: 200, zIndex: 1000, background: "#023", color: "#fff"
        }}
        onClick={() => window.location.href = `/eventos/${selectedEvent.idEvent}/report`}>
        Ver registro
      </button>
    </div>
  );
}
export default TicketList;
