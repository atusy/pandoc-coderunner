--- Protect table being modified
local function protect(v)
	if type(v) ~= "table" then
		return v
	end

	local m = getmetatable(v) or {}
	local index = m.__index or function(_, key)
		return v[key]
	end
	m.__index = function(_, key)
		return protect(index(v, key))
	end
	return setmetatable({}, m)
end

local run_script = function(cmd, code)
	return pandoc.system.with_temporary_directory("panwalk", function(tmpdir)
		local tmpfile = pandoc.path.join({ tmpdir, "panwalk.sh" })
		assert(assert(io.open(tmpfile, "w")):write(code.text)):close()
		local prog = string.format("%s %s", cmd, tmpfile)
		local handle = assert(io.popen(prog == cmd and (cmd .. " " .. tmpfile) or prog))
		local result = handle:read("*a")
		handle:close()
		return result
	end)
end

--- Environment where code is evaluated
local env = setmetatable({
	ctx = {
		opts = {
			engines = setmetatable({
				lua = function(code, environment)
					return assert(load(code.text, code.identifier, "t", environment))()
				end,
			}, {
				__index = function(_, cmd)
					return function(code)
						return run_script(cmd, code)
					end
				end,
			}),
		},
	},
}, {
	__index = function(_, key)
		return protect(_G[key])
	end,
})

--- Test if a code needs be evaluated
--- @param el table
--- @return boolean
local function needs_eval(el)
	-- needs language to evaluate
	if el.classes[1] == nil then
		return false
	end

	if tostring(el.attributes.eval) == "true" then
		return true
	end

	local o = env.ctx.meta.options or {}
	if not o.eval then
		return false
	end

	if o.eval[el.classes[1]] ~= nil then
		return tostring(o.eval[el.classes[1]]) == "true"
	end

	return tostring(o.eval["."]) == "true"
end

--- Process a code block or inline code
local function process_code(el)
	if not needs_eval(el) then
		return el
	end

	env.ctx.self = el
	local result = env.ctx.opts.engines[el.classes[1]](el, env)
	if result == nil then
		return {}
	end

	if type(result) == "table" then
		return result
	end

	return pandoc[el.t == "CodeBlock" and "RawBlock" or "RawInline"](
		FORMAT, ---@diagnostic disable-line: undefined-global
		tostring(result)
	)
end

return {
	{
		Pandoc = function(doc)
			env.ctx.meta = doc.meta
			env.ctx.blocks = doc.blocks
			return doc:walk({
				traverse = "topdown",
				CodeBlock = process_code,
				Code = process_code,
			})
		end,
	},
}
