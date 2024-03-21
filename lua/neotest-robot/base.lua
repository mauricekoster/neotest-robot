local async = require("neotest.async")
local lib = require("neotest.lib")
local Path = require("plenary.path")

local robot = require("neotest-robot.robot")

local M = {}

M.module_exists = function(module, python_command)
	return lib.process.run(vim.tbl_flatten({
		python_command,
		"-c",
		"import imp; imp.find_module('" .. module .. "')",
	})) == 0
end

local python_command_mem = {}

---@return string[]
function M.get_python_command(root)
	if python_command_mem[root] then
		return python_command_mem[root]
	end
	-- Use activated virtualenv.
	if vim.env.VIRTUAL_ENV then
		python_command_mem[root] = { Path:new(vim.env.VIRTUAL_ENV, "bin", "python").filename }
		return python_command_mem[root]
	end

	for _, pattern in ipairs({ "*", ".*" }) do
		local match = async.fn.glob(Path:new(root or async.fn.getcwd(), pattern, "pyvenv.cfg").filename)
		if match ~= "" then
			python_command_mem[root] = { (Path:new(match):parent() / "bin" / "python").filename }
			return python_command_mem[root]
		end
	end

	if lib.files.exists("Pipfile") then
		local success, exit_code, data = pcall(lib.process.run, { "pipenv", "--py" }, { stdout = true })
		if success and exit_code == 0 then
			local venv = data.stdout:gsub("\n", "")
			if venv then
				python_command_mem[root] = { Path:new(venv).filename }
				return python_command_mem[root]
			end
		end
	end

	if lib.files.exists("pyproject.toml") then
		local success, exit_code, data = pcall(
			lib.process.run,
			{ "poetry", "run", "poetry", "env", "info", "-p" },
			{ stdout = true }
		)
		if success and exit_code == 0 then
			local venv = data.stdout:gsub("\n", "")
			if venv then
				python_command_mem[root] = { Path:new(venv, "bin", "python").filename }
				return python_command_mem[root]
			end
		end
	end

	-- Fallback to system Python.
	python_command_mem[root] = {
		async.fn.exepath("python3") or async.fn.exepath("python") or "python",
	}
	return python_command_mem[root]
end

return M
