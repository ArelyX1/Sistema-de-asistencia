package com.sistema.eventos.backend_sys_eventos.events.event.adapter.web;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class EventDto {
    private Long idEvent;
    private String eventName;
    private String eventCode;
    private String description;
    private String eventType;
    private String eventCategory;
    private LocalDateTime startDatetime;
    private LocalDateTime endDatetime;
    private Long idEventSite;
    private Long idOrganizer;
    private String status;
}