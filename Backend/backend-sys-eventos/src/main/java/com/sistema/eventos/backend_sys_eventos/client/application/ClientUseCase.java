package com.sistema.eventos.backend_sys_eventos.client.application;

import com.sistema.eventos.backend_sys_eventos.client.domain.Client;
import java.util.List;
import java.util.Optional;

public interface ClientUseCase {
    List<Client> getAllClients();
    Optional<Client> getClientById(Long idClient);
    Optional<Client> getClientByDocument(String documentNumber);
    Client createClient(Client client);
    Client updateClient(Long idClient, Client client);
    void deleteClient(Long idClient);
}
