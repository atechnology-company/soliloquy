import { Settings as SettingsIcon } from "lucide-react";

function SettingsView() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
        <h2 className="text-xl font-bold mb-4">General</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Default Build System</label>
            <select className="w-full max-w-md bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary">
              <option value="bazel">Bazel</option>
              <option value="gn">GN + Ninja</option>
              <option value="cargo">Cargo</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Parallel Jobs</label>
            <input
              type="number"
              defaultValue={8}
              className="w-full max-w-md bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary"
            />
          </div>
        </div>
      </div>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
        <h2 className="text-xl font-bold mb-4">Notifications</h2>
        <div className="space-y-3">
          <label className="flex items-center">
            <input type="checkbox" defaultChecked className="mr-3" />
            <span>Enable notifications</span>
          </label>
          <label className="flex items-center">
            <input type="checkbox" defaultChecked className="mr-3" />
            <span>Notify on build success</span>
          </label>
          <label className="flex items-center">
            <input type="checkbox" defaultChecked className="mr-3" />
            <span>Notify on build failure</span>
          </label>
        </div>
      </div>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h2 className="text-xl font-bold mb-4">Appearance</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Theme</label>
            <select className="w-full max-w-md bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary">
              <option value="dark">Dark</option>
              <option value="light">Light (Coming Soon)</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Font Size</label>
            <input
              type="number"
              defaultValue={14}
              min={12}
              max={20}
              className="w-full max-w-md bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-primary"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

export default SettingsView;
