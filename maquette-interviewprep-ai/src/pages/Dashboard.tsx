import { motion } from 'motion/react';
import { Play, TrendingUp, Mic, Brain, BarChart3, ChevronRight, Sparkles } from 'lucide-react';
import { Link } from 'react-router-dom';
import React, { useState, useEffect } from 'react';

const Dashboard = () => {
  const [userName, setUserName] = useState('Alex');

  useEffect(() => {
    fetch('/api/auth/me')
      .then(res => res.json())
      .then(data => {
        if (data.name) setUserName(data.name);
      })
      .catch(() => {});
  }, []);

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="max-w-7xl mx-auto px-6 py-8 space-y-10"
    >
      {/* Welcome Hero Section */}
      <section className="grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
        <div className="md:col-span-7 space-y-6">
          <h2 className="font-display text-5xl font-bold text-primary">Welcome back, {userName}.</h2>
          <p className="text-lg text-on-surface-variant max-w-xl leading-relaxed">
            You've completed 12 practice sessions this week. Your confidence score is up by 15%.
          </p>
          <Link 
            to="/simulation"
            className="inline-flex items-center gap-3 bg-primary text-white px-8 py-4 rounded-xl font-bold shadow-lg hover:shadow-xl hover:scale-105 active:scale-95 transition-all w-fit"
          >
            <span>Start Training</span>
            <Play size={20} fill="white" />
          </Link>
        </div>
        
        <div className="md:col-span-5">
          <div className="bg-surface-container-lowest p-8 rounded-2xl border border-outline-variant shadow-[0px_4px_12px_rgba(0,26,94,0.05)] relative overflow-hidden group">
            <div className="absolute top-4 right-4">
              <div className="ai-badge-gradient text-[10px] font-bold text-white px-3 py-1 rounded-full flex items-center gap-1">
                <Sparkles size={12} />
                AI INSIGHT
              </div>
            </div>
            
            <div className="flex flex-col items-center gap-6">
              <div className="relative w-40 h-40 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-90">
                  <circle
                    cx="80"
                    cy="80"
                    r="70"
                    stroke="currentColor"
                    strokeWidth="12"
                    fill="transparent"
                    className="text-surface-container-low"
                  />
                  <motion.circle
                    cx="80"
                    cy="80"
                    r="70"
                    stroke="currentColor"
                    strokeWidth="12"
                    fill="transparent"
                    strokeDasharray={440}
                    initial={{ strokeDashoffset: 440 }}
                    animate={{ strokeDashoffset: 440 - (440 * 78) / 100 }}
                    transition={{ duration: 1.5, ease: "easeOut" }}
                    className="text-on-tertiary-container"
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="font-display text-4xl font-bold text-on-tertiary-container">78%</span>
                </div>
              </div>
              <div className="text-center">
                <p className="font-bold text-on-surface">Current Success Rate</p>
                <p className="text-xs text-outline">Based on last 5 simulations</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Bento Grid Content */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Recommendations Column */}
        <section className="md:col-span-1 space-y-4">
          <h3 className="font-display text-2xl font-bold text-primary flex items-center gap-2">
            <TrendingUp size={24} className="text-secondary" />
            Personalized
          </h3>
          <div className="space-y-4">
            {[
              { 
                title: "Improve Pacing", 
                desc: "Your speech speed is 15% faster than optimal in pressure segments.", 
                icon: Mic, 
                color: "bg-secondary-container" 
              },
              { 
                title: "Behavioral Frameworks", 
                desc: "Practice the STAR method for 'Conflict' related prompts.", 
                icon: Brain, 
                color: "bg-tertiary-fixed" 
              }
            ].map((item, i) => (
              <motion.div 
                key={i}
                whileHover={{ x: 5 }}
                className="bg-surface-container-lowest p-5 rounded-xl border border-outline-variant hover:bg-surface-container-low transition-colors cursor-pointer group flex items-start gap-4"
              >
                <div className={`${item.color} p-3 rounded-lg`}>
                  <item.icon size={20} className="text-on-secondary-container" />
                </div>
                <div>
                  <h4 className="font-bold text-primary text-sm">{item.title}</h4>
                  <p className="text-xs text-on-surface-variant leading-relaxed mt-1">{item.desc}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </section>

        {/* Recent Sessions Column */}
        <section className="md:col-span-2 space-y-4">
          <div className="flex justify-between items-end">
            <h3 className="font-display text-2xl font-bold text-primary">Recent Sessions</h3>
            <button className="text-secondary text-sm font-bold hover:underline">View All</button>
          </div>
          <div className="bg-surface-container-lowest rounded-xl border border-outline-variant shadow-sm overflow-hidden overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-[500px]">
              <thead>
                <tr className="bg-surface-container-low border-b border-outline-variant text-xs text-on-surface-variant font-bold uppercase tracking-wider">
                  <th className="px-6 py-4">Role</th>
                  <th className="px-6 py-4">Date</th>
                  <th className="px-6 py-4">Score</th>
                  <th className="px-6 py-4">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant">
                {[
                  { role: "Senior Product Designer", date: "Oct 24, 2023", score: 82, color: "text-on-tertiary-container", bg: "bg-tertiary-fixed" },
                  { role: "Technical Lead", date: "Oct 22, 2023", score: 64, color: "text-error", bg: "bg-error-container" },
                  { role: "UX Researcher", date: "Oct 20, 2023", score: 79, color: "text-on-tertiary-container", bg: "bg-tertiary-fixed" }
                ].map((session, i) => (
                  <tr key={i} className="hover:bg-surface-container-lowest transition-colors group">
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-3">
                        <div className={`w-2.5 h-2.5 rounded-full ${session.color.replace('text', 'bg')}`} />
                        <span className="font-bold text-primary text-sm">{session.role}</span>
                      </div>
                    </td>
                    <td className="px-6 py-5 text-sm text-on-surface-variant">{session.date}</td>
                    <td className="px-6 py-5">
                      <span className={`${session.bg} ${session.color} px-3 py-1 rounded-full font-bold text-xs`}>
                        {session.score}%
                      </span>
                    </td>
                    <td className="px-6 py-5">
                      <button className="text-secondary hover:text-primary transition-colors">
                        <BarChart3 size={20} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>

      {/* Motivation Banner */}
      <section className="relative rounded-2xl overflow-hidden bg-primary p-12 min-h-[250px] flex flex-col justify-center shadow-xl group">
        <div className="absolute inset-0 opacity-30 grayscale saturate-0 group-hover:scale-105 transition-transform duration-700">
          <img 
            src="https://lh3.googleusercontent.com/aida-public/AB6AXuAIctZ9ufgENf9GTS3cT8ZpsirN3eaFmM-hGuswfosKZsSV-6SlTS2XEAcSq_YbXUzDG1nPfZ8n-oD06oKavWnntFbOVwYLCVIxo8OrVj1xa1udHoGoFKWmbRh2KNR6zEeZ0aIddCyDLowTIoQDLcaqd2vEAEhZBlkevxXHbmiYlJRjOl00oVgR79WH9MzVA4OChXzPVFRFTZvq-bc1s2g9BwlGlZaFHtdkTeMDcn64KTkKjOaGvfVSlvoAeS4b2Wd-epk_zuqZg9I" 
            alt="Office background" 
            className="w-full h-full object-cover"
          />
        </div>
        <div className="absolute inset-0 bg-gradient-to-r from-primary via-primary/80 to-transparent" />
        <div className="relative z-10 max-w-2xl space-y-4">
          <div className="flex items-center gap-2">
            <Sparkles size={16} className="text-on-primary-container" />
            <p className="text-on-primary-container font-bold text-[10px] tracking-widest uppercase">Today's Focus</p>
          </div>
          <h2 className="text-white font-display text-4xl font-bold leading-tight">
            "How do you handle disagreement with a manager?"
          </h2>
          <p className="text-primary-fixed-dim text-lg opacity-90">
            This question is currently appearing in 40% of tech interviews. Are you prepared?
          </p>
        </div>
      </section>
    </motion.div>
  );
};

export default Dashboard;
