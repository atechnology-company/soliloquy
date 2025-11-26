import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { TrendingUp, Clock, CheckCircle, XCircle } from "lucide-react";

interface Build {
  id: string;
  target: string;
  system: string;
  status: string;
  start_time: string;
  end_time: string | null;
}

function AnalyticsView() {
  const [history, setHistory] = useState<Build[]>([]);
  const [days, setDays] = useState(7);

  useEffect(() => {
    loadHistory();
  }, [days]);

  const loadHistory = async () => {
    try {
      const data = await invoke<Build[]>("get_build_history", { days });
      setHistory(data);
    } catch (err) {
      console.error("Failed to load build history:", err);
    }
  };

  const successCount = history.filter((b) => b.status === "Success").length;
  const failureCount = history.filter((b) => b.status === "Failed").length;

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Analytics</h1>

      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Time Range</label>
        <select
          value={days}
          onChange={(e) => setDays(Number(e.target.value))}
          className="bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary"
        >
          <option value={1}>Last 24 hours</option>
          <option value={7}>Last 7 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Total Builds</h3>
            <TrendingUp className="w-5 h-5 text-primary" />
          </div>
          <p className="text-3xl font-bold">{history.length}</p>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Successful</h3>
            <CheckCircle className="w-5 h-5 text-success" />
          </div>
          <p className="text-3xl font-bold text-success">{successCount}</p>
          <p className="text-sm text-gray-400 mt-1">
            {history.length > 0 ? ((successCount / history.length) * 100).toFixed(1) : 0}% success
          </p>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-gray-400 text-sm font-medium">Failed</h3>
            <XCircle className="w-5 h-5 text-error" />
          </div>
          <p className="text-3xl font-bold text-error">{failureCount}</p>
        </div>
      </div>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-bold mb-4 flex items-center">
          <Clock className="w-5 h-5 mr-2" />
          Build History
        </h2>

        <div className="overflow-auto">
          <table className="w-full">
            <thead>
              <tr className="text-left border-b border-gray-700">
                <th className="pb-3 font-medium text-gray-400">Target</th>
                <th className="pb-3 font-medium text-gray-400">System</th>
                <th className="pb-3 font-medium text-gray-400">Status</th>
                <th className="pb-3 font-medium text-gray-400">Time</th>
              </tr>
            </thead>
            <tbody>
              {history.slice(0, 50).map((build) => (
                <tr key={build.id} className="border-b border-gray-700/50">
                  <td className="py-3 font-mono text-sm">{build.target}</td>
                  <td className="py-3">
                    <span className="text-sm bg-gray-700 px-2 py-1 rounded">
                      {build.system}
                    </span>
                  </td>
                  <td className="py-3">
                    {build.status === "Success" ? (
                      <span className="text-success">✓ Success</span>
                    ) : build.status === "Failed" ? (
                      <span className="text-error">✗ Failed</span>
                    ) : (
                      <span className="text-gray-400">{build.status}</span>
                    )}
                  </td>
                  <td className="py-3 text-sm text-gray-400">
                    {new Date(build.start_time).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default AnalyticsView;
