import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";

import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  httpOptions: {
    headers: {
      'User-Agent': 'aistudio-build',
    }
  }
});

// In-memory user store for demonstration (since Firebase was declined)
const users: any[] = [
  { 
    id: "alex-123", 
    email: "alex@example.com", 
    password: "password", 
    name: "Alex", 
    profilePic: "https://lh3.googleusercontent.com/aida-public/AB6AXuC_I93xl0az1loKxptTgS1v8XLJf4m-MiiNFaGjgbpN2S3Mwc73F0vWAgpIOeod7Z9EwM84O7SobDiTrislDoKBDcd5j_7GOuxVdyNgCq6VyQI5KeTeqgZaYMJw2OIq3A3JeosHMLypHXfOSakQkTwep1gTYFQ9ijDzsHDxCbBJOg-M128Hdin0jUf1qVJ5KxOnbbv5U_NtCO9pfmCQWHPWagFZLHVqkmaHBZCNqoQHFbpX7G5Y6pzF0ed8J_zcpEabhybfTJakdZs",
    verified: true,
    scenarios: []
  }
];

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // API Routes
  app.get("/api/auth/me", (req, res) => {
    // For demo purposes, we'll return the first user or Alex
    const user = users[0];
    if (!user) return res.status(401).json({ error: "Not logged in" });
    res.json(user);
  });

  app.post("/api/auth/verify", (req, res) => {
    const { token } = req.body;
    const user = users.find(u => u.verificationToken === token);
    
    if (!user) {
      return res.status(400).json({ error: "Invalid or expired verification token" });
    }

    user.verified = true;
    user.verificationToken = null;
    res.json({ message: "Email verified successfully", user: { email: user.email, verified: true } });
  });

  app.post("/api/auth/resend-verification", (req, res) => {
    const { email } = req.body;
    const user = users.find(u => u.email === email);
    
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const token = Math.random().toString(36).substring(2, 15);
    user.verificationToken = token;
    
    console.log(`[EMAIL MOCK] Verification link for ${email}: http://localhost:3000/verify/${token}`);
    res.json({ message: "Verification email sent", verificationLink: `/verify/${token}` });
  });

  app.post("/api/auth/profile", (req, res) => {
    const { name, profilePic, id } = req.body;
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({ error: "User not found" });
    }

    users[userIndex] = { ...users[userIndex], name, profilePic };
    res.json({ message: "Profile updated", user: users[userIndex] });
  });

  app.get("/api/scenarios", (req, res) => {
    const user = users[0]; // Demo: always first user
    if (!user) return res.status(401).json({ error: "Not logged in" });
    res.json(user.scenarios || []);
  });

  app.post("/api/scenarios", (req, res) => {
    const { role, company, questions } = req.body;
    const user = users[0]; // Demo: always first user
    
    if (!user) return res.status(401).json({ error: "Not logged in" });
    if (!role || !company) return res.status(400).json({ error: "Role and company are required" });

    const newScenario = {
      id: Date.now().toString(),
      role,
      company,
      questions: questions || [],
      createdAt: new Date().toISOString()
    };

    if (!user.scenarios) user.scenarios = [];
    user.scenarios.push(newScenario);

    res.status(201).json({ message: "Scenario saved", scenario: newScenario });
  });

  app.post("/api/auth/register", (req, res) => {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    const existingUser = users.find(u => u.email === email);
    if (existingUser) {
      return res.status(400).json({ error: "User already exists" });
    }

    const token = Math.random().toString(36).substring(2, 15);
    const newUser = { 
      email, 
      password, 
      id: Date.now().toString(), 
      name: email.split('@')[0], 
      profilePic: "",
      verified: false,
      verificationToken: token,
      scenarios: []
    };
    users.push(newUser);
    
    console.log(`New user registered: ${email}`);
    console.log(`[EMAIL MOCK] Verification link for ${email}: http://localhost:3000/verify/${token}`);

    res.status(201).json({ 
      message: "User registered successfully. Please verify your email.", 
      user: { email: newUser.email, id: newUser.id, verified: false },
      verificationLink: `/verify/${token}` // Including link in response for demo convenience
    });
  });

  app.post("/api/auth/login", (req, res) => {
    const { email, password } = req.body;
    
    const user = users.find(u => u.email === email && u.password === password);
    if (!user) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    res.json({ message: "Login successful", user: { email: user.email, id: user.id } });
  });

  app.post("/api/gemini/chat", async (req, res) => {
    try {
      const { message, history, model, config } = req.body;
      
      const chat = ai.chats.create({
        model: model || "gemini-1.5-flash",
        config: {
          systemInstruction: "You are a professional HR recruiter conducting a job interview. Be encouraging but rigorous. Provide constructive feedback occasionally.",
          ...config
        },
        history: history || []
      });

      const response = await chat.sendMessage({ message });
      res.json({ text: response.text });
    } catch (error: any) {
      console.error("Gemini API Error:", error);
      res.status(500).json({ error: error.message });
    }
  });

  app.post("/api/gemini/analyze", async (req, res) => {
    try {
      const { history, model } = req.body;
      
      const prompt = `Analyze this job interview conversation and provide a comprehensive feedback summary in JSON format. 
      The JSON should have exactly these keys: 
      "score" (number 0-100), 
      "strengths" (array of strings), 
      "improvements" (array of strings), 
      "tips" (array of strings),
      "summary" (a brief 2-3 sentence overview).
      
      Conversation:
      ${JSON.stringify(history)}`;

      const result = await ai.models.generateContent({
        model: model || "gemini-1.5-flash",
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        config: {
          responseMimeType: "application/json",
        }
      });

      const responseText = result.text;
      res.json(JSON.parse(responseText));
    } catch (error: any) {
      console.error("Gemini Analysis Error:", error);
      res.status(500).json({ error: error.message });
    }
  });

  app.post("/api/gemini/coach", async (req, res) => {
    try {
      const { history, lastMessage } = req.body;
      
      const prompt = `You are an AI Interview Coach. Analyze the user's last response in the context of the interview.
      Provide a quick, actionable tip (max 20 words) or an intervention if the user is struggling significantly.
      
      Return JSON with:
      "tip": "The actionable advice",
      "severity": "low" | "medium" | "high", (low/medium for tips, high for intervention)
      "intervention": boolean (true if the user needs immediate guidance to continue)

      Interview Context:
      ${JSON.stringify(history.slice(-4))}
      Last User Response:
      "${lastMessage}"`;

      const result = await ai.models.generateContent({
        model: "gemini-1.5-flash",
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        config: {
          responseMimeType: "application/json",
        }
      });

      res.json(JSON.parse(result.text));
    } catch (error: any) {
      console.error("Coach Error:", error);
      res.status(500).json({ error: error.message });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
