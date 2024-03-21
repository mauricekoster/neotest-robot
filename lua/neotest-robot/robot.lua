local lib = require("neotest.lib")
local logger = require("neotest.logging")

local M = {}

function M.is_test_file(file_path)
	if not vim.endswith(file_path, ".robot") then
		return false
	end
	local elems = vim.split(file_path, Path.path.sep)
	local file_name = elems[#elems]

	return M.has_testcase_section(file_path)
end

M._test_treesitter_query = [[
	;;query
    (section
      (test_cases_section
        [(test_case_definition (name) @test.name)] @test.definition))
]]

function M.has_testcase_section(file_path)
	logger.debug("has_testcase_section: " .. file_path)
	local content = lib.files.read(file_path)
	local tree = lib.treesitter.parse_positions_from_string(file_path, content, M._test_treesitter_query, {})
	logger.debug(tree)
	local contains_tests = next(tree._children) ~= nil
	logger.debug("  result: " .. tostring(contains_tests))
	return contains_tests
end

function M.discover_positions(path)
	logger.debug("Entered `discover_positions` with " .. path)
	logger.debug("Running query: " .. M._test_treesitter_query)
	local positions = lib.treesitter.parse_positions(path, M._test_treesitter_query, { nested_namespaces = true })
	logger.debug("Returning from `discover_positions` with: ", positions)
	return positions
end

return M
