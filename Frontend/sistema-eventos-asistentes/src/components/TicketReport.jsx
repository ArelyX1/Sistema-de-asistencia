import React, { useEffect, useState } from "react";
import { getTicketsByEvent } from "../api/tickets";

function TicketReport({ eventId }) {
  const [tickets, setTickets] = useState([]);
  useEffect(() => {
    getTicketsByEvent(eventId).then(setTickets);
  }, [eventId]);
  const vendidos = tickets.length;
  const totAsistentes = tickets.filter(t => t.status === "REGISTRADO").length;
  const totalMonto = tickets.reduce((acc, t) => acc + (t.unitPrice || 0), 0);
  return (
    <div>
      <h2>Reporte de Tickets</h2>
      <p>Total vendidos/generados: {vendidos}</p>
      <p>Total de asistentes: {totAsistentes}</p>
      <p>Monto total: ${totalMonto}</p>
      <ul>
        {tickets.map(t =>
          <li key={t.idTicket}>{t.ticketCode} - {t.status} - Cliente: {t.idClient} - ${t.unitPrice}</li>
        )}
      </ul>
    </div>
  );
}
export default TicketReport;
