import React, { useState } from "react";
import Papa from "papaparse";
import { createClient } from "../api/clients";
import { createTicket } from "../api/tickets";

function TicketRegisterCSV({ eventId }) {
  const [file, setFile] = useState(null);
  const [statusMsg, setStatusMsg] = useState("");
  const [done, setDone] = useState(false);

  const handleFile = (e) => setFile(e.target.files[0]);
  const handleProcess = async () => {
    if (!file) { setStatusMsg("Debes subir un archivo."); return; }
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: async function (results) {
        let ok = 0, errores = [];
        for (let row of results.data) {
          try {
            const nombre = row["nombre"] || row["Nombre"];
            const dni = row["dni"] || row["DNI"];
            const costo = parseFloat(row["costo"] || row["Costo"] || 0.0);
            if (!nombre || !dni) throw new Error("Faltan campos obligatorios.");
            const cliente = await createClient({
              fullName: nombre,
              documentNumber: dni,
              marketingPermission: false,
              newsletterSubscription: false,
            });
            await createTicket({
              idClient: cliente.idClient,
              idEvent: eventId,
              unitPrice: costo,
              totalPrice: costo,
              quantity: 1,
              status: "ACTIVO",
            });
            ok++;
          } catch (err) {
            errores.push(err.message);
          }
        }
        setStatusMsg(`${ok} tickets creados. Errores: ${errores.length}`);
        setDone(true);
      }
    });
  };
  return (
    <div>
      <h2>Importar tickets via CSV/Excel</h2>
      <input type="file" accept=".csv"
        onChange={handleFile} />
      <button onClick={handleProcess}>Procesar archivo</button>
      <div>{statusMsg}</div>
      {done && <button onClick={() => window.history.back()}>Volver</button>}
    </div>
  );
}
export default TicketRegisterCSV;
