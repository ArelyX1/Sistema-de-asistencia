package com.sistema.eventos.backend_sys_eventos.client.config;

import com.sistema.eventos.backend_sys_eventos.client.application.ClientService;
import com.sistema.eventos.backend_sys_eventos.client.application.ClientUseCase;
import com.sistema.eventos.backend_sys_eventos.client.domain.ClientRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ClientConfig {
    @Bean
    public ClientUseCase clientUseCase(ClientRepository clientRepository) {
        return new ClientService(clientRepository);
    }
}
