import { useEffect, useState } from "react";
import { Routes, Route, Link, useLocation } from "react-router-dom";
import { invoke } from "@tauri-apps/api/tauri";
import { 
  Home, 
  Package, 
  Activity, 
  TestTube2, 
  BarChart3, 
  Settings,
  Terminal
} from "lucide-react";
import Dashboard from "./views/Dashboard";
import BuildView from "./views/BuildView";
import ModulesView from "./views/ModulesView";
import TestsView from "./views/TestsView";
import AnalyticsView from "./views/AnalyticsView";
import SettingsView from "./views/SettingsView";

function App() {
  const [initialized, setInitialized] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const location = useLocation();

  useEffect(() => {
    invoke("init_manager")
      .then(() => setInitialized(true))
      .catch((err) => setError(err as string));
  }, []);

  const navItems = [
    { path: "/", icon: Home, label: "Dashboard" },
    { path: "/build", icon: Terminal, label: "Build" },
    { path: "/modules", icon: Package, label: "Modules" },
    { path: "/tests", icon: TestTube2, label: "Tests" },
    { path: "/analytics", icon: BarChart3, label: "Analytics" },
    { path: "/settings", icon: Settings, label: "Settings" },
  ];

  if (error) {
    return (
      <div className="h-screen flex items-center justify-center bg-gray-900">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-500 mb-4">Initialization Error</h1>
          <p className="text-gray-300">{error}</p>
        </div>
      </div>
    );
  }

  if (!initialized) {
    return (
      <div className="h-screen flex items-center justify-center bg-gray-900">
        <div className="text-center">
          <Activity className="w-12 h-12 text-primary animate-spin mx-auto mb-4" />
          <p className="text-gray-300">Initializing Build Manager...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-gray-900 text-white">
      <nav className="w-64 bg-gray-800 border-r border-gray-700 flex flex-col">
        <div className="p-6 border-b border-gray-700">
          <h1 className="text-xl font-bold text-primary">Soliloquy</h1>
          <p className="text-sm text-gray-400">Build Manager</p>
        </div>

        <div className="flex-1 py-4">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;

            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center px-6 py-3 transition-colors ${
                  isActive
                    ? "bg-primary text-white"
                    : "text-gray-300 hover:bg-gray-700"
                }`}
              >
                <Icon className="w-5 h-5 mr-3" />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </div>

        <div className="p-4 border-t border-gray-700 text-xs text-gray-500">
          Version 0.1.0
        </div>
      </nav>

      <main className="flex-1 overflow-auto">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/build" element={<BuildView />} />
          <Route path="/modules" element={<ModulesView />} />
          <Route path="/tests" element={<TestsView />} />
          <Route path="/analytics" element={<AnalyticsView />} />
          <Route path="/settings" element={<SettingsView />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
