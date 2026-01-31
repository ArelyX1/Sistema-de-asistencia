import React, { useState } from "react";
const VALID_USERNAME = "admin";
const VALID_PASSWORD = "admin123";
const LoginPage = ({ onLogin }) => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);

  const handleSubmit = e => {
    e.preventDefault();
    if (username === VALID_USERNAME && password === VALID_PASSWORD) {
      setError(null);
      onLogin();
    } else {
      setError("Incorrect username or password.");
    }
  };

  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
      <form onSubmit={handleSubmit} style={{ padding: 32, border: "1px solid #ccc", borderRadius: 8, maxWidth: 320, width: "100%", boxShadow: "0 0 10px #eee" }}>
        <h2 style={{ textAlign: "center", marginBottom: 24 }}>Login</h2>
        <div style={{ marginBottom: 12 }}>
          <label>
            Username:<br />
            <input
              type="text"
              value={username}
              required
              onChange={e => setUsername(e.target.value)}
              style={{ width: "100%", padding: 8, marginTop: 4 }}
            />
          </label>
        </div>
        <div style={{ marginBottom: 12 }}>
          <label>
            Password:<br />
            <input
              type="password"
              value={password}
              required
              onChange={e => setPassword(e.target.value)}
              style={{ width: "100%", padding: 8, marginTop: 4 }}
            />
          </label>
        </div>
        {error && <div style={{ color: "red", marginBottom: 12 }}>{error}</div>}
        <button type="submit" style={{ width: "100%", padding: 10, background: "#007bff", color: "#fff", border: "none", borderRadius: 4 }}>
          Login
        </button>
      </form>
    </div>
  );
};
export default LoginPage;
