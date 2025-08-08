package com.sistema.eventos.backend_sys_eventos.client.domain;

import java.util.List;
import java.util.Optional;

// Interfaz de puerto (pura, sin dependencias de Spring/JPA)
public interface ClientRepository {
    List<Client> findAll();
    Optional<Client> findById(Long idClient);
    Client save(Client client);
    void softDeleteById(Long idClient);
    Optional<Client> findByDocument(String documentNumber);
}
