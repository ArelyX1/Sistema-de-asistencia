import React, { useState } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import LoginPage from "./components/LoginPage";
import HomePage from "./components/HomePage";
import EventList from "./components/EventList";
import EventForm from "./components/EventForm";
import TicketList from "./components/TicketList";
import TicketRegisterCSV from "./components/TicketRegisterCSV";
import TicketRegisterManual from "./components/TicketRegisterManual";
import TicketRegisterAttendee from "./components/TicketRegisterAttendee";
import TicketReport from "./components/TicketReport";

function App() {
  const [authenticated, setAuthenticated] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState(null);

  if (!authenticated)
    return <LoginPage onLogin={() => setAuthenticated(true)} />;

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/eventos" element={
          <EventList setSelectedEvent={setSelectedEvent} />
        } />
        <Route path="/eventos/nuevo" element={<EventForm />} />
        <Route path="/eventos/:eventId/tickets" element={
          <TicketList selectedEvent={selectedEvent} />
        } />
        <Route path="/eventos/:eventId/tickets/csv" element={
          <TicketRegisterCSV eventId={selectedEvent?.idEvent} />
        } />
        <Route path="/eventos/:eventId/tickets/manual" element={
          <TicketRegisterManual eventId={selectedEvent?.idEvent} />
        } />
        <Route path="/eventos/:eventId/asistencia" element={
          <TicketRegisterAttendee eventId={selectedEvent?.idEvent} />
        } />
        <Route path="/eventos/:eventId/report" element={
          <TicketReport eventId={selectedEvent?.idEvent} />
        } />
      </Routes>
    </BrowserRouter>
  );
}
export default App;
