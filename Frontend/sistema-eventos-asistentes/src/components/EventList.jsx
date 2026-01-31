import React, { useEffect, useState } from "react";
import { getAllEvents } from "../api/events";

function EventList({ setSelectedEvent }) {
  const [events, setEvents] = useState([]);
  useEffect(() => {
    getAllEvents().then(setEvents);
  }, []);
  return (
    <div>
      <h2>Eventos</h2>
      <button onClick={() => window.location.href = "/eventos/nuevo"}>Crear Evento</button>
      <ul>
        {events.map(ev =>
          <li key={ev.idEvent}>
            <span
              style={{ cursor: "pointer", textDecoration: "underline" }}
              onClick={() => {
                setSelectedEvent(ev);
                window.location.href = `/eventos/${ev.idEvent}/tickets`
              }}>
              {ev.eventName}
            </span>
          </li>
        )}
      </ul>
    </div>
  );
}
export default EventList;
