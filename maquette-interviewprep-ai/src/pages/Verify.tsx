import { motion } from 'motion/react';
import { Mail, CheckCircle2, ShieldAlert, ArrowRight, Loader2 } from 'lucide-react';
import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';

const Verify = () => {
  const { token } = useParams();
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [message, setMessage] = useState('Verifying your email...');

  useEffect(() => {
    const verifyEmail = async () => {
      try {
        const response = await fetch('/api/auth/verify', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token }),
        });

        const data = await response.json();

        if (response.ok) {
          setStatus('success');
          setMessage(data.message);
        } else {
          setStatus('error');
          setMessage(data.error || 'Verification failed');
        }
      } catch (err) {
        setStatus('error');
        setMessage('Network error during verification');
      }
    };

    if (token) {
      verifyEmail();
    }
  }, [token]);

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="max-w-md mx-auto w-full px-6 py-20 flex flex-col items-center text-center"
    >
      <div className="bg-primary-container p-4 rounded-2xl text-white mb-8 shadow-lg">
        <Mail size={40} />
      </div>

      <h2 className="font-display text-3xl font-bold text-primary mb-4">Email Verification</h2>
      
      <div className={`p-8 rounded-3xl border w-full mb-8 ${
        status === 'loading' ? 'bg-surface border-outline-variant' :
        status === 'success' ? 'bg-tertiary-fixed/10 border-tertiary-fixed/30 text-on-tertiary-container' :
        'bg-error-container/10 border-error-container/30 text-error'
      }`}>
        {status === 'loading' && (
          <div className="flex flex-col items-center gap-4">
            <Loader2 size={40} className="animate-spin text-primary" />
            <p className="font-medium">{message}</p>
          </div>
        )}

        {status === 'success' && (
          <div className="flex flex-col items-center gap-4">
            <CheckCircle2 size={40} className="text-tertiary" />
            <p className="font-bold text-lg">{message}</p>
            <p className="text-sm opacity-80">Your account is now fully active. You can start your interview simulations now.</p>
          </div>
        )}

        {status === 'error' && (
          <div className="flex flex-col items-center gap-4">
            <ShieldAlert size={40} className="text-error" />
            <p className="font-bold text-lg">{message}</p>
            <p className="text-sm opacity-80">The link might be expired or invalid. Please request a new verification email from your profile.</p>
          </div>
        )}
      </div>

      <motion.div
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
      >
        <Link 
          to={status === 'success' ? '/' : '/auth'}
          className="bg-primary text-white px-8 py-3 rounded-xl font-bold flex items-center gap-2 shadow-lg"
        >
          {status === 'success' ? 'Go to Dashboard' : 'Back to Login'}
          <ArrowRight size={18} />
        </Link>
      </motion.div>
    </motion.div>
  );
};

export default Verify;
