use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2
};
use rand::rngs::OsRng;
use std::io::{self, Write};

fn main() {
    loop {
        println!("\n=== MENÚ DE PASSWORD HASHER ===");
        println!("1. Generar 3 hashes (PHC) de una contraseña");
        println!("2. Verificar contraseña contra un hash (PHC)");
        println!("3. Salir");
        print!("Selecciona una opción: ");
        io::stdout().flush().unwrap();

        let mut opcion = String::new();
        io::stdin().read_line(&mut opcion).unwrap();

        match opcion.trim() {
            "1" => generar_tres_hashes(),
            "2" => verificar_hash_pegado(),
            "3" => break,
            _ => println!("Opción no válida."),
        }
    }
}

fn generar_tres_hashes() {
    print!("\nIngresa la contraseña para generar hashes: ");
    io::stdout().flush().unwrap();
    let mut password = String::new();
    io::stdin().read_line(&mut password).unwrap();
    let password = password.trim();

    println!("\nGenerando 3 representaciones PHC diferentes para la misma clave:");
    let argon2 = Argon2::default();

    for i in 1..=3 {
        // Cada vez generamos un Salt diferente
        let salt = SaltString::generate(&mut OsRng);
        let hash = argon2.hash_password(password.as_bytes(), &salt).unwrap();
        println!("PHC Opcion {}: {}", i, hash);
    }
    println!("\nNota: Todos son diferentes por el 'Salt', pero todos son válidos.");
}

fn verificar_hash_pegado() {
    // 1. Pedir el hash (el string largo)
    println!("\n--- MODO VERIFICACIÓN ---");
    print!("Pega el hash (PHC string) de la DB: ");
    io::stdout().flush().unwrap();
    let mut phc_input = String::new();
    io::stdin().read_line(&mut phc_input).unwrap();
    let phc_input = phc_input.trim();

    // 2. Pedir la contraseña para probar
    print!("Ingresa la contraseña para verificar: ");
    io::stdout().flush().unwrap();
    let mut password_input = String::new();
    io::stdin().read_line(&mut password_input).unwrap();
    let password_input = password_input.trim();

    // 3. Proceso de verificación
    match PasswordHash::new(phc_input) {
        Ok(hash_parseado) => {
            let argon2 = Argon2::default();
            if argon2.verify_password(password_input.as_bytes(), &hash_parseado).is_ok() {
                println!("\n✅ ¡COINCIDE! Acceso permitido.");
            } else {
                println!("\n❌ NO COINCIDE. Contraseña incorrecta.");
            }
        }
        Err(e) => println!("\nerror: El hash pegado no tiene un formato PHC válido: {}", e),
    }
}
