import { useState } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { Play, Square, Trash2 } from "lucide-react";

function BuildView() {
  const [target, setTarget] = useState("");
  const [system, setSystem] = useState("bazel");
  const [building, setBuilding] = useState(false);
  const [buildId, setBuildId] = useState<string | null>(null);
  const [output, setOutput] = useState<string>("");

  const startBuild = async () => {
    if (!target) return;

    setBuilding(true);
    setOutput("Starting build...\n");

    try {
      const id = await invoke<string>("start_build", {
        target,
        system,
        options: {
          clean: false,
          parallel_jobs: null,
          verbose: false,
          profile: null,
          extra_args: [],
        },
      });

      setBuildId(id);
      setOutput((prev) => prev + `Build started: ${id}\n`);
    } catch (err) {
      setOutput((prev) => prev + `Error: ${err}\n`);
    } finally {
      setBuilding(false);
    }
  };

  const stopBuild = async () => {
    if (!buildId) return;

    try {
      await invoke("stop_build", { buildId });
      setOutput((prev) => prev + "Build stopped\n");
    } catch (err) {
      setOutput((prev) => prev + `Error: ${err}\n`);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Build Manager</h1>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
        <h2 className="text-xl font-bold mb-4">New Build</h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Target</label>
            <input
              type="text"
              value={target}
              onChange={(e) => setTarget(e.target.value)}
              placeholder="//src/shell:soliloquy_shell"
              className="w-full bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Build System</label>
            <select
              value={system}
              onChange={(e) => setSystem(e.target.value)}
              className="w-full bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary"
            >
              <option value="bazel">Bazel</option>
              <option value="gn">GN + Ninja</option>
              <option value="cargo">Cargo</option>
            </select>
          </div>

          <div className="flex space-x-3">
            <button
              onClick={startBuild}
              disabled={building || !target}
              className="flex items-center bg-primary hover:bg-blue-600 disabled:bg-gray-600 text-white font-medium py-2 px-4 rounded transition"
            >
              <Play className="w-4 h-4 mr-2" />
              Start Build
            </button>

            {buildId && (
              <button
                onClick={stopBuild}
                className="flex items-center bg-error hover:bg-red-600 text-white font-medium py-2 px-4 rounded transition"
              >
                <Square className="w-4 h-4 mr-2" />
                Stop
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-bold mb-4">Build Output</h2>
        <div className="bg-black rounded p-4 h-96 overflow-auto font-mono text-sm">
          <pre className="text-green-400 whitespace-pre-wrap">{output}</pre>
        </div>
      </div>
    </div>
  );
}

export default BuildView;
