import React from "react";
function HomePage() {
  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div>
        <h1>¡Bienvenido!</h1>
        <a href="/eventos">Ir al Módulo de eventos</a>
      </div>
    </div>
  );
}
export default HomePage;
