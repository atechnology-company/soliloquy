import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/tauri";
import { Package, Search } from "lucide-react";

interface Module {
  name: string;
  path: string;
  module_type: string;
  build_systems: string[];
  dependencies: string[];
  source_files: string[];
  test_files: string[];
}

function ModulesView() {
  const [modules, setModules] = useState<Module[]>([]);
  const [filter, setFilter] = useState("");
  const [selectedModule, setSelectedModule] = useState<Module | null>(null);

  useEffect(() => {
    loadModules();
  }, []);

  const loadModules = async () => {
    try {
      const data = await invoke<Module[]>("list_modules");
      setModules(data);
    } catch (err) {
      console.error("Failed to load modules:", err);
    }
  };

  const filteredModules = modules.filter((m) =>
    m.name.toLowerCase().includes(filter.toLowerCase())
  );

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Modules</h1>

      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            placeholder="Search modules..."
            className="w-full bg-gray-700 border border-gray-600 rounded pl-10 pr-4 py-2 focus:outline-none focus:border-primary"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 h-[600px] overflow-auto">
          <h2 className="text-xl font-bold mb-4">All Modules ({filteredModules.length})</h2>
          <div className="space-y-2">
            {filteredModules.map((module) => (
              <div
                key={module.name}
                onClick={() => setSelectedModule(module)}
                className={`p-4 rounded cursor-pointer transition ${
                  selectedModule?.name === module.name
                    ? "bg-primary"
                    : "bg-gray-700 hover:bg-gray-600"
                }`}
              >
                <div className="flex items-center">
                  <Package className="w-4 h-4 mr-2" />
                  <span className="font-medium">{module.name}</span>
                </div>
                <p className="text-sm text-gray-400 mt-1 truncate">{module.path}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 h-[600px] overflow-auto">
          <h2 className="text-xl font-bold mb-4">Module Details</h2>
          {selectedModule ? (
            <div className="space-y-4">
              <div>
                <h3 className="text-lg font-bold text-primary">{selectedModule.name}</h3>
                <p className="text-sm text-gray-400">{selectedModule.path}</p>
              </div>

              <div>
                <h4 className="font-medium mb-2">Type</h4>
                <span className="text-sm bg-gray-700 px-3 py-1 rounded">
                  {selectedModule.module_type}
                </span>
              </div>

              <div>
                <h4 className="font-medium mb-2">Build Systems</h4>
                <div className="flex flex-wrap gap-2">
                  {selectedModule.build_systems.map((sys) => (
                    <span key={sys} className="text-sm bg-gray-700 px-3 py-1 rounded">
                      {sys}
                    </span>
                  ))}
                </div>
              </div>

              <div>
                <h4 className="font-medium mb-2">Statistics</h4>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-400">Source Files</p>
                    <p className="text-2xl font-bold">{selectedModule.source_files.length}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-400">Test Files</p>
                    <p className="text-2xl font-bold">{selectedModule.test_files.length}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-400">Dependencies</p>
                    <p className="text-2xl font-bold">{selectedModule.dependencies.length}</p>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-gray-400">Select a module to view details</p>
          )}
        </div>
      </div>
    </div>
  );
}

export default ModulesView;
