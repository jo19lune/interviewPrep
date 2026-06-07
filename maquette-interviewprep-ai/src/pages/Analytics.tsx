import { motion } from 'motion/react';
import { TrendingUp, Rocket, Lightbulb, BadgeCheck, Clock, Award, ChevronRight, MoreVertical, ArrowLeft, Sparkles, PieChart } from 'lucide-react';
import { Link } from 'react-router-dom';

const Analytics = () => {
  return (
    <motion.div 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="max-w-7xl mx-auto px-6 py-8 space-y-8 pb-32"
    >
      {/* Top Header Controls */}
      <div className="flex flex-col md:flex-row justify-between items-center gap-6">
        <div className="flex bg-surface-container-low p-1 rounded-xl w-full md:w-auto shadow-sm border border-outline-variant/30">
          {['7D', '1M', '3M', 'All'].map((range, i) => (
            <button 
              key={range}
              className={`flex-1 md:w-20 py-2.5 px-4 rounded-lg font-bold text-xs transition-all ${
                i === 0 ? 'bg-secondary text-white shadow-md' : 'text-on-surface-variant hover:bg-surface-container'
              }`}
            >
              {range}
            </button>
          ))}
        </div>
        
        <div className="flex items-center gap-4 bg-surface-container-lowest p-3 rounded-2xl border border-outline-variant/20 shadow-sm">
          <div className="relative">
            <img 
              src="https://lh3.googleusercontent.com/aida/ADBb0uiKD7_jdpfzg1huJM90f4JXIgVhYcKTy3oJR3TteDXMcnVtrcUPWvspuxB45l5fv-vRXc8jBejpdFUD2OhV9Ku_QXR7zsMzPaClE5QExZkgifLB_wMEaxaT3Zifr16LgwogOZE3FHgSxahuZEHa-5mrIOktFo_7BEwDZbTEG8rNjVcfQw4zFv9JwF8CXhF53oAAkR8aZpeQ-dd6AzDAX_4LstYh6etamAO3FyHfHKSJgiTEUYmFLZdWcu2npWOspvU8IUyqNQOx9A" 
              alt="Profile" 
              className="w-12 h-12 rounded-full border-2 border-secondary object-cover"
            />
            <div className="absolute -bottom-1 -right-1 bg-on-tertiary-container text-white p-0.5 rounded-full border-2 border-white">
              <BadgeCheck size={14} fill="currentColor" />
            </div>
          </div>
          <div>
            <p className="font-bold text-sm text-primary">Success Rate: 82%</p>
            <p className="text-[10px] font-bold text-on-tertiary-container flex items-center gap-1">
              <TrendingUp size={12} /> +4.2% from last week
            </p>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Main Performance Graph Card */}
        <section className="lg:col-span-8 bg-surface-container-lowest rounded-2xl p-8 border border-outline-variant/20 shadow-sm group">
          <div className="flex justify-between items-center mb-10">
            <h2 className="font-display text-2xl font-bold text-primary">Success Progress</h2>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-secondary shadow-[0_0_8px_rgba(0,96,172,0.4)]"></span>
              <span className="text-[10px] font-bold text-on-surface-variant uppercase tracking-wider opacity-60">Selected Period</span>
            </div>
          </div>
          
          <div className="h-64 w-full relative chart-grid rounded-xl border border-outline-variant/10 overflow-hidden">
            <svg 
              className="w-full h-full absolute bottom-0 left-0 overflow-visible" 
              preserveAspectRatio="none" 
              viewBox="0 0 800 240"
            >
              <defs>
                <linearGradient id="chartGradient" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="5%" stopColor="#0060ac" stopOpacity="0.2" />
                  <stop offset="95%" stopColor="#0060ac" stopOpacity="0" />
                </linearGradient>
              </defs>
              <motion.path 
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ duration: 1.5, ease: "easeInOut" }}
                d="M0,200 Q100,180 200,140 T400,100 T600,60 T800,45 V240 H0 Z" 
                fill="url(#chartGradient)" 
              />
              <motion.path 
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ duration: 1.5, ease: "easeInOut" }}
                d="M0,200 Q100,180 200,140 T400,100 T600,60 T800,45" 
                fill="none" 
                stroke="#0060ac" 
                strokeLinecap="round" 
                strokeWidth="4" 
              />
              {[200, 400, 600].map((x, i) => {
                const y = i === 0 ? 140 : i === 1 ? 100 : 60;
                return (
                  <circle key={x} cx={x} cy={y} fill="white" r="4" stroke="#0060ac" strokeWidth="2" />
                );
              })}
              <circle cx="800" cy="45" fill="#0060ac" r="6" />
            </svg>
            
            <div className="absolute left-4 top-0 h-full flex flex-col justify-between text-[10px] text-outline font-bold py-4 opacity-40">
              <span>100%</span>
              <span>75%</span>
              <span>50%</span>
              <span>25%</span>
              <span>0%</span>
            </div>
          </div>
          <div className="flex justify-between mt-6 px-4 text-[10px] text-outline font-bold uppercase tracking-widest opacity-60">
            {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => <span key={day}>{day}</span>)}
          </div>
        </section>

        {/* Key Metrics Grid */}
        <section className="lg:col-span-4 grid grid-cols-2 lg:grid-cols-1 gap-6">
          <div className="grid grid-cols-2 gap-6 h-full">
            {[
              { icon: Rocket, label: "Total Simulations", value: "24" },
              { icon: PieChart, label: "Avg. Clarity Score", value: "78%" },
              { icon: Clock, label: "Hours Practiced", value: "12.5h" },
              { icon: Award, label: "Top Role", value: "Product Manager", isSmall: true }
            ].map((metric, i) => (
              <div key={i} className="bg-surface-container-lowest rounded-2xl p-6 border border-outline-variant/20 shadow-sm flex flex-col justify-between hover:scale-[1.02] transition-transform">
                <div>
                  <metric.icon size={20} className="text-secondary mb-3" />
                  <p className="text-[10px] font-bold text-on-surface-variant uppercase tracking-wider opacity-60">{metric.label}</p>
                </div>
                <p className={`font-display font-bold text-primary ${metric.isSmall ? 'text-sm mt-2' : 'text-3xl'}`}>
                  {metric.value}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Skill Breakdown Section */}
        <section className="lg:col-span-6 bg-surface-container-lowest rounded-2xl p-8 border border-outline-variant/20 shadow-sm">
          <h2 className="font-display text-2xl font-bold text-primary mb-8">Skill Proficiency</h2>
          <div className="space-y-8">
            {[
              { label: "Communication", score: 85 },
              { label: "Technical Knowledge", score: 92 },
              { label: "Structure (STAR)", score: 74 },
              { label: "Confidence", score: 78 }
            ].map((skill, i) => (
              <div key={i} className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="font-bold text-sm text-on-surface">{skill.label}</span>
                  <span className="text-xs font-bold text-secondary">{skill.score}%</span>
                </div>
                <div className="w-full bg-surface-container h-2.5 rounded-full overflow-hidden">
                  <motion.div 
                    initial={{ width: 0 }}
                    whileInView={{ width: `${skill.score}%` }}
                    transition={{ duration: 1, delay: i * 0.1 }}
                    className="bg-secondary h-full rounded-full shadow-[0_0_10px_rgba(0,96,172,0.2)]" 
                  />
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Insights Section */}
        <section className="lg:col-span-6 flex flex-col gap-6">
          <div className="bg-primary-container rounded-2xl p-8 border border-outline-variant/30 relative overflow-hidden flex-1 group shadow-lg">
            <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
              <Sparkles size={80} className="text-on-primary-container" />
            </div>
            <div className="relative z-10 space-y-6">
              <div className="flex items-center gap-3">
                <span className="ai-badge-gradient px-4 py-1.5 rounded-full text-[10px] font-bold text-white uppercase tracking-widest shadow-md">AI Insight</span>
              </div>
              <h3 className="font-display text-3xl text-on-primary-container font-bold">Balanced Development</h3>
              <p className="text-on-primary-container/80 leading-relaxed text-lg italic">
                "Your technical scores are soaring, but consider practicing more <strong>'Conflict Resolution'</strong> scenarios to balance your profile. You tend to excel in architectural questions but briefness in behavioral answers is affecting your overall structure score."
              </p>
              <button className="bg-surface-container-lowest text-primary px-6 py-3 rounded-xl font-bold shadow-md hover:scale-105 transition-transform flex items-center gap-2 w-fit">
                Start Suggested Practice
                <ChevronRight size={18} />
              </button>
            </div>
          </div>
        </section>
      </div>
    </motion.div>
  );
};

export default Analytics;
