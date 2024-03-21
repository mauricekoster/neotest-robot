local async = require("neotest.async")
local lib = require("neotest.lib")
local robot = require("neotest-robot.robot")
local logger = require("neotest.logging")

local is_test_file = robot.is_test_file

local RobotNeotestAdapter = { name = "neotest-robot" }

RobotNeotestAdapter.root = lib.files.match_root_pattern("robotidy.toml", "pyproject.toml", "conda.yaml", "robot.yaml")

function RobotNeotestAdapter.is_test_file(file_path)
	return is_test_file(file_path)
end

function RobotNeotestAdapter.filter_dir(name)
	return name ~= "venv"
end

---@async
function RobotNeotestAdapter.discover_positions(path)
	logger.debug("RobotNeotestAdapter.discover_positions")
	local positions = robot.discover_positions(path)

	return positions
end

function RobotNeotestAdapter.build_spec(args)
	local position = args.tree:data()
	local results_path = async.fn.tempname()
	local stream_path = async.fn.tempname()
	lib.files.write(stream_path, "")

	local root = RobotNeotestAdapter.root(position.path)

	return {
		command = command,
		context = {
			results_path = results_path,
			stop_stream = stop_stream,
		},
		stream = function()
			return function()
				local lines = stream_data()
				local results = {}
				for _, line in ipairs(lines) do
					local result = vim.json.decode(line, { luanil = { object = true } })
					results[result.id] = result.result
				end
				return results
			end
		end,
		strategy = strategy_config,
	}
end

return RobotNeotestAdapter
