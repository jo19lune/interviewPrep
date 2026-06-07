import { motion, AnimatePresence } from 'motion/react';
import { User, Camera, Save, ArrowLeft, LogOut, CheckCircle2, ShieldAlert, Bookmark, Building, Briefcase, ChevronRight } from 'lucide-react';
import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const Profile = () => {
  const [name, setName] = useState('');
  const [profilePic, setProfilePic] = useState('');
  const [email, setEmail] = useState('');
  const [userId, setUserId] = useState('');
  const [verified, setVerified] = useState(false);
  const [scenarios, setScenarios] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [resending, setResending] = useState(false);
  const [message, setMessage] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    fetch('/api/auth/me')
      .then(res => res.json())
      .then(data => {
        setName(data.name || '');
        setProfilePic(data.profilePic || '');
        setEmail(data.email || '');
        setUserId(data.id || '');
        setVerified(data.verified || false);
        setScenarios(data.scenarios || []);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setLoading(false);
      });
  }, []);

  const handleResend = async () => {
    setResending(true);
    setMessage('');
    try {
      const response = await fetch('/api/auth/resend-verification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await response.json();
      if (response.ok) {
        setMessage(`Verification email resent! (Demo link: ${data.verificationLink})`);
      } else {
        throw new Error(data.error);
      }
    } catch (err: any) {
      setMessage(`Error: ${err.message}`);
    } finally {
      setResending(false);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');

    try {
      const response = await fetch('/api/auth/profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: userId, name, profilePic }),
      });

      if (!response.ok) throw new Error('Failed to update profile');

      setMessage('Profile updated successfully!');
      setTimeout(() => setMessage(''), 3000);
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    // Demo logout
    navigate('/auth');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <motion.div 
          animate={{ rotate: 360 }}
          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
          className="text-secondary"
        >
          <User size={40} />
        </motion.div>
      </div>
    );
  }

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="max-w-2xl mx-auto w-full px-6 py-12"
    >
      <div className="flex items-center justify-between mb-10">
        <div className="flex items-center gap-4">
          <Link to="/" className="p-2 hover:bg-surface-container rounded-full transition-colors text-primary">
            <ArrowLeft size={24} />
          </Link>
          <h2 className="font-display text-3xl font-bold text-primary">Your Profile</h2>
        </div>
        <button 
          onClick={handleLogout}
          className="flex items-center gap-2 text-error font-bold text-sm hover:underline"
        >
          <LogOut size={18} />
          Log Out
        </button>
      </div>

      <div className="bg-surface-container-lowest border border-outline-variant rounded-2xl p-8 shadow-sm space-y-10">
        {/* Profile Picture Upload Area */}
        <div className="flex flex-col items-center gap-6">
          <div className="relative group">
            <div className="w-32 h-32 rounded-full border-4 border-secondary overflow-hidden shadow-xl">
              <img 
                src={profilePic || 'https://via.placeholder.com/150'} 
                alt="Profile" 
                className="w-full h-full object-cover"
              />
            </div>
            <label className="absolute bottom-0 right-0 bg-primary text-white p-3 rounded-full shadow-lg cursor-pointer hover:scale-110 active:scale-95 transition-all">
              <Camera size={20} />
              <input 
                type="text" 
                className="hidden" 
                onChange={(e) => setProfilePic(e.target.value)} 
                placeholder="Enter image URL"
              />
            </label>
            <div className="mt-4 text-center">
              <label className="text-[10px] font-bold text-outline uppercase tracking-widest block mb-2">Profile Image URL</label>
              <input 
                 type="text"
                 value={profilePic}
                 onChange={(e) => setProfilePic(e.target.value)}
                 className="w-full max-w-xs bg-surface border border-outline-variant rounded-lg py-2 px-3 text-xs focus:ring-2 focus:ring-secondary-container transition-all"
                 placeholder="https://example.com/avatar.jpg"
              />
            </div>
          </div>
        </div>

        <form onSubmit={handleSave} className="space-y-6">
          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant px-1 uppercase tracking-wider">Display Name</label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 -translate-y-1/2 text-outline" size={18} />
              <input 
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-surface border border-outline-variant rounded-xl py-4 pl-12 pr-4 text-sm focus:ring-2 focus:ring-secondary-container transition-all outline-none"
                placeholder="Your name"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant px-1 uppercase tracking-wider opacity-60">Email Address (Read Only)</label>
            <input 
              type="email"
              value={email}
              readOnly
              className="w-full bg-surface-container border border-outline-variant rounded-xl py-4 px-4 text-sm opacity-60 cursor-not-allowed"
            />
          </div>

          <AnimatePresence>
            {message && (
              <motion.div 
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="bg-on-tertiary-container/10 text-on-tertiary-container p-4 rounded-xl text-sm font-bold flex items-center gap-3 border border-on-tertiary-container/20"
              >
                <CheckCircle2 size={20} />
                {message}
              </motion.div>
            )}
          </AnimatePresence>

          <motion.button 
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            disabled={saving}
            className="w-full bg-primary text-white font-bold text-sm py-4 rounded-xl shadow-lg hover:bg-primary-container transition-all flex items-center justify-center gap-3 disabled:opacity-50"
          >
            {saving ? 'Saving...' : 'Save Changes'}
            <Save size={18} />
          </motion.button>
        </form>
      </div>

      {scenarios.length > 0 && (
        <div className="mt-10 space-y-6">
          <div className="flex items-center gap-3 text-primary">
            <Bookmark size={24} className="text-secondary" />
            <h3 className="font-display text-2xl font-bold">Your Custom Scenarios</h3>
          </div>
          
          <div className="grid grid-cols-1 gap-4">
            {scenarios.map((s) => (
              <motion.div 
                key={s.id}
                whileHover={{ x: 5 }}
                className="bg-surface-container-lowest border border-outline-variant p-6 rounded-2xl flex items-center justify-between group cursor-pointer"
                onClick={() => navigate('/simulation')}
              >
                <div className="flex items-center gap-6">
                  <div className="w-12 h-12 rounded-xl bg-primary/5 flex items-center justify-center text-primary border border-primary/10">
                    <Briefcase size={24} />
                  </div>
                  <div>
                    <h4 className="font-bold text-lg text-primary">{s.role}</h4>
                    <div className="flex items-center gap-4 text-xs text-on-surface-variant font-medium opacity-70">
                      <span className="flex items-center gap-1"><Building size={12} /> {s.company}</span>
                      <span className="flex items-center gap-1"><CheckCircle2 size={12} /> {s.questions?.length || 0} Custom Questions</span>
                    </div>
                  </div>
                </div>
                <ChevronRight className="text-outline group-hover:text-primary transition-colors" size={20} />
              </motion.div>
            ))}
          </div>
        </div>
      )}

      <div className="mt-8 bg-surface-container-low p-6 rounded-2xl flex items-start gap-4">
        <div className={`${verified ? 'bg-secondary-container text-on-secondary-container' : 'bg-error-container text-error'} p-3 rounded-xl transition-colors`}>
          {verified ? <CheckCircle2 size={24} /> : <ShieldAlert size={24} />}
        </div>
        <div className="flex-1">
          <h4 className="font-bold text-primary mb-1">
            {verified ? 'Your Account is Verified' : 'Account Verification Pending'}
          </h4>
          <p className="text-sm text-on-surface-variant opacity-80 leading-relaxed mb-4">
            {verified 
              ? 'Your personal information is stored securely. Updating your name helps our AI provide a more personalized coaching experience.' 
              : 'Please verify your email address to access all features, including advanced interview analytics and certification badges.'}
          </p>
          {!verified && (
            <button 
              onClick={handleResend}
              disabled={resending}
              className="text-xs font-bold text-secondary uppercase tracking-widest hover:underline disabled:opacity-50"
            >
              {resending ? 'Sending...' : 'Resend Verification Email'}
            </button>
          )}
        </div>
      </div>
    </motion.div>
  );
};

export default Profile;
