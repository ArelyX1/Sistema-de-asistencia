package com.sistema.eventos.backend_sys_eventos.events.event.adapter.web;

import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;

public class EventWebMapper {
    public static EventDto toDto(Event event) {
        if(event == null) return null;
        EventDto dto = new EventDto();
        dto.setIdEvent(event.getIdEvent());
        dto.setEventName(event.getEventName());
        dto.setEventCode(event.getEventCode());
        dto.setDescription(event.getDescription());
        dto.setEventType(event.getEventType());
        dto.setEventCategory(event.getEventCategory());
        dto.setStartDatetime(event.getStartDatetime());
        dto.setEndDatetime(event.getEndDatetime());
        dto.setIdEventSite(event.getIdEventSite());
        dto.setIdOrganizer(event.getIdOrganizer());
        dto.setStatus(event.getStatus());
        return dto;
    }

    public static Event toDomain(EventDto dto) {
        if(dto == null) return null;
        Event event = new Event();
        event.setIdEvent(dto.getIdEvent());
        event.setEventName(dto.getEventName());
        event.setEventCode(dto.getEventCode());
        event.setDescription(dto.getDescription());
        event.setEventType(dto.getEventType());
        event.setEventCategory(dto.getEventCategory());
        event.setStartDatetime(dto.getStartDatetime());
        event.setEndDatetime(dto.getEndDatetime());
        event.setIdEventSite(dto.getIdEventSite());
        event.setIdOrganizer(dto.getIdOrganizer());
        event.setStatus(dto.getStatus());
        return event;
    }
}