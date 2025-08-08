package com.sistema.eventos.backend_sys_eventos.events.event.application;

import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;
import com.sistema.eventos.backend_sys_eventos.events.event.domain.EventRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public class EventService implements EventUseCase {
    private final EventRepository eventRepository;

    public EventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    @Override
    public List<Event> getAllEvents() {
        return eventRepository.findAll();
    }

    @Override
    public Optional<Event> getEventById(Long idEvent) {
        return eventRepository.findById(idEvent);
    }

    @Override
    public Optional<Event> getEventByCode(String eventCode) {
        return eventRepository.findByCode(eventCode);
    }

    @Override
    public Event createEvent(Event event) {
        event.setCreatedAt(LocalDateTime.now());
        event.setIsActive(true);
        return eventRepository.save(event);
    }

    @Override
    public Event updateEvent(Long idEvent, Event event) {
        Optional<Event> original = eventRepository.findById(idEvent);
        if(original.isEmpty())
            throw new IllegalArgumentException("Event not found");
        Event toUpdate = original.get();
        toUpdate.setEventName(event.getEventName());
        toUpdate.setEventCode(event.getEventCode());
        toUpdate.setDescription(event.getDescription());
        toUpdate.setEventType(event.getEventType());
        toUpdate.setEventCategory(event.getEventCategory());
        toUpdate.setStartDatetime(event.getStartDatetime());
        toUpdate.setEndDatetime(event.getEndDatetime());
        toUpdate.setIdEventSite(event.getIdEventSite());
        toUpdate.setIdOrganizer(event.getIdOrganizer());
        toUpdate.setStatus(event.getStatus());
        toUpdate.setUpdatedAt(LocalDateTime.now());
        // Puedes actualizar más campos si quieres.
        return eventRepository.save(toUpdate);
    }

    @Override
    public void deleteEvent(Long idEvent) {
        eventRepository.softDeleteById(idEvent);
    }
}