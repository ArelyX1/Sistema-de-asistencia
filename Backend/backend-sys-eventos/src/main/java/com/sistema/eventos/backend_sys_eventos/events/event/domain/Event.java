package com.sistema.eventos.backend_sys_eventos.events.event.domain;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

@Getter @Setter
@AllArgsConstructor
@NoArgsConstructor
public class Event {
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
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}