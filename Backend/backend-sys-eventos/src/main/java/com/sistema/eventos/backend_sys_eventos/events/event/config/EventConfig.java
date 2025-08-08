package com.sistema.eventos.backend_sys_eventos.events.event.config;

import com.sistema.eventos.backend_sys_eventos.events.event.application.EventService;
import com.sistema.eventos.backend_sys_eventos.events.event.application.EventUseCase;
import com.sistema.eventos.backend_sys_eventos.events.event.domain.EventRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class EventConfig {
    @Bean
    public EventUseCase eventUseCase(EventRepository eventRepository) {
        return new EventService(eventRepository);
    }
}