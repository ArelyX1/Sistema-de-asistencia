package com.sistema.eventos.backend_sys_eventos.client.adapter.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SpringDataClientRepository extends JpaRepository<ClientEntity, Long> {
    Optional<ClientEntity> findByDocumentNumber(String documentNumber);
}
