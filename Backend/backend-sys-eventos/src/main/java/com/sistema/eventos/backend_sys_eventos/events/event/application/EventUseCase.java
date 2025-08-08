package com.sistema.eventos.backend_sys_eventos.events.event.application;

import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;
import java.util.List;
import java.util.Optional;

public interface EventUseCase {
    List<Event> getAllEvents();
    Optional<Event> getEventById(Long idEvent);
    Optional<Event> getEventByCode(String eventCode);
    Event createEvent(Event event);
    Event updateEvent(Long idEvent, Event event);
    void deleteEvent(Long idEvent);
}