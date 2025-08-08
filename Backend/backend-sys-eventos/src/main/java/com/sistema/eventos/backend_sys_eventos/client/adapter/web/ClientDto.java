package com.sistema.eventos.backend_sys_eventos.client.adapter.web;

import lombok.Data;

@Data
public class ClientDto {
    private Long idClient;
    private String fullName;
    private String email;
    private String phoneNumber;
    private Long idDocumentType;
    private Long idUser;
    private String documentNumber;
    private boolean marketingPermission;
    private boolean newsletterSubscription;
}
