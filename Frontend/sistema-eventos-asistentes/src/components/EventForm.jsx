import React, { useState } from "react";
import { createEvent } from "../api/events";
import { createSite } from "../api/sites";

function EventForm() {
  const [nombre, setNombre] = useState("");
  const [siteName, setSiteName] = useState("");
  const [logo, setLogo] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    let siteId = null;
    if (siteName.trim()) {
      // Solo si se completó el input creamos el site
      const site = await createSite({ siteName });
      siteId = site.idEventSite; // o el nombre del campo que uses
    }
    // Puedes enviar idEventSite como null (o undefined) si no hay site
    await createEvent({ eventName: nombre, idEventSite: siteId, logo_url: logo?.name || "" });
    window.location.href = "/eventos";
  };

  return (
    <form onSubmit={handleSubmit}>
      <h2>Nuevo Evento</h2>
      <label>
        Nombre del Evento:
        <input type="text" value={nombre} onChange={e => setNombre(e.target.value)} required />
      </label>
      <br />
      <label>
        Lugar del Evento (opcional):
        <input type="text" value={siteName} onChange={e => setSiteName(e.target.value)} />
      </label>
      <br />
      <label>
        Logo:
        <input type="file" accept="image/*"
          onChange={e => setLogo(e.target.files[0])}
        />
      </label>
      <br /><br />
      <button type="submit">Guardar</button>
    </form>
  );
}
export default EventForm;
