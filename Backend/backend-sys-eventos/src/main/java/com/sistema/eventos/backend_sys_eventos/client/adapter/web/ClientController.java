package com.sistema.eventos.backend_sys_eventos.client.adapter.web;

import com.sistema.eventos.backend_sys_eventos.client.application.ClientUseCase;
import com.sistema.eventos.backend_sys_eventos.client.domain.Client;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/clients")
public class ClientController {

    private final ClientUseCase clientUseCase;

    public ClientController(ClientUseCase clientUseCase) {
        this.clientUseCase = clientUseCase;
    }

    @GetMapping
    public List<ClientDto> getAll() {
        return clientUseCase.getAllClients()
                .stream()
                .map(ClientWebMapper::toDto)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    public ClientDto getById(@PathVariable Long id) {
        Optional<Client> client = clientUseCase.getClientById(id);
        return client.map(ClientWebMapper::toDto).orElse(null); // Maneja mejor las excepciones en real
    }

    @PostMapping
    public ClientDto create(@RequestBody ClientDto dto) {
        Client created = clientUseCase.createClient(ClientWebMapper.toDomain(dto));
        return ClientWebMapper.toDto(created);
    }

    @PutMapping("/{id}")
    public ClientDto update(@PathVariable Long id, @RequestBody ClientDto dto) {
        Client updated = clientUseCase.updateClient(id, ClientWebMapper.toDomain(dto));
        return ClientWebMapper.toDto(updated);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        clientUseCase.deleteClient(id);
    }
}
