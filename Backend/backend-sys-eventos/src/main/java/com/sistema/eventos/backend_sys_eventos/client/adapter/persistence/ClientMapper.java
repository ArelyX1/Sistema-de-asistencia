package com.sistema.eventos.backend_sys_eventos.client.adapter.persistence;

import com.sistema.eventos.backend_sys_eventos.client.domain.Client;

public class ClientMapper {
    public static ClientEntity toEntity(Client client) {
        if (client == null) return null;

        ClientEntity entity = new ClientEntity();
        entity.setIdClient(client.getIdClient());
        entity.setFullName(client.getFullName());
        entity.setEmail(client.getEmail());
        entity.setPhoneNumber(client.getPhoneNumber());
        entity.setIdDocumentType(client.getIdDocumentType());
        entity.setIdUser(client.getIdUser());
        entity.setDocumentNumber(client.getDocumentNumber());
        entity.setMarketingPermission(client.isMarketingPermission());
        entity.setNewsletterSubscription(client.isNewsletterSubscription());
        entity.setIsActive(client.isActive());
        entity.setCreatedAt(client.getCreatedAt());
        entity.setUpdatedAt(client.getUpdatedAt());
        entity.setDeletedAt(client.getDeletedAt());
        entity.setCreatedBy(client.getCreatedBy());
        entity.setUpdatedBy(client.getUpdatedBy());
        entity.setDeletedBy(client.getDeletedBy());
        return entity;
    }

    public static Client toDomain(ClientEntity entity) {
        if (entity == null) return null;
        Client client = new Client();
        client.setIdClient(entity.getIdClient());
        client.setFullName(entity.getFullName());
        client.setEmail(entity.getEmail());
        client.setPhoneNumber(entity.getPhoneNumber());
        client.setIdDocumentType(entity.getIdDocumentType());
        client.setIdUser(entity.getIdUser());
        client.setDocumentNumber(entity.getDocumentNumber());
        client.setMarketingPermission(Boolean.TRUE.equals(entity.getMarketingPermission()));
        client.setNewsletterSubscription(Boolean.TRUE.equals(entity.getNewsletterSubscription()));
        client.setActive(Boolean.TRUE.equals(entity.getIsActive()));
        client.setCreatedAt(entity.getCreatedAt());
        client.setUpdatedAt(entity.getUpdatedAt());
        client.setDeletedAt(entity.getDeletedAt());
        client.setCreatedBy(entity.getCreatedBy());
        client.setUpdatedBy(entity.getUpdatedBy());
        client.setDeletedBy(entity.getDeletedBy());
        return client;
    }
}
