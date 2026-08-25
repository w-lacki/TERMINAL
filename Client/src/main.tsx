import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import HyperDX from "@hyperdx/browser";
import "./index.css";
import App from "./App.tsx";

HyperDX.init({
  apiKey: import.meta.env.VITE_HYPERDX_API_KEY,
  service: "terminal-frontend",
  url:
    import.meta.env.VITE_HYPERDX_URL ||
    "https://telemetry.terminal.eti.pg.edu.pl",
  tracePropagationTargets: [/localhost/, /terminal\.eti\.pg\.edu\.pl/],
  consoleCapture: true,
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
