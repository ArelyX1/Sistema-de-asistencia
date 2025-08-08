package com.sistema.eventos.backend_sys_eventos.events.event.domain;

import java.util.List;
import java.util.Optional;

public interface EventRepository {
    List<Event> findAll();
    Optional<Event> findById(Long idEvent);
    Event save(Event event);
    void softDeleteById(Long idEvent);
    Optional<Event> findByCode(String eventCode);
}