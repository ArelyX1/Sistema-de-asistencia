import React, { useState } from "react";
import { createClient } from "../api/clients";
import { createTicket } from "../api/tickets";

function TicketRegisterManual({ eventId }) {
  const [nombre, setNombre] = useState("");
  const [dni, setDni] = useState("");
  const [costo, setCosto] = useState("");
  const [msg, setMsg] = useState("");
  async function handleSubmit(e) {
    e.preventDefault();
    try {
      const cliente = await createClient({
        fullName: nombre,
        documentNumber: dni,
        marketingPermission: false,
        newsletterSubscription: false,
      });
      await createTicket({
        idClient: cliente.idClient,
        idEvent: eventId,
        unitPrice: parseFloat(costo),
        totalPrice: parseFloat(costo),
        quantity: 1,
        status: "ACTIVO"
      });
      setMsg("Ticket creado correctamente.");
    } catch (err) {
      setMsg("Error: " + err.message);
    }
  }
  return (
    <form onSubmit={handleSubmit}>
      <h2>Registrar Ticket Manual</h2>
      <label>
        Nombre:
        <input value={nombre} onChange={e => setNombre(e.target.value)} required />
      </label><br />
      <label>
        DNI:
        <input value={dni} onChange={e => setDni(e.target.value)} required />
      </label><br />
      <label>
        Costo:
        <input value={costo} type="number" step="0.01" onChange={e => setCosto(e.target.value)} required />
      </label><br /><br />
      <button type="submit">Registrar</button>
      <div>{msg}</div>
    </form>
  );
}
export default TicketRegisterManual;
