package com.sistema.eventos.backend_sys_eventos.client.adapter.persistence;

import com.sistema.eventos.backend_sys_eventos.client.domain.Client;
import com.sistema.eventos.backend_sys_eventos.client.domain.ClientRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Repository
public class ClientRepositoryImpl implements ClientRepository {
    private final SpringDataClientRepository jpaRepo;

    public ClientRepositoryImpl(SpringDataClientRepository jpaRepo) {
        this.jpaRepo = jpaRepo;
    }

    @Override
    public List<Client> findAll() {
        return jpaRepo.findAll()
                .stream()
                .map(ClientMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public Optional<Client> findById(Long idClient) {
        return jpaRepo.findById(idClient).map(ClientMapper::toDomain);
    }

    @Override
    public Client save(Client client) {
        ClientEntity savedEntity = jpaRepo.save(ClientMapper.toEntity(client));
        return ClientMapper.toDomain(savedEntity);
    }

    @Override
    public void softDeleteById(Long idClient) {
        jpaRepo.findById(idClient).ifPresent(entity -> {
            entity.setIsActive(false);
            entity.setDeletedAt(java.time.LocalDateTime.now());
            jpaRepo.save(entity);
        });
    }

    @Override
    public Optional<Client> findByDocument(String documentNumber) {
        return jpaRepo.findByDocumentNumber(documentNumber)
                .map(ClientMapper::toDomain);
    }
}
