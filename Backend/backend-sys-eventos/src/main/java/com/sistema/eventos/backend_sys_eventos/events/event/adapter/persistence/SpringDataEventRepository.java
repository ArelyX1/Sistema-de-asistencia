package com.sistema.eventos.backend_sys_eventos.events.event.adapter.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SpringDataEventRepository extends JpaRepository<EventEntity, Long> {
    Optional<EventEntity> findByEventCode(String eventCode);
}