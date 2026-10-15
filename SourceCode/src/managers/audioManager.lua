local audioManager = {
    masterVolume = 100,
    sfxVolume = 100,
    musicVolume = 100,

    themeSelected = nil,
    pausedAudios = {},

    sfxRoute = "assets/sounds/",
    themesRoute = "assets/sounds/"
}

function audioManager:PlayTheme(_audio, _volume, _pitch, _loop)
    if self.themeSelected ~= nil then
        love.audio.stop(self.themeSelected)
    end

    local songToPlay = love.audio.newSource(self.themesRoute .. _audio, "stream") -- Create song.

    -- Set parameters:
    if _pitch == nil then _pitch = 1 end
    songToPlay:setPitch(_pitch)

    if _volume == nil then _volume = 100
    elseif _volume > 200 then assert(false, "The value inserted on PlayTheme(_volume) is too high!") end -- If the volume is too high, jump an bug screen.
    _volume = _volume * (self.musicVolume/ 100) / 100
    songToPlay:setVolume(_volume / 2)
    
    if _loop == nil then _loop = true end
    songToPlay:setLooping(_loop)

    self.themeSelected = songToPlay
    love.audio.play(self.themeSelected)
end

function audioManager:PlaySfx(_audio, _volume, _pitch, _variablePitch)
    local soundToPlay = love.audio.newSource(self.sfxRoute .. _audio, "static") -- Create sound.

    -- Set parameters:
    if _pitch == nil then _pitch = 1 end
    if _variablePitch ~= nil and _variablePitch then _pitch = _pitch + (math.random() * 0.3 - 0.15) end -- Variable pitch.
    soundToPlay:setPitch(_pitch)

    if _volume == nil then _volume = 100
    elseif _volume > 200 then assert(false, "The value inserted on PlaySFX(_volume) is too high!") end -- If the volume is too high, jump an bug screen.
    _volume = _volume * (self.sfxVolume/ 100) / 100
    soundToPlay:setVolume(_volume / 2)

    love.audio.play(soundToPlay)
end

function audioManager:SetPause(_pause)
    if _pause then self.pausedAudios = love.audio.pause()
    else love.audio.play(self.pausedAudios) 
    self.pausedAudios = nil end
end

return audioManager