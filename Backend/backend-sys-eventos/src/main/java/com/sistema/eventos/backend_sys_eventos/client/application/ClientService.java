package com.sistema.eventos.backend_sys_eventos.client.application;

import com.sistema.eventos.backend_sys_eventos.client.domain.Client;
import com.sistema.eventos.backend_sys_eventos.client.domain.ClientRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public class ClientService implements ClientUseCase {
    private final ClientRepository clientRepository;

    // Inyección del repositorio (generalmente desde una configuración o adapter)
    public ClientService(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    @Override
    public List<Client> getAllClients() {
        return clientRepository.findAll();
    }

    @Override
    public Optional<Client> getClientById(Long idClient) {
        return clientRepository.findById(idClient);
    }

    @Override
    public Optional<Client> getClientByDocument(String documentNumber) {
        return clientRepository.findByDocument(documentNumber);
    }

    @Override
    public Client createClient(Client client) {
        client.setCreatedAt(LocalDateTime.now());
        client.setActive(true);
        return clientRepository.save(client);
    }

    @Override
    public Client updateClient(Long idClient, Client client) {
        Optional<Client> existing = clientRepository.findById(idClient);
        if(existing.isEmpty()) {
            throw new IllegalArgumentException("Client not found");
        }
        // Aplica la actualización (ya sea todo el objeto o campos específicos)
        Client toUpdate = existing.get();
        toUpdate.setFullName(client.getFullName());
        toUpdate.setEmail(client.getEmail());
        toUpdate.setPhoneNumber(client.getPhoneNumber());
        toUpdate.setIdDocumentType(client.getIdDocumentType());
        toUpdate.setDocumentNumber(client.getDocumentNumber());
        toUpdate.setMarketingPermission(client.isMarketingPermission());
        toUpdate.setNewsletterSubscription(client.isNewsletterSubscription());
        toUpdate.setUpdatedAt(LocalDateTime.now());
        toUpdate.setUpdatedBy(client.getUpdatedBy());
        toUpdate.setActive(client.isActive());
        toUpdate.setDeletedAt(client.getDeletedAt());
        toUpdate.setDeletedBy(client.getDeletedBy());
        return clientRepository.save(toUpdate);
    }

    @Override
    public void deleteClient(Long idClient) {
        clientRepository.softDeleteById(idClient);
    }
}
