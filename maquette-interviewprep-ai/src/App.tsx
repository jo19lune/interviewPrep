/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { BrowserRouter, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, BookOpen, MessageSquare, BarChart3, Lock, User } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import Dashboard from './pages/Dashboard';
import Exercises from './pages/Exercises';
import Simulation from './pages/Simulation';
import Analytics from './pages/Analytics';
import Auth from './pages/Auth';
import Profile from './pages/Profile';
import Verify from './pages/Verify';

const Navigation = () => {
  const location = useLocation();
  
  const navItems = [
    { path: '/', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/exercises', label: 'Exercises', icon: BookOpen },
    { path: '/simulation', label: 'Simulation', icon: MessageSquare },
    { path: '/analytics', label: 'Insights', icon: BarChart3 },
  ];

  return (
    <nav className="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-4 py-3 bg-surface-container-lowest border-t border-outline-variant shadow-[0px_-4px_12px_rgba(0,26,94,0.05)] rounded-t-xl transition-all duration-300">
      {navItems.map((item) => {
        const isActive = location.pathname === item.path;
        const Icon = item.icon;
        
        return (
          <Link
            key={item.path}
            to={item.path}
            className={`flex flex-col items-center justify-center px-4 py-1 rounded-xl transition-all duration-200 group ${
              isActive 
                ? 'bg-secondary-container text-on-secondary-container scale-100' 
                : 'text-on-surface-variant hover:bg-surface-container active:scale-95'
            }`}
          >
            <Icon size={isActive ? 24 : 22} strokeWidth={isActive ? 2.5 : 2} />
            <span className={`text-[10px] font-bold mt-1 uppercase tracking-wider ${isActive ? 'opacity-100' : 'opacity-70'}`}>
              {item.label}
            </span>
            {isActive && (
              <motion.div
                layoutId="nav-pill"
                className="absolute inset-0 bg-secondary-container rounded-xl -z-10"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </Link>
        );
      })}
    </nav>
  );
};

const Header = () => {
  const [profilePic, setProfilePic] = React.useState('https://lh3.googleusercontent.com/aida-public/AB6AXuC_I93xl0az1loKxptTgS1v8XLJf4m-MiiNFaGjgbpN2S3Mwc73F0vWAgpIOeod7Z9EwM84O7SobDiTrislDoKBDcd5j_7GOuxVdyNgCq6VyQI5KeTeqgZaYMJw2OIq3A3JeosHMLypHXfOSakQkTwep1gTYFQ9ijDzsHDxCbBJOg-M128Hdin0jUf1qVJ5KxOnbbv5U_NtCO9pfmCQWHPWagFZLHVqkmaHBZCNqoQHFbpX7G5Y6pzF0ed8J_zcpEabhybfTJakdZs');

  React.useEffect(() => {
    fetch('/api/auth/me')
      .then(res => res.json())
      .then(data => {
        if (data.profilePic) setProfilePic(data.profilePic);
      })
      .catch(() => {}); // Fallback to default
  }, []);

  return (
    <header className="bg-surface sticky top-0 z-40 border-b border-outline-variant/30 backdrop-blur-md bg-opacity-80">
      <div className="flex justify-between items-center w-full px-6 py-4 max-w-7xl mx-auto">
        <Link to="/" className="flex items-center gap-3 group">
          <div className="bg-primary-container p-2 rounded-lg text-white group-hover:scale-110 transition-transform">
            <Lock size={20} />
          </div>
          <h1 className="font-display text-xl font-bold text-primary">InterviewPrep</h1>
        </Link>
        <div className="flex items-center gap-4">
          <button className="p-2 rounded-full hover:bg-surface-container-low transition-colors text-primary">
            <BarChart3 size={20} />
          </button>
          <Link to="/profile">
            <div className="w-10 h-10 rounded-full border-2 border-primary overflow-hidden hover:scale-105 transition-transform flex items-center justify-center bg-primary-container/10">
              {profilePic ? (
                <img 
                  src={profilePic}
                  alt="Profile" 
                  className="w-full h-full object-cover"
                />
              ) : (
                <User size={20} className="text-primary" />
              )}
            </div>
          </Link>
        </div>
      </div>
    </header>
  );
};

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen flex flex-col pb-24">
        <Header />
        <main className="flex-1 overflow-hidden">
          <AnimatePresence mode="wait">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/exercises" element={<Exercises />} />
              <Route path="/simulation" element={<Simulation />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/auth" element={<Auth />} />
              <Route path="/profile" element={<Profile />} />
              <Route path="/verify/:token" element={<Verify />} />
            </Routes>
          </AnimatePresence>
        </main>
        <Navigation />
      </div>
    </BrowserRouter>
  );
}
