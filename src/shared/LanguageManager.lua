local HttpService = game:GetService("HttpService")

local LanguageManager = {}
LanguageManager.__index = LanguageManager

-- Utility: get nested value by "a.b.c" path
local function getByPath(tbl, path)
	local current = tbl
	for part in string.gmatch(path, "[^%.]+") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[part]
	end
	return current
end

-- Utility: simple {name} interpolation
local function interpolate(str, params)
	if type(str) ~= "string" then
		return str
	end
	if type(params) ~= "table" then
		return str
	end
	return (str:gsub("{(.-)}", function(key)
		local v = params[key]
		if v == nil then return "{" .. key .. "}" end
		return tostring(v)
	end))
end

function LanguageManager.new()
	local self = setmetatable({}, LanguageManager)
	self._data = {}                 -- all languages
	self._lang = "en"               -- current language
	self._fallback = "en"           -- fallback language
	self._missingAsKey = true       -- if missing, return key instead of empty
	return self
end

-- Load JSON from a string (recommended for ModuleScript storage)
function LanguageManager:loadFromJsonString(jsonString)
	assert(type(jsonString) == "string", "jsonString must be a string")
	local decoded = HttpService:JSONDecode(jsonString)
	assert(type(decoded) == "table", "decoded language json must be a table")
	self._data = decoded
	return self
end

-- Optional: load JSON from a URL (requires HTTP enabled)
function LanguageManager:loadFromUrl(url)
	assert(type(url) == "string", "url must be a string")
	local raw = HttpService:GetAsync(url)
	return self:loadFromJsonString(raw)
end

function LanguageManager:setFallbackLanguage(langCode)
	self._fallback = langCode
	return self
end

function LanguageManager:setLanguage(langCode)
	self._lang = langCode
	return self
end

function LanguageManager:getLanguage()
	return self._lang
end

-- Translate: t("menu.rules.title") -> "How to Play"
-- With params: t("score.label", {value = 10}) -> "Score: 10"
function LanguageManager:t(key, params)
	local langTable = self._data[self._lang]
	local fallbackTable = self._data[self._fallback]

	local value = nil
	if type(langTable) == "table" then
		value = getByPath(langTable, key)
	end
	if value == nil and type(fallbackTable) == "table" then
		value = getByPath(fallbackTable, key)
	end

	if value == nil then
		return self._missingAsKey and key or ""
	end

	-- allow strings, but also allow arrays/tables if you want
	if type(value) == "string" then
		return interpolate(value, params)
	end
	return value
end

return LanguageManager
