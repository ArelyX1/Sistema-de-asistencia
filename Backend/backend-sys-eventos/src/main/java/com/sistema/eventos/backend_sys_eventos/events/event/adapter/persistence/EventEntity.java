package com.sistema.eventos.backend_sys_eventos.events.event.adapter.persistence;

import jakarta.persistence.*;
import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Getter @Setter
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "mae_event")
public class EventEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_event")
    private Long idEvent;

    @Column(name = "event_name")
    private String eventName;

    @Column(name = "event_code")
    private String eventCode;

    @Column(name = "description")
    private String description;

    @Column(name = "event_type")
    private String eventType;

    @Column(name = "event_category")
    private String eventCategory;

    @Column(name = "start_datetime")
    private LocalDateTime startDatetime;

    @Column(name = "end_datetime")
    private LocalDateTime endDatetime;

    @Column(name = "id_event_site")
    private Long idEventSite;

    @Column(name = "id_organizer")
    private Long idOrganizer;

    @Column(name = "status")
    private String status;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Getters y setters (usa lombok si prefieres)
}