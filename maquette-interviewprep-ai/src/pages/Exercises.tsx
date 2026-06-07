import { motion } from 'motion/react';
import { Search, Sparkles, TrendingUp, ArrowRight, ListChecks, Database, Gavel, Layout, PieChart, Package, ChevronRight } from 'lucide-react';

const Exercises = () => {
  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="max-w-7xl mx-auto px-6 py-8 space-y-10"
    >
      {/* Search Header */}
      <div className="max-w-3xl mx-auto w-full">
        <div className="relative group">
          <Search className="absolute left-5 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-primary transition-colors" size={20} />
          <input 
            type="text" 
            className="w-full pl-14 pr-6 py-5 bg-surface-container-lowest border border-outline-variant rounded-2xl focus:ring-2 focus:ring-secondary-container focus:border-secondary outline-none transition-all shadow-sm font-medium text-on-surface"
            placeholder="Search exercises, skills, or modules..."
          />
        </div>
      </div>

      {/* AI Hero Suggestion */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2 bg-primary text-white rounded-2xl p-10 flex flex-col justify-between relative overflow-hidden shadow-xl group">
          <div className="relative z-10 space-y-6">
            <div className="ai-badge-gradient inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-[10px] font-bold uppercase tracking-widest shadow-lg">
              <Sparkles size={14} fill="white" />
              AI Recommended
            </div>
            <div className="space-y-3">
              <h2 className="font-display text-4xl font-bold leading-tight">Master the "Behavioral Edge"</h2>
              <p className="text-secondary-fixed opacity-90 max-w-lg leading-relaxed text-lg">
                Based on your recent mock interview, we suggest focusing on the STAR method exercises to improve your storytelling impact.
              </p>
            </div>
            <button className="bg-white text-primary font-bold px-8 py-3 rounded-xl flex items-center gap-2 hover:scale-105 active:scale-95 transition-all shadow-lg w-fit">
              Start Module <ArrowRight size={18} />
            </button>
          </div>
          {/* Decorative Abstract Art */}
          <div className="absolute -right-20 -top-20 w-80 h-80 opacity-20 bg-secondary-container rounded-full blur-[100px] group-hover:scale-110 transition-transform duration-1000"></div>
          <div className="absolute -left-10 -bottom-10 w-40 h-40 opacity-10 bg-secondary rounded-full blur-[60px]"></div>
        </div>

        <div className="bg-surface-container-high rounded-2xl p-10 flex flex-col items-center justify-center text-center shadow-md border border-outline-variant group">
          <motion.div 
            whileHover={{ scale: 1.1, rotate: 5 }}
            className="w-20 h-20 rounded-full bg-secondary-fixed flex items-center justify-center mb-6 shadow-sm"
          >
            <TrendingUp size={40} className="text-secondary" />
          </motion.div>
          <h3 className="font-display text-3xl font-bold text-primary mb-2">84% Readiness</h3>
          <p className="text-on-surface-variant font-medium opacity-80 leading-relaxed">
            You've completed 12 modules this week. Keep up the momentum!
          </p>
        </div>
      </section>

      {/* Section: MCQs */}
      <section className="space-y-6">
        <div className="flex items-center gap-4 mb-4">
          <div className="w-1 h-8 bg-secondary rounded-full" />
          <h2 className="font-display text-2xl font-bold text-primary tracking-tight">Multiple Choice (MCQs)</h2>
          <span className="text-secondary font-bold text-sm">/ Foundation</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            { 
              title: "Core CS Fundamentals", 
              desc: "Data structures, algorithms, and complexity analysis basics.", 
              mins: "15 MINS",
              progress: 60,
              level: "Intermediate",
              color: "text-on-tertiary-container",
              icon: ListChecks
            },
            { 
              title: "System Design Quiz", 
              desc: "Scalability, load balancing, and distributed systems architecture.", 
              mins: "10 MINS",
              progress: 40,
              level: "Expert",
              color: "text-error",
              icon: Database
            },
            { 
              title: "Ethics & Compliance", 
              desc: "Corporate governance, data privacy, and workplace ethics.", 
              mins: "20 MINS",
              progress: 100,
              level: "Beginner",
              color: "text-on-tertiary-container",
              icon: Gavel
            }
          ].map((card, i) => (
            <motion.div 
              key={i}
              whileHover={{ y: -5 }}
              className="bg-surface-container-lowest border border-outline-variant rounded-2xl p-6 shadow-sm hover:shadow-md transition-all cursor-pointer group"
            >
              <div className="flex justify-between items-start mb-6">
                <div className="bg-secondary-fixed p-4 rounded-xl text-secondary group-hover:bg-secondary group-hover:text-white transition-colors">
                  <card.icon size={24} />
                </div>
                <span className="text-[10px] font-bold text-outline opacity-60 tracking-widest">{card.mins}</span>
              </div>
              <div className="space-y-4">
                <h4 className="font-bold text-lg text-primary group-hover:text-secondary transition-colors line-clamp-1">{card.title}</h4>
                <p className="text-sm text-on-surface-variant line-clamp-2 leading-relaxed opacity-80">{card.desc}</p>
                <div className="pt-2 border-t border-outline-variant/30 flex items-center gap-3">
                  <div className="h-1.5 flex-1 bg-surface-container rounded-full overflow-hidden">
                    <motion.div 
                      initial={{ width: 0 }}
                      whileInView={{ width: `${card.progress}%` }}
                      className={`h-full ${card.progress === 100 ? 'bg-on-tertiary-container' : card.progress < 50 ? 'bg-error' : 'bg-secondary'}`}
                    />
                  </div>
                  <span className={`text-[10px] font-black uppercase tracking-tighter ${card.color}`}>{card.level}</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Section: Logic & Aptitude */}
      <section className="space-y-6 pb-8">
        <div className="flex items-center gap-4 mb-4">
          <div className="w-1 h-8 bg-secondary rounded-full" />
          <h2 className="font-display text-2xl font-bold text-primary tracking-tight">Logic & Aptitude</h2>
          <span className="text-secondary font-bold text-sm">/ Analytical</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {[
            { 
              title: "Abstract Reasoning", 
              desc: "Pattern recognition and spatial intelligence puzzles.", 
              time: "30m",
              img: "https://lh3.googleusercontent.com/aida-public/AB6AXuB-MeQ7HsOB_7QYbvuOgwWW-7V76pQ86mDKSWAR3woMQIOeN_24bDAljw9qCUuOdA91vOkgNEz86nXTFufqGMTd2prXsHZ2Za2l6O61t8p_VmJwtXqDlolS1E0xvhrl9iEP24aqXPGkZ6CEb32QDT2gEZXY9NrwLgLKOclirTEdGjj9GQJX2KNXCoKOm25M5fRqi59bxJlrm5ChTgxl8A6b9xTyLCOYWn7dR_fYttgjMd3RYT2ANmPnXV_mnyD9pEh5nTumJEyzuPo"
            },
            { 
              title: "Quantitative Analysis", 
              desc: "Data interpretation, statistics, and business arithmetic.", 
              time: "45m",
              img: "https://lh3.googleusercontent.com/aida-public/AB6AXuDW0vUS69xxSzY5VuQNlU2js9x6u1ZlM2BECxHck82d0abQ_SfcUv__XXcCQaAwaQgrMoWFeT46X0rBR3O2dJdx4KGYicLvKwC6cN57ddzxljigi_3m8BKHol-czaINvD19Gfw-5GCommKFGgzhvE9MAzRuYv7n2AL4WxOswYsoC8-DgCb03nGGqIoGulOGoFnAilYTXq8cCIVIztHz8o4lIn2IqoE0CQHpEyssDUm_MgdzzsQS6kGDmPQn3_7bN0p_0sscoxkHSJs"
            }
          ].map((item, i) => (
            <div key={i} className="flex bg-surface-container-lowest border border-outline-variant rounded-2xl overflow-hidden hover:shadow-lg transition-all group h-44">
              <div className="w-1/3 relative overflow-hidden">
                <img className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" src={item.img} alt={item.title} />
                <div className="absolute inset-0 bg-primary opacity-20 group-hover:opacity-10 transition-opacity"></div>
              </div>
              <div className="p-8 flex flex-col justify-center flex-1 space-y-3">
                <div className="flex justify-between items-center">
                  <h4 className="font-bold text-lg text-primary">{item.title}</h4>
                  <span className="text-secondary font-bold text-sm tracking-tight">{item.time}</span>
                </div>
                <p className="text-sm text-on-surface-variant opacity-80">{item.desc}</p>
                <div className="flex items-center gap-6 pt-2">
                  <button className="text-secondary font-bold text-xs uppercase hover:underline opacity-80 hover:opacity-100 transition-all tracking-wider">Preview</button>
                  <button className="bg-primary text-white text-[10px] px-6 py-2.5 rounded-xl font-black uppercase tracking-widest shadow-md hover:bg-primary-container active:scale-95 transition-all">Launch</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </motion.div>
  );
};

export default Exercises;
