import { motion, AnimatePresence } from 'motion/react';
import { Mic, Send, Sparkles, Brain, Lightbulb, MessageSquare, Terminal, Settings, X, Sliders, Trophy, Target, LineChart, CheckCircle2, RotateCcw, Plus, Bookmark, Building, Briefcase, AlertCircle } from 'lucide-react';
import React, { useState, useRef, useEffect } from 'react';

interface Scenario {
  id: string;
  role: string;
  company: string;
  questions: string[];
}

interface ChatMessage {
  role: 'user' | 'model';
  parts: [{ text: string }];
}

interface Feedback {
  score: number;
  strengths: string[];
  improvements: string[];
  tips: string[];
  summary: string;
}

const Simulation = () => {
  const [userInput, setUserInput] = useState('');
  const [history, setHistory] = useState<ChatMessage[]>([
    { role: 'model', parts: [{ text: 'Great start on your background. Now, can you tell me about a time you had to lead a cross-functional team through a period of significant ambiguity? How did you align the stakeholders?' }] }
  ]);
  const [loading, setLoading] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [feedback, setFeedback] = useState<Feedback | null>(null);
  const [showScenarioModal, setShowScenarioModal] = useState(false);
  const [scenarios, setScenarios] = useState<Scenario[]>([]);
  const [newScenario, setNewScenario] = useState({ role: '', company: '', questions: '' });
  const [activeScenario, setActiveScenario] = useState<Scenario | null>(null);
  const [seconds, setSeconds] = useState(0);
  const [coachTip, setCoachTip] = useState<{ tip: string; severity: 'low' | 'medium' | 'high'; intervention: boolean } | null>(null);
  const [showCoach, setShowCoach] = useState(false);
  
  // Model Settings
  const [model, setModel] = useState('gemini-1.5-flash');
  const [temperature, setTemperature] = useState(0.7);
  const [topK, setTopK] = useState(40);
  const [topP, setTopP] = useState(0.95);
  const [isListening, setIsListening] = useState(false);

  const recognitionRef = useRef<any>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

  const fetchScenarios = async () => {
    try {
      const res = await fetch('/api/scenarios');
      const data = await res.json();
      setScenarios(data);
    } catch (err) {
      console.error("Failed to fetch scenarios:", err);
    }
  };

  useEffect(() => {
    fetchScenarios();
  }, []);

  const handleSaveScenario = async () => {
    if (!newScenario.role || !newScenario.company) return;
    
    try {
      const response = await fetch('/api/scenarios', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          role: newScenario.role,
          company: newScenario.company,
          questions: newScenario.questions ? newScenario.questions.split('\n').filter(q => q.trim()) : []
        }),
      });

      if (response.ok) {
        setShowScenarioModal(false);
        setNewScenario({ role: '', company: '', questions: '' });
        fetchScenarios();
      }
    } catch (err) {
      console.error("Failed to save scenario:", err);
    }
  };

  useEffect(() => {
    let interval: any;
    if (!feedback && !analyzing) {
      interval = setInterval(() => {
        setSeconds(s => s + 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [feedback, analyzing]);

  const formatTime = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const startScenario = (scenario: Scenario) => {
    setActiveScenario(scenario);
    setSeconds(0);
    const initialPrompt = `Hello, I'm the hiring manager at ${scenario.company}. We are interviewing you for the ${scenario.role} position. ${scenario.questions.length > 0 ? `I'd like to start with some specific questions: ${scenario.questions.join(', ')}.` : "Let's start. Can you tell me why you're interested in this role?"}`;
    
    setHistory([{ role: 'model', parts: [{ text: initialPrompt }] }]);
    setShowScenarioModal(false);
  };

  useEffect(() => {
    // Initialize Web Speech API
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (SpeechRecognition) {
      recognitionRef.current = new SpeechRecognition();
      recognitionRef.current.continuous = true;
      recognitionRef.current.interimResults = true;
      recognitionRef.current.lang = 'en-US';

      recognitionRef.current.onresult = (event: any) => {
        let transcript = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          transcript += event.results[i][0].transcript;
        }
        setUserInput(transcript);
      };

      recognitionRef.current.onend = () => {
        setIsListening(false);
      };

      recognitionRef.current.onerror = (event: any) => {
        console.error('Speech recognition error:', event.error);
        setIsListening(false);
      };
    }

    return () => {
      if (recognitionRef.current) {
        recognitionRef.current.stop();
      }
    };
  }, []);

  const toggleListening = () => {
    if (!recognitionRef.current) {
      alert('Speech recognition is not supported in this browser.');
      return;
    }

    if (isListening) {
      recognitionRef.current.stop();
      setIsListening(false);
    } else {
      setUserInput('');
      recognitionRef.current.start();
      setIsListening(true);
    }
  };

  const scrollToBottom = () => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [history]);

  const handleSendMessage = async () => {
    if (!userInput.trim() || loading || analyzing) return;

    const currentMsg = userInput;
    const userMsg: ChatMessage = { role: 'user', parts: [{ text: currentMsg }] };
    setHistory(prev => [...prev, userMsg]);
    setUserInput('');
    setLoading(true);

    try {
      const response = await fetch('/api/gemini/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: currentMsg,
          history: history.map(item => ({
            role: item.role,
            parts: item.parts
          })),
          model,
          config: {
            temperature,
            topK,
            topP
          }
        }),
      });

      const data = await response.json();
      if (data.error) throw new Error(data.error);

      setHistory(prev => [...prev, { role: 'model', parts: [{ text: data.text }] }]);

      // Call AI Coach after each turn
      const coachResponse = await fetch('/api/gemini/coach', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          history: history.concat(userMsg).map(item => ({
            role: item.role,
            parts: item.parts
          })),
          lastMessage: currentMsg
        }),
      });
      const coachData = await coachResponse.json();
      if (coachData.tip) {
        setCoachTip(coachData);
        setShowCoach(true);
        // Hide minor tips after 8 seconds, keep interventions
        if (!coachData.intervention) {
          setTimeout(() => setShowCoach(false), 8000);
        }
      }

    } catch (error: any) {
      console.error(error);
      setHistory(prev => [...prev, { role: 'model', parts: [{ text: `Error: ${error.message}` }] }]);
    } finally {
      setLoading(false);
    }
  };

  const handleEndSession = async () => {
    if (history.length < 3 || analyzing) return;
    
    setAnalyzing(true);
    try {
      const response = await fetch('/api/gemini/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          history: history.map(item => ({
            role: item.role,
            parts: item.parts
          })),
          model: 'gemini-1.5-pro' // Use Pro for analysis for better results
        }),
      });

      const data = await response.json();
      if (data.error) throw new Error(data.error);
      setFeedback(data);
    } catch (error) {
      console.error("Feedback error:", error);
    } finally {
      setAnalyzing(false);
    }
  };

  const resetSession = () => {
    setHistory([{ role: 'model', parts: [{ text: 'Great start on your background. Now, can you tell me about a time you had to lead a cross-functional team through a period of significant ambiguity? How did you align the stakeholders?' }] }]);
    setFeedback(null);
    setCoachTip(null);
    setShowCoach(false);
    setUserInput('');
    setSeconds(0);
  };

  return (
    <motion.div 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="flex flex-col h-[calc(100vh-140px)] max-w-7xl mx-auto w-full px-6 pt-6 relative"
    >
      {/* Feedback Overlay */}
      <AnimatePresence>
        {feedback && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-primary/40 backdrop-blur-md flex items-center justify-center p-4"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              className="bg-white max-w-4xl w-full max-h-[90vh] overflow-y-auto rounded-3xl shadow-2xl flex flex-col"
            >
              <div className="p-8 border-b border-outline-variant flex justify-between items-center bg-surface-container-lowest sticky top-0 z-10">
                <div className="flex items-center gap-3">
                  <div className="bg-secondary-container p-3 rounded-2xl text-on-secondary-container">
                    <Trophy size={28} />
                  </div>
                  <div>
                    <h3 className="font-display text-2xl font-bold text-primary">Interview Performance</h3>
                    <p className="text-sm text-on-surface-variant font-medium opacity-70">
                       {activeScenario ? `${activeScenario.role} at ${activeScenario.company}` : "Fortune 500 Strategy Lead Simulation"}
                    </p>
                  </div>
                </div>
                <button onClick={() => setFeedback(null)} className="p-2 hover:bg-surface-container rounded-full transition-colors">
                  <X size={24} />
                </button>
              </div>

              <div className="p-8 space-y-10">
                {/* Score & Summary */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                  <div className="md:col-span-1 bg-surface-container p-8 rounded-3xl flex flex-col items-center justify-center text-center">
                    <div className="relative mb-4">
                      <svg className="w-32 h-32 transform -rotate-90">
                        <circle cx="64" cy="64" r="58" stroke="currentColor" strokeWidth="8" fill="transparent" className="text-secondary/10" />
                        <motion.circle 
                          cx="64" cy="64" r="58" stroke="currentColor" strokeWidth="8" fill="transparent" strokeDasharray={364.4}
                          initial={{ strokeDashoffset: 364.4 }}
                          animate={{ strokeDashoffset: 364.4 * (1 - feedback.score / 100) }}
                          transition={{ duration: 2, ease: "easeOut" }}
                          className="text-secondary" 
                        />
                      </svg>
                      <div className="absolute inset-0 flex items-center justify-center flex-col">
                        <span className="text-4xl font-black text-primary">{feedback.score}</span>
                        <span className="text-[10px] font-bold text-outline">SCORE</span>
                      </div>
                    </div>
                    <p className="text-sm font-bold text-secondary uppercase tracking-widest">Great Potential</p>
                  </div>
                  <div className="md:col-span-2 space-y-4">
                    <div className="flex items-center gap-2 text-primary">
                      <Sparkles size={20} className="text-secondary" />
                      <h4 className="font-bold text-lg">AI Feedback Summary</h4>
                    </div>
                    <p className="text-on-surface-variant leading-relaxed font-medium bg-surface-container-low p-6 rounded-2xl border border-outline-variant/30">
                      "{feedback.summary}"
                    </p>
                  </div>
                </div>

                {/* Detailed Breakdown */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div className="space-y-4">
                    <div className="flex items-center gap-2 text-primary font-bold">
                      <CheckCircle2 size={18} className="text-tertiary" />
                      Key Strengths
                    </div>
                    <div className="space-y-3">
                      {feedback.strengths.map((s, i) => (
                        <div key={i} className="flex gap-3 p-4 bg-tertiary-fixed/20 rounded-xl border border-tertiary-fixed/30 text-sm font-medium">
                          <div className="mt-1 flex-shrink-0 w-1.5 h-1.5 rounded-full bg-tertiary" />
                          {s}
                        </div>
                      ))}
                    </div>
                  </div>
                  <div className="space-y-4">
                    <div className="flex items-center gap-2 text-primary font-bold">
                      <Target size={18} className="text-error" />
                      Areas for Growth
                    </div>
                    <div className="space-y-3">
                      {feedback.improvements.map((s, i) => (
                        <div key={i} className="flex gap-3 p-4 bg-error-container/40 rounded-xl border border-error-container/60 text-sm font-medium">
                          <div className="mt-1 flex-shrink-0 w-1.5 h-1.5 rounded-full bg-error" />
                          {s}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Actionable Tips */}
                <div className="bg-primary/5 border border-primary/10 rounded-3xl p-8 space-y-4">
                  <div className="flex items-center gap-2 text-primary font-bold">
                    <Lightbulb size={20} />
                    Career-Ready Tips
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {feedback.tips.map((s, i) => (
                      <div key={i} className="flex gap-3 text-sm text-on-surface-variant leading-relaxed">
                        <span className="text-xs font-black text-primary opacity-30">0{i+1}</span>
                        {s}
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="p-8 mt-auto border-t border-outline-variant flex flex-col sm:flex-row gap-4 bg-surface-container-lowest">
                <button 
                  onClick={resetSession}
                  className="flex-1 bg-surface border border-outline-variant text-primary font-bold py-4 rounded-xl hover:bg-surface-container transition-all flex items-center justify-center gap-2"
                >
                  <RotateCcw size={18} />
                  Try New Scenarios
                </button>
                <button 
                  onClick={() => window.location.href = '/analytics'}
                  className="flex-1 bg-primary text-white font-bold py-4 rounded-xl shadow-lg hover:bg-primary-container transition-all flex items-center justify-center gap-2"
                >
                  <LineChart size={18} />
                  View Analytics History
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Custom Scenario Modal */}
      <AnimatePresence>
        {showScenarioModal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-primary/40 backdrop-blur-md flex items-center justify-center p-4"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              className="bg-white max-w-2xl w-full rounded-3xl shadow-2xl overflow-hidden flex flex-col"
            >
              <div className="p-6 border-b border-outline-variant flex justify-between items-center bg-surface-container-lowest">
                <div className="flex items-center gap-3 text-primary">
                  <Bookmark size={24} className="text-secondary" />
                  <h3 className="font-display text-xl font-bold">Custom Interview Scenarios</h3>
                </div>
                <button onClick={() => setShowScenarioModal(false)} className="p-2 hover:bg-surface-container rounded-full transition-colors">
                  <X size={20} />
                </button>
              </div>

              <div className="p-8 space-y-8 overflow-y-auto max-h-[70vh]">
                {/* Saved Scenarios List */}
                {scenarios.length > 0 && (
                  <div className="space-y-4">
                    <h4 className="text-xs font-black text-on-surface-variant uppercase tracking-widest flex items-center gap-2">
                       <CheckCircle2 size={14} className="text-tertiary" />
                       Your Saved Scenarios
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                       {scenarios.map((s) => (
                         <button 
                           key={s.id}
                           onClick={() => startScenario(s)}
                           className="text-left p-4 rounded-2xl border border-outline-variant/60 bg-surface hover:bg-secondary-container/10 transition-all group"
                         >
                            <div className="font-bold text-primary mb-0.5 group-hover:text-secondary transition-colors">{s.role}</div>
                            <div className="text-[10px] text-on-surface-variant flex items-center gap-1 opacity-70">
                               <Building size={10} /> {s.company}
                            </div>
                         </button>
                       ))}
                    </div>
                  </div>
                )}

                {/* New Scenario Form */}
                <div className="space-y-6">
                  <div className="flex items-center gap-2 text-primary font-bold">
                    <Plus size={18} className="text-secondary" />
                    Create New Scenario
                  </div>
                  
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Dream Role</label>
                      <div className="relative">
                        <Briefcase className="absolute left-4 top-1/2 -translate-y-1/2 text-outline" size={16} />
                        <input 
                          type="text"
                          value={newScenario.role}
                          onChange={(e) => setNewScenario({ ...newScenario, role: e.target.value })}
                          className="w-full bg-surface border border-outline-variant rounded-xl py-3 pl-11 pr-4 text-sm focus:ring-2 focus:ring-secondary-container outline-none"
                          placeholder="e.g. Product Designer"
                        />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Company</label>
                      <div className="relative">
                        <Building className="absolute left-4 top-1/2 -translate-y-1/2 text-outline" size={16} />
                        <input 
                          type="text"
                          value={newScenario.company}
                          onChange={(e) => setNewScenario({ ...newScenario, company: e.target.value })}
                          className="w-full bg-surface border border-outline-variant rounded-xl py-3 pl-11 pr-4 text-sm focus:ring-2 focus:ring-secondary-container outline-none"
                          placeholder="e.g. Google"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Specific Questions (Optional, one per line)</label>
                    <textarea 
                      value={newScenario.questions}
                      onChange={(e) => setNewScenario({ ...newScenario, questions: e.target.value })}
                      className="w-full bg-surface border border-outline-variant rounded-xl p-4 text-sm focus:ring-2 focus:ring-secondary-container outline-none min-h-[100px] resize-none"
                      placeholder="What is your design process?&#10;How do you handle difficult stakeholders?"
                    ></textarea>
                  </div>

                  <button 
                    onClick={handleSaveScenario}
                    disabled={!newScenario.role || !newScenario.company}
                    className="w-full bg-primary text-white font-bold py-4 rounded-xl shadow-lg hover:bg-primary-container disabled:opacity-50 transition-all flex items-center justify-center gap-2"
                  >
                    <Plus size={18} />
                    Save & Start Scenario
                  </button>
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showCoach && coachTip && (
          <motion.div 
            initial={{ opacity: 0, x: 50, scale: 0.9 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className={`fixed top-24 right-10 z-[80] max-w-xs w-full p-5 rounded-2xl shadow-xl border ${
              coachTip.severity === 'high' 
                ? 'bg-error-container border-error-container/60 text-on-error-container' 
                : 'bg-secondary-container border-secondary-container/60 text-on-secondary-container'
            }`}
          >
            <div className="flex items-start gap-4">
              <div className={`p-2 rounded-xl ${coachTip.severity === 'high' ? 'bg-error text-white' : 'bg-secondary text-white'}`}>
                {coachTip.severity === 'high' ? <AlertCircle size={20} /> : <Lightbulb size={20} />}
              </div>
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <h4 className="font-black text-[10px] uppercase tracking-widest opacity-70">
                    {coachTip.intervention ? 'AI COACH INTERVENTION' : 'AI COACH TIP'}
                  </h4>
                  <button onClick={() => setShowCoach(false)} className="opacity-50 hover:opacity-100 transition-opacity">
                    <X size={14} />
                  </button>
                </div>
                <p className="text-sm font-medium leading-relaxed">
                  {coachTip.tip}
                </p>
                {coachTip.intervention && (
                  <button 
                    onClick={() => setShowCoach(false)}
                    className="mt-3 w-full bg-error text-white py-2 rounded-lg text-xs font-bold shadow-md hover:bg-error/90 transition-colors"
                  >
                    Got it, continuing
                  </button>
                )}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Settings Toggle Button */}
      <div className="absolute top-6 right-6 flex gap-3 z-30">
        <button 
          onClick={() => setShowScenarioModal(true)}
          className="bg-white px-4 py-3 rounded-xl border border-outline-variant shadow-sm hover:bg-surface-container transition-colors flex items-center gap-2 text-primary font-bold text-sm"
        >
          <Bookmark size={18} className="text-secondary" />
          <span className="hidden sm:inline">Scenario</span>
        </button>
        <button 
          onClick={() => setShowSettings(true)}
          className="bg-white p-3 rounded-xl border border-outline-variant shadow-sm hover:bg-surface-container transition-colors"
        >
          <Settings size={20} className="text-primary" />
        </button>
      </div>

      {/* Settings Sidebar */}
      <AnimatePresence>
        {showSettings && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowSettings(false)}
              className="absolute inset-0 bg-primary/20 backdrop-blur-sm z-40 lg:hidden"
            />
            <motion.div 
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              className="absolute top-0 right-0 h-full w-full max-w-sm bg-white z-50 border-l border-outline-variant shadow-2xl p-8 flex flex-col gap-8"
            >
              <div className="flex justify-between items-center">
                <h3 className="font-display text-xl font-bold text-primary flex items-center gap-2">
                  <Sliders size={20} className="text-secondary" />
                  Simulation Settings
                </h3>
                <button onClick={() => setShowSettings(false)} className="p-2 hover:bg-surface-container rounded-lg transition-colors">
                  <X size={20} />
                </button>
              </div>

              <div className="space-y-6 overflow-y-auto pr-2">
                <div className="space-y-3">
                  <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">AI Model</label>
                  <select 
                    value={model}
                    onChange={(e) => setModel(e.target.value)}
                    className="w-full bg-surface border border-outline-variant rounded-xl p-3 text-sm focus:ring-2 focus:ring-secondary-container outline-none appearance-none"
                  >
                    <option value="gemini-1.5-flash">Gemini 1.5 Flash (Fast & Concise)</option>
                    <option value="gemini-1.5-pro">Gemini 1.5 Pro (Advanced Reasoning)</option>
                    <option value="gemini-1.5-flash-8b">Gemini 1.5 Flash 8B (Ultra Efficient)</option>
                  </select>
                  <p className="text-[10px] text-outline italic">Pro models may require higher tier API keys.</p>
                </div>

                <div className="space-y-4">
                  <div className="flex justify-between">
                    <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Temperature ({temperature})</label>
                  </div>
                  <input 
                    type="range" min="0" max="1" step="0.1" 
                    value={temperature}
                    onChange={(e) => setTemperature(parseFloat(e.target.value))}
                    className="w-full accent-secondary"
                  />
                  <p className="text-[10px] text-outline leading-tight">Controls randomness: Higher values make the output more creative, lower values more deterministic.</p>
                </div>

                <div className="space-y-4">
                  <div className="flex justify-between">
                    <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Top K ({topK})</label>
                  </div>
                  <input 
                    type="range" min="1" max="100" step="1" 
                    value={topK}
                    onChange={(e) => setTopK(parseInt(e.target.value))}
                    className="w-full accent-secondary"
                  />
                </div>

                <div className="space-y-4">
                  <div className="flex justify-between">
                    <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Top P ({topP})</label>
                  </div>
                  <input 
                    type="range" min="0" max="1" step="0.01" 
                    value={topP}
                    onChange={(e) => setTopP(parseFloat(e.target.value))}
                    className="w-full accent-secondary"
                  />
                </div>
              </div>

              <div className="mt-auto bg-surface-container-low p-4 rounded-xl">
                 <div className="flex items-center gap-2 mb-2 text-secondary">
                   <Sparkles size={16} />
                   <p className="text-xs font-bold uppercase tracking-wider">AI Insight</p>
                 </div>
                 <p className="text-xs text-on-surface-variant">Adjusting <strong>Temperature</strong> can help simulate more unpredictable or "stressful" interview scenarios.</p>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <div className="max-w-4xl mx-auto w-full flex flex-col flex-1 overflow-hidden">
        {/* Model Selector Pills */}
        <div className="flex justify-center mb-6">
          <div className="bg-surface-container-low p-1 rounded-2xl flex gap-1 shadow-sm border border-outline-variant/30 overflow-x-auto no-scrollbar max-w-full">
            {[
              { id: 'gemini-1.5-flash', label: 'Flash', icon: Sparkles, desc: 'Fast & Concise' },
              { id: 'gemini-1.5-pro', label: 'Pro', icon: Brain, desc: 'High Reasoning' },
              { id: 'gemini-1.5-flash-8b', label: 'Lite', icon: Terminal, desc: 'Ultra-Efficient' }
            ].map((m) => (
              <button
                key={m.id}
                onClick={() => setModel(m.id)}
                className={`flex flex-col items-center px-6 py-2 rounded-xl transition-all min-w-[120px] whitespace-nowrap ${
                  model === m.id 
                    ? 'bg-white text-primary shadow-md scale-100 ring-1 ring-outline-variant' 
                    : 'text-on-surface-variant hover:bg-surface-container opacity-70 hover:opacity-100 scale-95'
                }`}
              >
                <div className="flex items-center gap-2 mb-0.5">
                  <m.icon size={14} className={model === m.id ? 'text-secondary' : ''} />
                  <span className="text-xs font-black uppercase tracking-widest">{m.label}</span>
                </div>
                <span className="text-[10px] font-medium opacity-60">{m.desc}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Real-time Feedback Bar */}
        <div className="bg-surface-container-lowest border border-outline-variant rounded-2xl p-4 mb-4 shadow-[0px_4px_12px_rgba(0,26,94,0.05)] flex flex-wrap items-center justify-between gap-6">
          <div className="flex-1 min-w-[150px]">
            <div className="flex justify-between items-center mb-2">
              <span className="text-xs font-bold text-primary flex items-center gap-1">
                <Terminal size={14} /> Clarity
              </span>
              <span className="text-xs font-bold text-on-tertiary-container">82%</span>
            </div>
            <div className="w-full bg-surface-container-high h-2 rounded-full overflow-hidden">
              <motion.div 
                initial={{ width: 0 }}
                animate={{ width: "82%" }}
                transition={{ duration: 1, ease: "easeOut" }}
                className="bg-tertiary-fixed-dim h-full"
              />
            </div>
          </div>
          <div className="hidden md:block h-10 w-[1px] bg-outline-variant" />
          <div className="flex-1 min-w-[150px]">
            <div className="flex justify-between items-center mb-2">
              <span className="text-xs font-bold text-primary flex items-center gap-1">
                <Brain size={14} /> Sentiment
              </span>
              <span className="text-xs font-bold text-secondary">Confident</span>
            </div>
            <div className="flex gap-1 h-3 items-end">
              {[1, 3, 2, 1, 2, 4, 3, 2].map((h, i) => (
                <motion.div 
                  key={i}
                  animate={{ height: [`${h*25}%`, `${(h+1)*20}%`, `${h*25}%`] }}
                  transition={{ duration: 1, repeat: Infinity, delay: i * 0.1 }}
                  className="flex-1 bg-secondary-container rounded-full" 
                />
              ))}
            </div>
          </div>
          <div className="hidden md:block h-10 w-[1px] bg-outline-variant" />
          <div className="flex-1 min-w-[100px] flex flex-col items-center justify-center">
            <span className="text-[10px] font-black text-outline uppercase tracking-wider mb-1">Duration</span>
            <div className="text-lg font-mono font-bold text-primary flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-secondary animate-pulse" />
              {formatTime(seconds)}
            </div>
          </div>
        </div>

        {/* AI Recruiter Identity */}
        <div className="flex flex-col items-center mb-8">
          <div className="relative mb-4">
            <div className="w-24 h-24 rounded-full border-4 border-surface-container-high p-1 bg-white shadow-lg overflow-hidden">
              <img 
                className="w-full h-full object-cover rounded-full" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuBWRGybwvb1AeU7Ix0ba1aCwJ249E141mdSSxeSNMThSs-pMzkfx_9TS5LWhUqFW7ZIUC-gLdBwersFoccugvEza7iQJcoA-hsteU6S20WcPwj5BKoixYuI5eEeBtr4AYc_mJc2JotsP7VKkb4DI7iE5DAKoPAx14lxY20w0nxKENuUkaH1Z-rIyyAfvA7l61jFtWKS06lsbHAg0N_xxPvM2isGQ7sEhAlETB7OE_D8OrLerL1w4V1JzZRD_kU4QwKaGhy6h5vfTxE" 
                alt="AI Recruiter" 
              />
            </div>
            <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 whitespace-nowrap ai-badge-gradient text-white px-4 py-1.5 rounded-full shadow-md flex items-center gap-1.5">
              <Sparkles size={14} fill="white" />
              <span className="text-[10px] font-bold tracking-widest uppercase">AI RECRUITER</span>
            </div>
          </div>
          <h2 className="font-display text-2xl font-bold text-primary text-center">
            {activeScenario ? `${activeScenario.role} Interviewer` : "Senior Talent Partner"}
          </h2>
          <p className="text-xs text-on-surface-variant text-center opacity-80 uppercase tracking-widest font-black">
            {activeScenario ? `Simulating ${activeScenario.company} Interview` : "Simulating a Fortune 500 Strategy Lead Interview"}
          </p>
        </div>

        {/* Chat Interface Area */}
        <div className="flex-1 overflow-y-auto space-y-8 px-2 pb-8 scrollbar-hide">
          {history.map((msg, idx) => (
            <motion.div 
              key={idx}
              initial={{ opacity: 0, x: msg.role === 'model' ? -20 : 20 }}
              animate={{ opacity: 1, x: 0 }}
              className={`flex gap-4 max-w-[90%] lg:max-w-[80%] ${msg.role === 'user' ? 'flex-row-reverse ml-auto' : ''}`}
            >
              <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center overflow-hidden ${msg.role === 'model' ? 'bg-secondary-container text-on-secondary-container' : 'bg-primary text-white border border-outline'}`}>
                {msg.role === 'model' ? (
                  <MessageSquare size={16} />
                ) : (
                  <img src="https://lh3.googleusercontent.com/aida-public/AB6AXuC_I93xl0az1loKxptTgS1v8XLJf4m-MiiNFaGjgbpN2S3Mwc73F0vWAgpIOeod7Z9EwM84O7SobDiTrislDoKBDcd5j_7GOuxVdyNgCq6VyQI5KeTeqgZaYMJw2OIq3A3JeosHMLypHXfOSakQkTwep1gTYFQ9ijDzsHDxCbBJOg-M128Hdin0jUf1qVJ5KxOnbbv5U_NtCO9pfmCQWHPWagFZLHVqkmaHBZCNqoQHFbpX7G5Y6pzF0ed8J_zcpEabhybfTJakdZs" className="w-full h-full object-cover" />
                )}
              </div>
              <div className={`p-5 rounded-2xl shadow-sm ${msg.role === 'model' ? 'bg-white border border-outline-variant rounded-tl-none' : 'bg-primary text-white rounded-tr-none'}`}>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">
                  {msg.parts[0].text}
                </p>
              </div>
            </motion.div>
          ))}

          {loading && (
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex gap-4 max-w-[90%]"
            >
              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-secondary-container flex items-center justify-center animate-pulse">
                <Sparkles size={16} className="text-on-secondary-container" />
              </div>
              <div className="flex gap-1 items-center bg-white border border-outline-variant px-4 py-2 rounded-full shadow-sm">
                <span className="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                <span className="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                <span className="w-1.5 h-1.5 bg-secondary rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
              </div>
            </motion.div>
          )}

          <div ref={chatEndRef} />
        </div>

        {/* Input Area Container */}
        <div className="mt-auto bg-surface pt-4 pb-4">
          <div className="relative group max-w-4xl mx-auto w-full">
            <textarea 
              value={userInput}
              onChange={(e) => setUserInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSendMessage();
                }
              }}
              className="w-full bg-white border border-outline-variant rounded-2xl p-6 pr-[200px] focus:ring-2 focus:ring-secondary-container focus:border-secondary outline-none transition-all shadow-sm resize-none min-h-[100px] text-sm text-on-surface" 
              placeholder={isListening ? "Listening... Speak now." : "Type your response or tap the mic to speak..."}
            ></textarea>
            <div className="absolute right-6 bottom-6 flex gap-3 items-center">
              <button 
                onClick={handleEndSession}
                disabled={history.length < 3 || analyzing}
                className="bg-error-container hover:bg-error/10 text-error px-4 py-2.5 rounded-xl flex items-center gap-2 active:scale-95 transition-all disabled:opacity-30 disabled:grayscale"
              >
                {analyzing ? <Sparkles size={16} className="animate-pulse" /> : <CheckCircle2 size={16} />}
                <span className="font-bold text-xs">{analyzing ? 'Analyzing...' : 'End Session'}</span>
              </button>
              <button 
                onClick={toggleListening}
                className={`w-11 h-11 rounded-full flex items-center justify-center active:scale-95 transition-all shadow-sm ${
                  isListening 
                    ? 'bg-error text-white animate-pulse' 
                    : 'bg-surface-container-high hover:bg-surface-variant text-on-surface-variant'
                }`}
                title={isListening ? "Stop Recording" : "Start Voice Input"}
              >
                <Mic size={20} />
              </button>
              <button 
                onClick={handleSendMessage}
                disabled={loading || !userInput.trim() || analyzing}
                className="bg-primary hover:bg-primary-container text-white px-6 py-2.5 rounded-xl flex items-center gap-2 active:scale-95 transition-all shadow-md disabled:opacity-50"
              >
                <span className="font-bold text-sm">Send</span>
                <Send size={16} />
              </button>
            </div>
          </div>
          <p className="text-center text-[10px] text-outline mt-3 uppercase tracking-widest font-bold opacity-60">
            Press Enter to Send
          </p>
        </div>
      </div>
    </motion.div>
  );
};

export default Simulation;
