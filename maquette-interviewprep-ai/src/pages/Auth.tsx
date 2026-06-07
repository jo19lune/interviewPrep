import { motion } from 'motion/react';
import { Mail, Lock, Sparkles, Terminal, ShieldAlert, Trash2, ArrowRight } from 'lucide-react';
import React, { useState } from 'react';

const Auth = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setMessage('');

    const endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Something went wrong');
      }

      if (isLogin) {
        setMessage('Login successful! Redirecting...');
        // In a real app, you'd store the token/session and redirect
        setTimeout(() => window.location.href = '/', 1500);
      } else {
        setMessage(`${data.message}`);
        if (data.verificationLink) {
           console.log("Mocking verification email send to: ", data.verificationLink);
           // In a demo, we might want to auto-redirect or show a link if requested
           // But according to prompt, user should marked as verified after clicking it.
           // I'll show a message and maybe provide the link for testing convenience in this sandboxed env
           setMessage(`Account created! A verification link was sent to your email. (Demo link: ${data.verificationLink})`);
        }
        setIsLogin(true);
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 1.05 }}
      className="max-w-md mx-auto w-full px-6 py-12 flex flex-col gap-10 items-center justify-center min-h-[calc(100vh-100px)]"
    >
      {/* Welcome Header */}
      <div className="text-center space-y-2">
        <div className="bg-primary-container p-3 rounded-2xl text-white inline-block mb-4 shadow-lg">
           <Terminal size={32} />
        </div>
        <h2 className="font-display text-4xl font-bold text-primary">
          {isLogin ? 'Welcome back' : 'Create Account'}
        </h2>
        <p className="text-on-surface-variant font-medium opacity-80">
          {isLogin ? 'Your career breakthrough starts here.' : 'Start your journey to professional excellence.'}
        </p>
      </div>

      {/* Auth Card */}
      <div className="w-full bg-surface-container-lowest border border-outline-variant rounded-2xl p-8 shadow-[0px_4px_24px_rgba(0,26,94,0.08)] space-y-8">
        {error && (
          <div className="bg-error-container text-error p-3 rounded-xl text-xs font-bold flex items-center gap-2">
            <ShieldAlert size={16} />
            {error}
          </div>
        )}
        {message && (
          <div className="bg-tertiary-fixed text-on-tertiary-container p-3 rounded-xl text-xs font-bold flex items-center gap-2">
            <Sparkles size={16} />
            {message}
          </div>
        )}

        <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
          {/* Email Field */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant px-1 uppercase tracking-wider">Email Address</label>
            <div className="relative group">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-secondary transition-colors" size={18} />
              <input 
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-surface border border-outline-variant rounded-xl py-4 pl-12 pr-4 text-sm focus:ring-2 focus:ring-secondary-container focus:border-secondary transition-all outline-none"
                placeholder="name@company.com"
                required
              />
            </div>
          </div>

          {/* Password Field */}
          <div className="space-y-2">
            <div className="flex justify-between items-center px-1">
              <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Password</label>
              {isLogin && <button type="button" className="text-xs font-bold text-secondary hover:underline">Forgot password?</button>}
            </div>
            <div className="relative group">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-secondary transition-colors" size={18} />
              <input 
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-surface border border-outline-variant rounded-xl py-4 pl-12 pr-4 text-sm focus:ring-2 focus:ring-secondary-container focus:border-secondary transition-all outline-none"
                placeholder="••••••••"
                required
              />
            </div>
          </div>

          {/* Submit Button */}
          <motion.button 
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            disabled={loading}
            className="bg-primary text-white font-bold text-sm py-4 rounded-xl shadow-lg hover:bg-primary-container transition-all flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {loading ? 'Processing...' : isLogin ? 'Log In' : 'Sign Up'}
            <ArrowRight size={18} />
          </motion.button>
        </form>

        {/* Divider */}
        <div className="relative flex items-center py-2">
          <div className="flex-grow border-t border-outline-variant opacity-30"></div>
          <span className="px-4 text-[10px] text-outline font-black uppercase tracking-[0.2em] opacity-40">OR CONTINUE WITH</span>
          <div className="flex-grow border-t border-outline-variant opacity-30"></div>
        </div>

        {/* Social Logins */}
        <div className="grid grid-cols-2 gap-4">
          <motion.button 
            whileHover={{ y: -2 }}
            className="flex items-center justify-center gap-3 border border-outline-variant py-3 rounded-xl hover:bg-surface-container transition-all active:scale-95 shadow-sm"
          >
            <img 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAl9bMlqijON7EIHWarRNjQLlkm0rS1hJgW23xfnbDTCN0JMoU9uZpXa6b84WnNv4n8rG0T2m1NoruPRFrlUWpOY9YGMAvLEUWtwBfYTAvF79q8ahmShKSYbO8CQ0LAp18o1RDIin2NlsBYacsG_r7ix7xHsIlsqOpKQD-pDwVBKtGllZxVUThfJhMrZPq268xNOAyrZokKfnMQmcXvK7nqx-4r6spMnnjwCZAqlCyYxEMZexTZHX2cD06YAzR7A3pmxVzR9fpZsTI" 
              className="w-5 h-5" 
              alt="Google"
            />
            <span className="text-xs font-bold text-on-surface">Google</span>
          </motion.button>
          <motion.button 
            whileHover={{ y: -2 }}
            className="flex items-center justify-center gap-3 border border-outline-variant py-3 rounded-xl hover:bg-surface-container transition-all active:scale-95 shadow-sm"
          >
            <div className="bg-secondary-container w-5 h-5 rounded flex items-center justify-center">
              <span className="text-[10px] font-black text-white italic">in</span>
            </div>
            <span className="text-xs font-bold text-on-surface">SSO</span>
          </motion.button>
        </div>
      </div>

      {/* AI Teaser */}
      <div className="relative overflow-hidden bg-gradient-to-br from-primary-container to-secondary rounded-2xl p-8 text-white ai-glow shadow-xl w-full">
        <div className="relative z-10 space-y-4">
          <div className="flex items-center gap-2">
            <span className="bg-white/20 backdrop-blur-md px-3 py-1 rounded-full text-[10px] font-bold tracking-widest uppercase shadow-sm">AI Insights</span>
          </div>
          <h4 className="font-display text-2xl font-bold leading-tight">Master your next interview.</h4>
          <p className="text-xs opacity-90 leading-relaxed max-w-[80%]">
            Join 50k+ professionals using our proprietary AI simulation engine to land top-tier roles.
          </p>
        </div>
        <div className="absolute -right-6 -bottom-6 opacity-10 transform rotate-12 scale-150">
          <Sparkles size={120} />
        </div>
      </div>

      {/* Footer Links */}
      <div className="text-center space-y-12 w-full">
        <p className="text-sm font-medium text-on-surface-variant">
          {isLogin ? "Don't have an account? " : "Already have an account? "}
          <button 
            onClick={() => setIsLogin(!isLogin)}
            className="text-secondary font-bold hover:underline ml-1"
          >
            {isLogin ? 'Create Account' : 'Log In'}
          </button>
        </p>
        
        <footer className="pt-8 border-t border-outline-variant/30 space-y-6">
          <div className="flex justify-center items-center gap-3 opacity-60">
            <ShieldAlert size={18} className="text-outline" />
            <p className="text-[10px] font-medium text-on-surface-variant max-w-xs leading-tight">
              We value your privacy. InterviewPrep is fully GDPR compliant and uses enterprise-grade encryption.
            </p>
          </div>
          <div className="flex justify-center gap-8">
            <button className="text-[10px] font-bold text-secondary uppercase tracking-widest hover:underline">Privacy Policy</button>
            <button className="text-[10px] font-bold text-error uppercase tracking-widest hover:underline flex items-center gap-2">
              <Trash2 size={12} />
              Right to be forgotten
            </button>
          </div>
        </footer>
      </div>

      {/* Background Orbs */}
      <div className="fixed inset-0 -z-10 pointer-events-none overflow-hidden opacity-50">
        <div className="absolute top-[-10%] right-[-5%] w-[400px] h-[400px] bg-secondary-container/20 rounded-full blur-[120px]"></div>
        <div className="absolute bottom-[-10%] left-[-5%] w-[400px] h-[400px] bg-primary-container/10 rounded-full blur-[120px]"></div>
      </div>
    </motion.div>
  );
};

export default Auth;
