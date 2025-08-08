package com.sistema.eventos.backend_sys_eventos.events.event.adapter.persistence;


import com.sistema.eventos.backend_sys_eventos.events.event.domain.Event;
import com.sistema.eventos.backend_sys_eventos.events.event.domain.EventRepository;

import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Repository
public class EventRepositoryImpl implements EventRepository {
    private final SpringDataEventRepository jpaRepo;

    public EventRepositoryImpl(SpringDataEventRepository jpaRepo) {
        this.jpaRepo = jpaRepo;
    }

    @Override
    public List<Event> findAll() {
        return jpaRepo.findAll().stream().map(EventMapper::toDomain).collect(Collectors.toList());
    }

    @Override
    public Optional<Event> findById(Long idEvent) {
        return jpaRepo.findById(idEvent).map(EventMapper::toDomain);
    }

    @Override
    public Event save(Event event) {
        EventEntity saved = jpaRepo.save(EventMapper.toEntity(event));
        return EventMapper.toDomain(saved);
    }

    @Override
    public void softDeleteById(Long idEvent) {
        jpaRepo.findById(idEvent).ifPresent(entity -> {
            entity.setIsActive(false);
            jpaRepo.save(entity);
        });
    }

    @Override
    public Optional<Event> findByCode(String eventCode) {
        return jpaRepo.findByEventCode(eventCode).map(EventMapper::toDomain);
    }
}