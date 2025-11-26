import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { Activity, CheckCircle, XCircle, Clock, TrendingUp } from "lucide-react";

interface Statistics {
  total_builds: number;
  successful_builds: number;
  failed_builds: number;
  average_duration_secs: number;
}

function Dashboard() {
  const [stats, setStats] = useState<Statistics | null>(null);
  const [activeBuilds, setActiveBuilds] = useState<string[]>([]);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const loadData = async () => {
    try {
      const [statsData, buildsData] = await Promise.all([
        invoke<Statistics>("get_statistics"),
        invoke<string[]>("list_active_builds"),
      ]);
      setStats(statsData);
      setActiveBuilds(buildsData);
    } catch (err) {
      console.error("Failed to load dashboard data:", err);
    }
  };

  const successRate = stats
    ? stats.total_builds > 0
      ? ((stats.successful_builds / stats.total_builds) * 100).toFixed(1)
      : "0.0"
    : "0.0";

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Dashboard</h1>
        <p className="text-gray-400">Soliloquy OS Build Overview</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Total Builds</h3>
            <Activity className="w-5 h-5 text-primary" />
          </div>
          <p className="text-3xl font-bold">{stats?.total_builds || 0}</p>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Successful</h3>
            <CheckCircle className="w-5 h-5 text-success" />
          </div>
          <p className="text-3xl font-bold text-success">
            {stats?.successful_builds || 0}
          </p>
          <p className="text-sm text-gray-400 mt-1">{successRate}% success rate</p>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Failed</h3>
            <XCircle className="w-5 h-5 text-error" />
          </div>
          <p className="text-3xl font-bold text-error">
            {stats?.failed_builds || 0}
          </p>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Avg Duration</h3>
            <Clock className="w-5 h-5 text-warning" />
          </div>
          <p className="text-3xl font-bold">
            {stats?.average_duration_secs.toFixed(1) || 0}s
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h2 className="text-xl font-bold mb-4 flex items-center">
            <Activity className="w-5 h-5 mr-2 text-primary" />
            Active Builds
          </h2>
          {activeBuilds.length === 0 ? (
            <p className="text-gray-400">No active builds</p>
          ) : (
            <div className="space-y-2">
              {activeBuilds.map((buildId) => (
                <div
                  key={buildId}
                  className="bg-gray-700 rounded p-3 text-sm font-mono"
                >
                  {buildId}
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <h2 className="text-xl font-bold mb-4 flex items-center">
            <TrendingUp className="w-5 h-5 mr-2 text-primary" />
            Quick Actions
          </h2>
          <div className="space-y-3">
            <button className="w-full bg-primary hover:bg-blue-600 text-white font-medium py-2 px-4 rounded transition">
              Start New Build
            </button>
            <button className="w-full bg-gray-700 hover:bg-gray-600 text-white font-medium py-2 px-4 rounded transition">
              Run Tests
            </button>
            <button className="w-full bg-gray-700 hover:bg-gray-600 text-white font-medium py-2 px-4 rounded transition">
              View Build History
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
