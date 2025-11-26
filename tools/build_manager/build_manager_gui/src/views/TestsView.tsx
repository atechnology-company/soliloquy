import { TestTube2 } from "lucide-react";

function TestsView() {
  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Tests</h1>

      <div className="bg-gray-800 rounded-lg p-12 border border-gray-700 text-center">
        <TestTube2 className="w-16 h-16 text-gray-600 mx-auto mb-4" />
        <h2 className="text-xl font-bold mb-2">Test Management Coming Soon</h2>
        <p className="text-gray-400">
          Test execution and reporting features are under development.
        </p>
      </div>
    </div>
  );
}

export default TestsView;
