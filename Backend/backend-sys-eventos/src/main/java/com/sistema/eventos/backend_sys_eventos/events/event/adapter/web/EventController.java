package com.sistema.eventos.backend_sys_eventos.events.event.adapter.web;

import com.sistema.eventos.backend_sys_eventos.events.event.application.EventUseCase;
import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;
import java.util.Optional;

@RestController
@RequestMapping("/api/events")
public class EventController {
    private final EventUseCase eventUseCase;

    public EventController(EventUseCase eventUseCase) {
        this.eventUseCase = eventUseCase;
    }

    @GetMapping
    public List<EventDto> getAll() {
        return eventUseCase.getAllEvents().stream().map(EventWebMapper::toDto).collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public EventDto getById(@PathVariable Long id) {
        Optional<Event> event = eventUseCase.getEventById(id);
        return event.map(EventWebMapper::toDto).orElse(null);
    }

    @PostMapping
    public EventDto create(@RequestBody EventDto dto) {
        Event created = eventUseCase.createEvent(EventWebMapper.toDomain(dto));
        return EventWebMapper.toDto(created);
    }

    @PutMapping("/{id}")
    public EventDto update(@PathVariable Long id, @RequestBody EventDto dto) {
        Event updated = eventUseCase.updateEvent(id, EventWebMapper.toDomain(dto));
        return EventWebMapper.toDto(updated);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        eventUseCase.deleteEvent(id);
    }
}