import React, { useState } from "react";
import { FaPlus } from "react-icons/fa";
function FloatingActionMenu({ eventId }) {
  const [open, setOpen] = useState(false);
  return (
    <div
      style={{
        position: "fixed", top: 30, right: 30, zIndex: 1001
      }}
    >
      <button style={{ borderRadius: "50%", width: 48, height: 48, background: "#007bff", color: "#fff", fontSize: 22 }}
        onClick={() => setOpen((o) => !o)}>
        <FaPlus />
      </button>
      {open && (
        <div style={{ position: "absolute", top: 55, right: 0, background: "#fff", boxShadow: "0 0 8px #ccc", borderRadius: 8 }}>
          <button style={{ display: "block", padding: 12, width: "100%" }}
            onClick={() => window.location.href = `/eventos/${eventId}/tickets/csv`}>
            Importar CSV/Excel
          </button>
          <button style={{ display: "block", padding: 12, width: "100%" }}
            onClick={() => window.location.href = `/eventos/${eventId}/tickets/manual`}>
            Nuevo Ticket Manual
          </button>
        </div>
      )}
    </div>
  )
}
export default FloatingActionMenu;
