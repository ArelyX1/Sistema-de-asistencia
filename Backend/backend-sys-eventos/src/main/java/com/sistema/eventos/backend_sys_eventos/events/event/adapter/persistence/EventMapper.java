package com.sistema.eventos.backend_sys_eventos.events.event.adapter.persistence;

import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;
public class EventMapper {
    public static EventEntity toEntity(Event event) {
        if(event == null) return null;
        EventEntity e = new EventEntity();
        e.setIdEvent(event.getIdEvent());
        e.setEventName(event.getEventName());
        e.setEventCode(event.getEventCode());
        e.setDescription(event.getDescription());
        e.setEventType(event.getEventType());
        e.setEventCategory(event.getEventCategory());
        e.setStartDatetime(event.getStartDatetime());
        e.setEndDatetime(event.getEndDatetime());
        e.setIdEventSite(event.getIdEventSite());
        e.setIdOrganizer(event.getIdOrganizer());
        e.setStatus(event.getStatus());
        e.setIsActive(event.getIsActive());
        e.setCreatedAt(event.getCreatedAt());
        e.setUpdatedAt(event.getUpdatedAt());
        return e;
    }

    public static Event toDomain(EventEntity e) {
        if(e == null) return null;
        Event event = new Event();
        event.setIdEvent(e.getIdEvent());
        event.setEventName(e.getEventName());
        event.setEventCode(e.getEventCode());
        event.setDescription(e.getDescription());
        event.setEventType(e.getEventType());
        event.setEventCategory(e.getEventCategory());
        event.setStartDatetime(e.getStartDatetime());
        event.setEndDatetime(e.getEndDatetime());
        event.setIdEventSite(e.getIdEventSite());
        event.setIdOrganizer(e.getIdOrganizer());
        event.setStatus(e.getStatus());
        event.setIsActive(e.getIsActive());
        event.setCreatedAt(e.getCreatedAt());
        event.setUpdatedAt(e.getUpdatedAt());
        return event;
    }
}