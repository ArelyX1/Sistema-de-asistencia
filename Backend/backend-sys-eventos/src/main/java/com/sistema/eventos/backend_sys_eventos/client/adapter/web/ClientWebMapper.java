package com.sistema.eventos.backend_sys_eventos.client.adapter.web;

import com.sistema.eventos.backend_sys_eventos.client.domain.Client;

public class ClientWebMapper {
    public static ClientDto toDto(Client client) {
        if (client == null) return null;
        ClientDto dto = new ClientDto();
        dto.setIdClient(client.getIdClient());
        dto.setFullName(client.getFullName());
        dto.setEmail(client.getEmail());
        dto.setPhoneNumber(client.getPhoneNumber());
        dto.setIdDocumentType(client.getIdDocumentType());
        dto.setIdUser(client.getIdUser());
        dto.setDocumentNumber(client.getDocumentNumber());
        dto.setMarketingPermission(client.isMarketingPermission());
        dto.setNewsletterSubscription(client.isNewsletterSubscription());
        return dto;
    }

    public static Client toDomain(ClientDto dto) {
        if (dto == null) return null;
        Client client = new Client();
        client.setIdClient(dto.getIdClient());
        client.setFullName(dto.getFullName());
        client.setEmail(dto.getEmail());
        client.setPhoneNumber(dto.getPhoneNumber());
        client.setIdDocumentType(dto.getIdDocumentType());
        client.setIdUser(dto.getIdUser());
        client.setDocumentNumber(dto.getDocumentNumber());
        client.setMarketingPermission(dto.isMarketingPermission());
        client.setNewsletterSubscription(dto.isNewsletterSubscription());
        return client;
    }
}
