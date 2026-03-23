import type { ReactNode } from "react";

export const metadata = {
  title: "PBIX Storytelling",
  description: "Power BI model storytelling with Ollama (Vercel AI SDK)",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif" }}>{children}</body>
    </html>
  );
}
