package com.sistema.eventos.backend_sys_eventos.client.domain;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter @Setter
@AllArgsConstructor
@NoArgsConstructor
public class Client {
    private Long idClient;
    private String fullName;
    private String email;
    private String phoneNumber;

    private Long idDocumentType;
    private Long idUser;

    private String documentNumber;
    private boolean marketingPermission;
    private boolean newsletterSubscription;
    private boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime deletedAt;
    private Long createdBy;
    private Long updatedBy;
    private Long deletedBy;
}
